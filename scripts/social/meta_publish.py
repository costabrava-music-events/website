#!/usr/bin/env python3
import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ENV = ROOT / "_private" / "meta.env"
DEFAULT_STATE = ROOT / "_private" / "meta_publish_state.json"
GRAPH_VERSION = "v23.0"
SCOPE_ALIASES = {
    "instagram_content_publish": ("instagram_content_publish", "instagram_content_publishing"),
}
REQUIRED_SCOPES = {
    "instagram_feed": ("instagram_basic", "instagram_content_publish", "pages_read_engagement", "business_management", "pages_show_list"),
    "instagram_story": ("instagram_basic", "instagram_content_publish", "pages_read_engagement", "business_management", "pages_show_list"),
    "instagram_reel": ("instagram_basic", "instagram_content_publish", "pages_read_engagement", "business_management", "pages_show_list"),
    "facebook_photo": ("pages_manage_posts", "pages_read_engagement", "pages_show_list"),
}
SCHEDULABLE_PLATFORMS = {"instagram_feed", "instagram_story"}
INSTAGRAM_MIN_SCHEDULE_SECONDS = 10 * 60
INSTAGRAM_MAX_SCHEDULE_SECONDS = 75 * 24 * 60 * 60


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
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as err:
        payload = ""
        try:
            payload = err.read().decode("utf-8", errors="replace")
        except Exception:
            payload = ""
        detail = f" | {payload}" if payload else ""
        raise RuntimeError(f"Meta Graph API HTTP {err.code}: {err.reason}{detail}") from err


def graph_get(path, params=None):
    token = os.environ.get("META_ACCESS_TOKEN")
    if not token:
        raise RuntimeError("Falta META_ACCESS_TOKEN")
    query = urllib.parse.urlencode({**(params or {}), "access_token": token})
    url = f"https://graph.facebook.com/{GRAPH_VERSION}/{path.lstrip('/')}?{query}"
    try:
        with urllib.request.urlopen(url, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as err:
        payload = ""
        try:
            payload = err.read().decode("utf-8", errors="replace")
        except Exception:
            payload = ""
        detail = f" | {payload}" if payload else ""
        raise RuntimeError(f"Meta Graph API HTTP {err.code}: {err.reason}{detail}") from err


def graph_delete(path, params=None):
    token = os.environ.get("META_ACCESS_TOKEN")
    if not token:
        raise RuntimeError("Falta META_ACCESS_TOKEN")
    url = f"https://graph.facebook.com/{GRAPH_VERSION}/{path.lstrip('/')}"
    body = urllib.parse.urlencode({**(params or {}), "access_token": token}).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="DELETE")
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as err:
        payload = ""
        try:
            payload = err.read().decode("utf-8", errors="replace")
        except Exception:
            payload = ""
        detail = f" | {payload}" if payload else ""
        raise RuntimeError(f"Meta Graph API HTTP {err.code}: {err.reason}{detail}") from err


def canonical_scope(scope):
    for canonical, aliases in SCOPE_ALIASES.items():
        if scope == canonical or scope in aliases:
            return canonical
    return scope


def normalize_scopes(scopes):
    return {canonical_scope(scope) for scope in scopes}


def debug_token_data():
    token = os.environ.get("META_ACCESS_TOKEN")
    if not token:
        raise RuntimeError("Falta META_ACCESS_TOKEN en env")
    app_id = os.environ.get("META_APP_ID")
    app_secret = os.environ.get("META_APP_SECRET")
    if not app_id:
        raise RuntimeError("Falta META_APP_ID en env")
    if not app_secret:
        raise RuntimeError("Falta META_APP_SECRET en env")

    app_token = f"{app_id}|{app_secret}"
    query = urllib.parse.urlencode({"input_token": token, "access_token": app_token})
    url = f"https://graph.facebook.com/{GRAPH_VERSION}/debug_token?{query}"
    with urllib.request.urlopen(url, timeout=60) as response:
        payload = json.loads(response.read().decode("utf-8"))
    return payload["data"]


def check_scopes_for_platforms(scopes, platforms):
    normalized = normalize_scopes(scopes)
    missing = {}
    for platform in platforms:
        required = REQUIRED_SCOPES.get(platform, ())
        platform_missing = [scope for scope in required if canonical_scope(scope) not in normalized]
        if platform_missing:
            missing[platform] = platform_missing
    return missing


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


def wait_instagram_container(container_id, timeout_seconds=600, interval_seconds=5):
    deadline = time.time() + timeout_seconds
    last = None
    while time.time() < deadline:
        last = graph_get(container_id, {"fields": "status_code,status"})
        status = last.get("status_code")
        if status == "FINISHED":
            return last
        if status in {"ERROR", "EXPIRED"}:
            raise RuntimeError(f"Contenedor Instagram no publicable: {last}")
        time.sleep(interval_seconds)
    raise RuntimeError(f"Timeout esperando contenedor Instagram: {last}")


