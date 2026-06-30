#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/social/salerm-vmw-2026-05-25/source"
OUT = ROOT / "assets/social/salerm-vmw-2026-05-25"
GIF = OUT / "salerm-reel-v1.gif"
COVER = OUT / "salerm-reel-cover.png"

SIZE = (360, 640)
FPS = 6
TOTAL_SECONDS = 12
SEGMENTS = [
    {
        "image": "image-02.jpeg",
        "start": 0,
        "duration": 4,
        "kicker": "SALERM VMW COSMETICS",
        "title": "Cada evento empieza\nmucho antes de que\nllegue la gente",
        "subtitle": "Producción de evento cuidada\ndesde el montaje.",
    },
    {
        "image": "image-03.jpeg",
        "start": 4,
        "duration": 4,
        "kicker": "PRODUCCIÓN · COORDINACIÓN · EJECUCIÓN",
        "title": "Todo tiene que\nencajar antes de que\nempiece el evento",
        "subtitle": "Espacio, servicio y ritmo visual\nen una misma ejecución.",
    },
    {
        "image": "image-01.jpeg",
        "start": 8,
        "duration": 4,
        "kicker": "EVENTO CORPORATIVO",
        "title": "Así fue el evento de\nSALERM VMW\nCOSMETICS",
        "subtitle": "Un montaje pensado para que la\nexperiencia fluya de principio a final.",
    },
]


def load_font(candidates, size):
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size)
        except Exception:
            continue
    return ImageFont.load_default()


FONT_BOLD = load_font(
    [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/Library/Fonts/Arial Bold.ttf",
    ],
    42,
)
FONT_MED = load_font(
    [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
    ],
    22,
)
FONT_SMALL = load_font(
    [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/Library/Fonts/Arial Bold.ttf",
    ],
    18,
)


def find_segment(t):
    for seg in SEGMENTS:
        if seg["start"] <= t < seg["start"] + seg["duration"]:
            return seg
    return SEGMENTS[-1]


def fit_cover(image: Image.Image, scale: float, offset_x: float, offset_y: float) -> Image.Image:
    image = image.convert("RGB")
    iw, ih = image.size
    cw, ch = SIZE
    image_ratio = iw / ih
    canvas_ratio = cw / ch
    if image_ratio > canvas_ratio:
        nh = ch
        nw = int(nh * image_ratio)
    else:
        nw = cw
        nh = int(nw / image_ratio)
    image = image.resize((nw, nh), Image.Resampling.LANCZOS)
    nw = int(nw * scale)
    nh = int(nh * scale)
    image = image.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (cw - nw) // 2 + int(offset_x)
    y = (ch - nh) // 2 + int(offset_y)
    canvas = Image.new("RGB", SIZE, "black")
    canvas.paste(image, (x, y))
    return canvas


def overlay_gradient(image: Image.Image) -> Image.Image:
    grad = Image.new("L", SIZE, 0)
    draw = ImageDraw.Draw(grad)
    for y in range(SIZE[1]):
        if y < SIZE[1] * 0.35:
            alpha = 10
        else:
            alpha = int(10 + ((y - SIZE[1] * 0.35) / (SIZE[1] * 0.65)) * 180)
        draw.line((0, y, SIZE[0], y), fill=max(0, min(255, alpha)))
    image = image.convert("RGBA")
    overlay = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    overlay.putalpha(grad)
    return Image.alpha_composite(image, overlay)


def text_alpha(local_t, duration):
    fade = min(0.45, duration * 0.18)
    if local_t < fade:
        return max(0, min(1, local_t / fade))
    if local_t > duration - fade:
        return max(0, min(1, (duration - local_t) / fade))
    return 1


def render_frame(frame_idx, images):
    t = frame_idx / FPS
    seg = find_segment(t)
    local_t = t - seg["start"]
    progress = local_t / seg["duration"]
    alpha = text_alpha(local_t, seg["duration"])
    source = images[seg["image"]]
    scale = 1.03 + 0.05 * progress
    offset_x = (progress - 0.5) * 18
    offset_y = (0.5 - progress) * 14
    frame = fit_cover(source, scale, offset_x, offset_y)
    frame = overlay_gradient(frame)
    draw = ImageDraw.Draw(frame)
    gold = (245, 214, 106, int(255 * alpha))
    white = (255, 255, 255, int(255 * alpha))
    muted = (233, 236, 241, int(240 * alpha))
    draw.text((36, 710), seg["kicker"], font=FONT_SMALL, fill=gold)
    draw.multiline_text((36, 760), seg["title"], font=FONT_BOLD, fill=white, spacing=4)
    draw.multiline_text((36, 895), seg["subtitle"], font=FONT_MED, fill=muted, spacing=4)
    return frame.convert("P", palette=Image.Palette.ADAPTIVE)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    images = {seg["image"]: Image.open(SOURCE / seg["image"]) for seg in SEGMENTS}
    total_frames = TOTAL_SECONDS * FPS
    frames = [render_frame(i, images) for i in range(total_frames)]
    frames[0].save(
        GIF,
        save_all=True,
        append_images=frames[1:],
        duration=int(1000 / FPS),
        loop=0,
        optimize=False,
        disposal=2,
    )
    cover = render_frame(int(10.5 * FPS), images).convert("RGBA")
    cover.save(COVER)
    print(GIF)
    print(COVER)


if __name__ == "__main__":
    main()
