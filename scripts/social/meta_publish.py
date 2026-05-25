#!/usr/bin/env python3
import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ENV = ROOT / "_private" / "meta.env"
DEFAULT_STATE = ROOT / "_private" / "meta_publish_state.json"
GRAPH_VERSION = "v23.0"


def eprint(message):
    print(message, file=sys.stderr)


def load_env(path):
    if not path.exists():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def parse_dt(value):
    return datetime.fromisoformat(value).astimezone(timezone.utc)


def asset_url(job):
    if job.get("image_url"):
        return job["image_url"]
    base = os.environ.get("PUBLIC_ASSET_BASE", "").rstrip("/")
    if not base:
        raise ValueError("Falta PUBLIC_ASSET_BASE o image_url")
    path = job["asset"].lstrip("/")
    return f"{base}/{path}"


def graph_post(path, params):
    token = os.environ.get("META_ACCESS_TOKEN")
    if not token:
        raise RuntimeError("Falta META_ACCESS_TOKEN")
    url = f"https://graph.facebook.com/{GRAPH_VERSION}/{path.lstrip('/')}"
    body = urllib.parse.urlencode({**params, "access_token": token}).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST")
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def publish_instagram_feed(job):
    ig_user_id = os.environ.get("IG_USER_ID")
    if not ig_user_id:
        raise RuntimeError("Falta IG_USER_ID")
    container = graph_post(
        f"{ig_user_id}/media",
        {"image_url": asset_url(job), "caption": job["caption"]},
    )
    return graph_post(f"{ig_user_id}/media_publish", {"creation_id": container["id"]})


def publish_instagram_story(job):
    ig_user_id = os.environ.get("IG_USER_ID")
    if not ig_user_id:
        raise RuntimeError("Falta IG_USER_ID")
    container = graph_post(
        f"{ig_user_id}/media",
        {"image_url": asset_url(job), "media_type": "STORIES"},
    )
    return graph_post(f"{ig_user_id}/media_publish", {"creation_id": container["id"]})


def publish_facebook_photo(job):
    page_id = os.environ.get("FB_PAGE_ID")
    if not page_id:
        raise RuntimeError("Falta FB_PAGE_ID")
    return graph_post(
        f"{page_id}/photos",
        {"url": asset_url(job), "caption": job["caption"], "published": "true"},
    )


PUBLISHERS = {
    "instagram_feed": publish_instagram_feed,
    "instagram_story": publish_instagram_story,
    "facebook_photo": publish_facebook_photo,
}


def load_state(path):
    if path.exists():
        return read_json(path)
    return {"published": {}}


def caption(job):
    text = job.get("caption", "").rstrip()
    hashtags = " ".join(job.get("hashtags", []))
    return f"{text}\n\n{hashtags}".strip()


def normalized_jobs(data):
    jobs = []
    for job in data["jobs"]:
        item = dict(job)
        item["caption"] = caption(item)
        item["platforms"] = item.get("platforms", [])
        jobs.append(item)
    return jobs


def cmd_plan(args):
    load_env(args.env)
    jobs = normalized_jobs(read_json(args.file))
    for job in jobs:
        manual = " manual" if job.get("manual") else ""
        permission = " permiso_pendiente" if job.get("permission_required") else ""
        print(f"{job['id']} | {job['scheduled_at']} | {','.join(job['platforms'])}{manual}{permission}")
        print(f"  asset: {job.get('asset')}")
        if job.get("manual"):
            print("  url: -")
        else:
            try:
                print(f"  url: {asset_url(job)}")
            except ValueError as error:
                print(f"  url: pendiente ({error})")
        if job.get("manual_after_publish"):
            print(f"  completar a mano: {job['manual_after_publish']}")


def cmd_check_config(args):
    load_env(args.env)
    required = ["META_ACCESS_TOKEN", "IG_USER_ID", "PUBLIC_ASSET_BASE"]
    if args.facebook:
        required.append("FB_PAGE_ID")
    missing = [key for key in required if not os.environ.get(key)]
    if missing:
        for key in missing:
            eprint(f"Falta {key}")
        return 1
    print("Config OK")
    return 0


def cmd_publish_due(args):
    load_env(args.env)
    data = read_json(args.file)
    state = load_state(args.state)
    now = datetime.now(timezone.utc)
    jobs = normalized_jobs(data)
    selected = 0

    for job in jobs:
        if args.id and job["id"] != args.id:
            continue
        if not args.id and parse_dt(job["scheduled_at"]) > now:
            continue
        if job.get("manual"):
            print(f"SKIP manual {job['id']}: {job.get('manual_reason', '')}")
            continue
        if job.get("permission_required") and not args.allow_pending_permission:
            print(f"SKIP permiso pendiente {job['id']}")
            continue
        selected += 1
        for platform in job["platforms"]:
            key = f"{job['id']}:{platform}"
            if state["published"].get(key):
                print(f"SKIP ya publicado {key}")
                continue
            if platform not in PUBLISHERS:
                raise ValueError(f"Plataforma no soportada: {platform}")
            if not args.live:
                print(f"DRY-RUN {key} -> {asset_url(job)}")
                if job.get("manual_after_publish"):
                    print(f"  DESPUES: {job['manual_after_publish']}")
                continue
            result = PUBLISHERS[platform](job)
            state["published"][key] = {"at": int(time.time()), "result": result}
            write_json(args.state, state)
            print(f"OK {key}: {result}")
            if job.get("manual_after_publish"):
                print(f"  DESPUES: {job['manual_after_publish']}")

    if selected == 0:
        print("No hay trabajos pendientes.")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Publica cola social CBME por Meta Graph API.")
    parser.add_argument("--env", type=Path, default=DEFAULT_ENV)
    sub = parser.add_subparsers(dest="cmd", required=True)

    check = sub.add_parser("check-config")
    check.add_argument("--facebook", action="store_true")
    check.set_defaults(func=cmd_check_config)

    plan = sub.add_parser("plan")
    plan.add_argument("file", type=Path)
    plan.set_defaults(func=cmd_plan)

    due = sub.add_parser("publish-due")
    due.add_argument("file", type=Path)
    due.add_argument("--state", type=Path, default=DEFAULT_STATE)
    due.add_argument("--id")
    due.add_argument("--live", action="store_true", help="Publica de verdad. Sin esto solo simula.")
    due.add_argument("--allow-pending-permission", action="store_true")
    due.set_defaults(func=cmd_publish_due)

    args = parser.parse_args()
    try:
        return args.func(args) or 0
    except Exception as error:
        eprint(f"ERROR: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