def publish_instagram_reel(job):
    ig_user_id = os.environ.get("IG_USER_ID")
    if not ig_user_id:
        raise RuntimeError("Falta IG_USER_ID")
    params = {
        "media_type": "REELS",
        "video_url": job.get("video_url") or asset_url(job),
        "caption": job["caption"],
        "share_to_feed": str(job.get("share_to_feed", True)).lower(),
    }
    if job.get("cover_url"):
        params["cover_url"] = job["cover_url"]
    if "thumb_offset" in job:
        params["thumb_offset"] = str(job["thumb_offset"])
    container = graph_post(f"{ig_user_id}/media", params)
    wait_instagram_container(container["id"])
    return graph_post(f"{ig_user_id}/media_publish", {"creation_id": container["id"]})


def schedule_instagram_feed(job):
    ig_user_id = os.environ.get("IG_USER_ID")
    if not ig_user_id:
        raise RuntimeError("Falta IG_USER_ID")
    return graph_post(
        f"{ig_user_id}/media",
        {
            "image_url": asset_url(job),
            "caption": job["caption"],
            "published": "false",
            "scheduled_publish_time": str(schedule_unix(job)),
        },
    )


def schedule_instagram_story(job):
    ig_user_id = os.environ.get("IG_USER_ID")
    if not ig_user_id:
        raise RuntimeError("Falta IG_USER_ID")
    return graph_post(
        f"{ig_user_id}/media",
        {
            "image_url": asset_url(job),
            "media_type": "STORIES",
            "published": "false",
            "scheduled_publish_time": str(schedule_unix(job)),
        },
    )


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
    "instagram_reel": publish_instagram_reel,
    "facebook_photo": publish_facebook_photo,
}
SCHEDULERS = {
    "instagram_feed": schedule_instagram_feed,
    "instagram_story": schedule_instagram_story,
}


def load_state(path):
    if path.exists():
        state = read_json(path)
    else:
        state = {}
    state.setdefault("published", {})
    state.setdefault("scheduled", {})
    return state


def schedule_unix(job):
    return int(parse_dt(job["scheduled_at"]).timestamp())


def validate_schedule_window(job, now):
    scheduled_at = parse_dt(job["scheduled_at"])
    delta = int((scheduled_at - now).total_seconds())
    if delta < INSTAGRAM_MIN_SCHEDULE_SECONDS:
        raise RuntimeError(f"{job['id']} queda a menos de 10 minutos")
    if delta > INSTAGRAM_MAX_SCHEDULE_SECONDS:
        raise RuntimeError(f"{job['id']} supera la ventana maxima de 75 dias")


def scheduled_state_entry(job, platform, result):
    return {
        "scheduled_at": job["scheduled_at"],
        "remote_id": result.get("id"),
        "result": result,
        "platform": platform,
        "recorded_at": int(time.time()),
    }


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
            if state["scheduled"].get(key):
                print(f"SKIP ya programado {key}")
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


def cmd_schedule_pending(args):
    load_env(args.env)
    data = read_json(args.file)
    state = load_state(args.state)
    now = datetime.now(timezone.utc)
    jobs = normalized_jobs(data)
    selected = 0

    for job in jobs:
        if args.id and job["id"] != args.id:
            continue
        if not args.id and parse_dt(job["scheduled_at"]) <= now:
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
            if platform not in SCHEDULABLE_PLATFORMS:
                print(f"SKIP no programable {key}")
                continue
            if state["published"].get(key):
                print(f"SKIP ya publicado {key}")
                continue
            if state["scheduled"].get(key):
                print(f"SKIP ya programado {key}")
                continue
            validate_schedule_window(job, now)
            if not args.live:
                print(f"DRY-RUN programar {key} -> {job['scheduled_at']}")
                if job.get("manual_after_publish"):
                    print(f"  DESPUES: {job['manual_after_publish']}")
                continue
            result = SCHEDULERS[platform](job)
            state["scheduled"][key] = scheduled_state_entry(job, platform, result)
            write_json(args.state, state)
            print(f"OK programado {key}: {result}")
            if job.get("manual_after_publish"):
                print(f"  DESPUES: {job['manual_after_publish']}")

    if selected == 0:
        print("No hay trabajos futuros pendientes.")
    return 0


def _upsert_env_line(text, key, value):
    lines = text.splitlines()
    updated = False
    out = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("#") or "=" not in stripped:
            out.append(line)
            continue
        k, _ = stripped.split("=", 1)
        if k.strip() != key:
            out.append(line)
            continue
        out.append(f"{key}={value}")
        updated = True
    if not updated:
        if out and out[-1].strip() != "":
            out.append("")
        out.append(f"{key}={value}")
    return "\n".join(out).rstrip() + "\n"


