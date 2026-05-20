from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
IMG = ROOT / "assets" / "img"
OUT = ROOT / "assets" / "social" / "week-1-v2"
GPT_EDU = OUT / "gpt-educational-source"
LOGO = IMG / "logo-hero-white-text.png"

FONT_PATHS = [
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/Library/Fonts/Arial.ttf",
]


def font(size, bold=True):
    paths = FONT_PATHS if bold else list(reversed(FONT_PATHS))
    for path in paths:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            pass
    return ImageFont.load_default(size=size)


def cover(path, size):
    img = Image.open(path).convert("RGB")
    ratio = max(size[0] / img.width, size[1] / img.height)
    resized = img.resize((int(img.width * ratio), int(img.height * ratio)), Image.LANCZOS)
    x = (resized.width - size[0]) // 2
    y = (resized.height - size[1]) // 2
    return resized.crop((x, y, x + size[0], y + size[1]))


def wrap(draw, text, text_font, max_width):
    lines = []
    current = ""
    for word in text.split():
        test = f"{current} {word}".strip()
        if draw.textbbox((0, 0), test, font=text_font)[2] <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def overlay(img):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    width, height = img.size
    for y in range(height):
        alpha = int(210 * (y / height))
        draw.line((0, y, width, y), fill=(0, 0, 0, alpha))
    return Image.alpha_composite(img.convert("RGBA"), layer)


def add_logo(canvas):
    logo = Image.open(LOGO).convert("RGBA")
    logo.thumbnail((176, 176), Image.LANCZOS)
    shadow = logo.filter(ImageFilter.GaussianBlur(8))
    canvas.alpha_composite(ImageEnhance.Brightness(shadow).enhance(0), (68, 64))
    canvas.alpha_composite(logo, (64, 58))


def draw_block(draw, title, subtitle, index=None):
    title_font = font(72)
    sub_font = font(34, bold=False)
    y = 815
    for line in wrap(draw, title, title_font, 900):
        draw.text((70, y), line, fill="white", font=title_font)
        y += 84
    y += 24
    for line in wrap(draw, subtitle, sub_font, 880):
        draw.text((70, y), line, fill=(235, 238, 242), font=sub_font)
        y += 46
    if index:
        draw.text((885, 1230), index, fill=(245, 210, 145), font=font(34))


def save_carousel():
    size = (1080, 1350)
    slides = [
        (
            "La música d'una boda no comença a la festa",
            "Guia ràpida per ordenar cada moment",
            "slide-01-dj-table.png",
        ),
        (
            "Cerimònia i còctel",
            "Ambient, emoció i conversa sense tapar el moment.",
            "slide-02-ceremony-cocktail.png",
        ),
        (
            "Sopar i festa",
            "Volum, energia i pista en el punt just.",
            "slide-03-masia-party.png",
        ),
    ]
    for index, (title, subtitle, image) in enumerate(slides, start=1):
        bg = cover(GPT_EDU / image, size)
        bg = ImageEnhance.Color(bg).enhance(0.96)
        bg = ImageEnhance.Contrast(bg).enhance(1.04)
        canvas = overlay(bg)
        add_logo(canvas)
        draw = ImageDraw.Draw(canvas)
        draw_block(draw, title, subtitle, f"{index}/3")
        canvas.convert("RGB").save(OUT / f"post-03-educational-gpt-ca-{index:02d}.png", quality=95)


def save_artist_post():
    size = (1080, 1350)
    bg = cover(IMG / "onedaydj.jpg", size)
    bg = ImageEnhance.Color(bg).enhance(1.04)
    bg = ImageEnhance.Contrast(bg).enhance(1.08)
    canvas = overlay(bg)
    add_logo(canvas)
    draw = ImageDraw.Draw(canvas)
    draw_block(
        draw,
        "Artist focus",
        "OneDayDJs - electronic 80/90s sets with live percussion for events.",
    )
    canvas.convert("RGB").save(OUT / "post-04-artist-focus-onedaydjs-en.png", quality=95)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    save_carousel()
    save_artist_post()


if __name__ == "__main__":
    main()
