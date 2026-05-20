from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets" / "social" / "week-1-v2"
LOGO = ROOT / "assets" / "img" / "logo-hero-white-text.png"


POSTS = [
    ("bg-01-wedding-terrace.png", "post-01-wedding-terrace.png", "bottom"),
    ("bg-02-cocktail-live.png", "post-02-cocktail-live.png", "top"),
    ("bg-03-masia-night.png", "post-03-masia-night.png", "bottom"),
    ("bg-04-private-party.png", "post-04-private-party.png", "top"),
]


def cover(path, size=(1080, 1350)):
    img = Image.open(path).convert("RGB")
    ratio = max(size[0] / img.width, size[1] / img.height)
    img = img.resize((int(img.width * ratio), int(img.height * ratio)), Image.LANCZOS)
    x = (img.width - size[0]) // 2
    y = (img.height - size[1]) // 2
    return img.crop((x, y, x + size[0], y + size[1]))


def add_vignette(img):
    w, h = img.size
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for y in range(h):
        top = max(0, 120 - y)
        bottom = max(0, y - int(h * 0.58))
        alpha = min(150, int(top * 1.3 + bottom * 0.55))
        draw.line((0, y, w, y), fill=(0, 0, 0, alpha))
    return Image.alpha_composite(img.convert("RGBA"), overlay)


def paste_logo(canvas, position):
    logo = Image.open(LOGO).convert("RGBA")
    logo.thumbnail((188, 188), Image.LANCZOS)
    x = 64
    y = 58 if position == "top" else canvas.height - logo.height - 58
    shadow = Image.new("RGBA", logo.size, (0, 0, 0, 0))
    shadow.alpha_composite(logo)
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    canvas.alpha_composite(ImageEnhance.Brightness(shadow).enhance(0), (x + 4, y + 6))
    canvas.alpha_composite(logo, (x, y))


def main():
    for bg, out, logo_pos in POSTS:
        img = cover(SRC / bg)
        img = ImageEnhance.Color(img).enhance(0.94)
        img = ImageEnhance.Contrast(img).enhance(1.04)
        canvas = add_vignette(img)
        paste_logo(canvas, logo_pos)
        canvas.convert("RGB").save(SRC / out, quality=95)


if __name__ == "__main__":
    main()