def cmd_exchange_long_lived(args):
    load_env(args.env)
    short_token = os.environ.get("META_ACCESS_TOKEN")
    if not short_token:
        raise RuntimeError("Falta META_ACCESS_TOKEN (short-lived) en env")
    app_id = os.environ.get("META_APP_ID")
    app_secret = os.environ.get("META_APP_SECRET")
    if not app_id:
        raise RuntimeError("Falta META_APP_ID en env")
    if not app_secret:
        raise RuntimeError("Falta META_APP_SECRET en env")

    query = urllib.parse.urlencode(
        {
            "grant_type": "fb_exchange_token",
            "client_id": app_id,
            "client_secret": app_secret,
            "fb_exchange_token": short_token,
        }
    )
    url = f"https://graph.facebook.com/{GRAPH_VERSION}/oauth/access_token?{query}"
    try:
        with urllib.request.urlopen(url, timeout=60) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as err:
        raw = ""
        try:
            raw = err.read().decode("utf-8", errors="replace")
        except Exception:
            raw = ""
        detail = f" | {raw}" if raw else ""
        raise RuntimeError(f"Meta token exchange HTTP {err.code}: {err.reason}{detail}") from err
    long_token = payload.get("access_token")
    if not long_token:
        raise RuntimeError(f"Respuesta inesperada: {payload}")

    if args.write:
        env_text = args.env.read_text(encoding="utf-8") if args.env.exists() else ""
        args.env.parent.mkdir(parents=True, exist_ok=True)
        args.env.write_text(_upsert_env_line(env_text, "META_ACCESS_TOKEN", long_token), encoding="utf-8")

    print(long_token)
    return 0


def cmd_debug_token(args):
    load_env(args.env)
    payload = {"data": debug_token_data()}
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


def cmd_check_token_scopes(args):
    load_env(args.env)
    data = debug_token_data()
    scopes = data.get("scopes", [])
    platforms = []
    if args.instagram:
        platforms.extend(["instagram_feed", "instagram_story", "instagram_reel"])
    if args.facebook:
        platforms.append("facebook_photo")
    missing = check_scopes_for_platforms(scopes, platforms)
    print("Scopes OK" if not missing else "Scopes incompletos")
    print(json.dumps({"scopes": scopes, "missing": missing}, ensure_ascii=False, indent=2))
    return 1 if missing else 0
    return 0


def cmd_delete_instagram_media(args):
    load_env(args.env)
    result = graph_delete(args.media_id)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


def cmd_get_instagram_media(args):
    load_env(args.env)
    fields = "id,caption,media_type,media_url,permalink,timestamp,username"
    result = graph_get(args.media_id, {"fields": fields})
    print(json.dumps(result, ensure_ascii=False, indent=2))
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

    schedule = sub.add_parser("schedule-pending", help="Crea publicaciones programadas reales en Instagram para trabajos futuros.")
    schedule.add_argument("file", type=Path)
    schedule.add_argument("--state", type=Path, default=DEFAULT_STATE)
    schedule.add_argument("--id")
    schedule.add_argument("--live", action="store_true", help="Programa de verdad. Sin esto solo simula.")
    schedule.add_argument("--allow-pending-permission", action="store_true")
    schedule.set_defaults(func=cmd_schedule_pending)

    exchange = sub.add_parser("exchange-long-lived", help="Cambia META_ACCESS_TOKEN (corto) por long-lived (~60d).")
    exchange.add_argument("--write", action="store_true", help="Sobrescribe META_ACCESS_TOKEN en el env file.")
    exchange.set_defaults(func=cmd_exchange_long_lived)

    debug = sub.add_parser("debug-token", help="Muestra info/scopes del META_ACCESS_TOKEN actual.")
    debug.set_defaults(func=cmd_debug_token)

    check_token = sub.add_parser("check-token-scopes", help="Verifica si el token actual tiene scopes suficientes para publicar.")
    check_token.add_argument("--instagram", action="store_true")
    check_token.add_argument("--facebook", action="store_true")
    check_token.set_defaults(func=cmd_check_token_scopes)

    delete_media = sub.add_parser("delete-instagram-media", help="Intenta borrar un media publicado por ID.")
    delete_media.add_argument("media_id")
    delete_media.set_defaults(func=cmd_delete_instagram_media)

    get_media = sub.add_parser("get-instagram-media", help="Muestra datos de un media publicado por ID.")
    get_media.add_argument("media_id")
    get_media.set_defaults(func=cmd_get_instagram_media)

    args = parser.parse_args()
    try:
        return args.func(args) or 0
    except Exception as error:
        eprint(f"ERROR: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
