from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "social" / "dc-sant-joan-2026"
SOURCE = OUT / "source"

BG = SOURCE / "sant-joan-beach-club-bg.png"
DC_LOGO = SOURCE / "logo-dc-beach-club-blau-mari.png"
CBME_LOGO = ROOT / "assets" / "brand" / "cbme" / "logo-hero-white-text.png"

NAVY = (8, 22, 38, 235)
INK = (3, 10, 17, 230)
GOLD = (235, 187, 94)
GOLD_LIGHT = (255, 224, 154)
WHITE = (248, 249, 245)
MUTED = (205, 216, 220)
BLUE = (33, 96, 139)

FONT_BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_NARROW = "/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf"
FONT_DIN = "/System/Library/Fonts/Supplemental/DIN Condensed Bold.ttf"
FONT_IMPACT = "/System/Library/Fonts/Supplemental/Impact.ttf"
FONT_AVENIR_COND = "/System/Library/Fonts/Avenir Next Condensed.ttc"
FONT_FUTURA = "/System/Library/Fonts/Supplemental/Futura.ttc"


def font(path, size):
    try:
        return ImageFont.truetype(path, size=size)
    except OSError:
        return ImageFont.load_default(size=size)


def cover(path, size, focus_y=0.5):
    img = Image.open(path).convert("RGB")
    ratio = max(size[0] / img.width, size[1] / img.height)
    img = img.resize((int(img.width * ratio), int(img.height * ratio)), Image.LANCZOS)
    x = (img.width - size[0]) // 2
    max_y = max(0, img.height - size[1])
    y = int(max_y * focus_y)
    return img.crop((x, y, x + size[0], y + size[1]))


def add_grade(img, dark=58):
    canvas = img.convert("RGBA")
    w, h = canvas.size
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rectangle((0, 0, w, h), fill=(0, 8, 16, dark))
    for y in range(h):
        top = max(0, 180 - y)
        bottom = max(0, y - int(h * 0.55))
        alpha = min(180, int(top * 0.45 + bottom * 0.5))
        draw.line((0, y, w, y), fill=(0, 0, 0, alpha))
    return Image.alpha_composite(canvas, layer)


def polish_sky_and_fireworks(canvas, sky_strength=1.0, firework_strength=1.0):
    w, h = canvas.size

    sky = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(sky)
    sky_h = int(h * 0.52)
    for y in range(sky_h):
        fade = 1 - (y / sky_h)
        alpha = int(42 * sky_strength * fade)
        draw.line((0, y, w, y), fill=(42, 104, 152, alpha))
    canvas = Image.alpha_composite(canvas, sky)

    x0 = int(w * 0.62)
    y0 = int(h * 0.03)
    x1 = w
    y1 = int(h * 0.34)
    fireworks = canvas.crop((x0, y0, x1, y1))
    fireworks = ImageEnhance.Brightness(fireworks).enhance(1 + 0.10 * firework_strength)
    fireworks = ImageEnhance.Contrast(fireworks).enhance(1 + 0.22 * firework_strength)
    fireworks = ImageEnhance.Color(fireworks).enhance(1 + 0.28 * firework_strength)
    fireworks = ImageEnhance.Sharpness(fireworks).enhance(1 + 0.35 * firework_strength)

    mask = Image.new("L", fireworks.size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse(
        (
            int(fireworks.width * 0.10),
            int(fireworks.height * -0.05),
            int(fireworks.width * 1.05),
            int(fireworks.height * 0.95),
        ),
        fill=210,
    )
    mask = mask.filter(ImageFilter.GaussianBlur(32))
    canvas.paste(fireworks, (x0, y0), mask)
    return canvas


def logo(path, max_size):
    img = Image.open(path).convert("RGBA")
    bbox = img.getchannel("A").getbbox()
    if bbox:
        pad = 14
        img = img.crop((
            max(0, bbox[0] - pad),
            max(0, bbox[1] - pad),
            min(img.width, bbox[2] + pad),
            min(img.height, bbox[3] + pad),
        ))
    img.thumbnail(max_size, Image.LANCZOS)
    return img


def paste_logo(canvas, img, box, anchor="center"):
    x0, y0, x1, y1 = box
    if anchor == "left":
        x = x0
    elif anchor == "right":
        x = x1 - img.width
    else:
        x = x0 + ((x1 - x0) - img.width) // 2
    y = y0 + ((y1 - y0) - img.height) // 2
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow.alpha_composite(img)
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    canvas.alpha_composite(shadow, (x + 4, y + 6))
    canvas.alpha_composite(img, (x, y))


def text_box(draw, box, text, text_font, fill, align="center", stroke=0, spacing=0, stroke_fill=(0, 0, 0, 210)):
    x0, y0, x1, y1 = box
    lines = text.split("\n")
    heights = []
    widths = []
    for line in lines:
        b = draw.textbbox((0, 0), line, font=text_font, stroke_width=stroke)
        widths.append(b[2] - b[0])
        heights.append(b[3] - b[1])
    total_h = sum(heights) + spacing * (len(lines) - 1)
    y = y0 + ((y1 - y0) - total_h) / 2
    for line, width, height in zip(lines, widths, heights):
        if align == "left":
            x = x0
        elif align == "right":
            x = x1 - width
        else:
            x = x0 + ((x1 - x0) - width) / 2
        draw.text((x, y), line, font=text_font, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)
        y += height + spacing


def text_center(draw, center_y, text, text_font, fill, stroke=0, tracking=0, stroke_fill=(0, 0, 0, 220)):
    if tracking <= 0:
        box = draw.textbbox((0, 0), text, font=text_font, stroke_width=stroke)
        x = (1080 - (box[2] - box[0])) / 2
        y = center_y - (box[3] - box[1]) / 2
        draw.text((x, y), text, font=text_font, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)
        return

    widths = [draw.textlength(char, font=text_font) for char in text]
    total_width = sum(widths) + tracking * (len(text) - 1)
    x = (1080 - total_width) / 2
    box = draw.textbbox((0, 0), text, font=text_font, stroke_width=stroke)
    y = center_y - (box[3] - box[1]) / 2
    for char, width in zip(text, widths):
        draw.text((x, y), char, font=text_font, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)
        x += width + tracking


def event_stack(draw, spec):
    text_center(draw, spec["title_1_y"], spec["title_1"], font(FONT_DIN, spec["title_1_size"]), WHITE, stroke=2, tracking=2)
    text_center(draw, spec["title_2_y"], spec["title_2"], font(FONT_IMPACT, spec["title_2_size"]), WHITE, stroke=2, tracking=1)
    text_center(draw, spec["dj_y"], "DJ ALB3RT BIT", font(FONT_FUTURA, spec["dj_size"]), GOLD_LIGHT, stroke=2)
    text_center(draw, spec["music_y"], "80s · 90s · HITS", font(FONT_DIN, spec["music_size"]), WHITE, stroke=2, tracking=2)
    text_center(draw, spec["place_y"], "DC BEACH CLUB · LA FOSCA", font(FONT_AVENIR_COND, spec["place_size"]), GOLD_LIGHT, stroke=1, tracking=1)
    if "\n" in spec["time"]:
        text_box(
            draw,
            (80, spec["time_y"] - 44, 1000, spec["time_y"] + 58),
            spec["time"],
            font(FONT_DIN, spec["time_size"]),
            WHITE,
            stroke=2,
            spacing=0,
        )
    else:
        text_center(draw, spec["time_y"], spec["time"], font(FONT_DIN, spec["time_size"]), WHITE, stroke=2, tracking=1)


def draw_dc_logo(canvas, y, size, max_size):
    w, _ = size
    dc = logo(DC_LOGO, max_size)
    paste_logo(canvas, dc, (0, y, w, y + max_size[1]), "center")


def draw_cbme_footer(canvas, draw, y, size, logo_size, text_size):
    w, _ = size
    cbme = logo(CBME_LOGO, logo_size)
    paste_logo(canvas, cbme, (0, y, w, y + logo_size[1]), "center")
    text_box(
        draw,
        (80, y + logo_size[1] - 4, w - 80, y + logo_size[1] + 54),
        "Costa Brava Music Events",
        font(FONT_BOLD, text_size),
        WHITE,
        stroke=1,
    )


def main_feed():
    size = (1080, 1350)
    canvas = polish_sky_and_fireworks(add_grade(cover(BG, size, focus_y=0.44), dark=26), 1.05, 1.0)
    draw = ImageDraw.Draw(canvas)
    w, h = size
    draw_dc_logo(canvas, 24, size, (390, 278))
    event_stack(draw, {
        "title_1": "REVETLLA DE SANT JOAN",
        "title_2": "A LA PISTA DE BALL",
        "title_1_y": 360,
        "title_2_y": 414,
        "title_1_size": 70,
        "title_2_size": 52,
        "dj_y": 560,
        "dj_size": 64,
        "music_y": 632,
        "music_size": 58,
        "place_y": 730,
        "place_size": 48,
        "time_y": 790,
        "time_size": 45,
        "time": "23 JUNY\nDE 23:30 A TANCAMENT",
    })
    draw_cbme_footer(canvas, draw, 1076, size, (220, 220), 35)
    canvas.convert("RGB").save(OUT / "dc-sant-joan-feed.png", quality=96)


def story_main():
    size = (1080, 1920)
    canvas = polish_sky_and_fireworks(add_grade(cover(BG, size, focus_y=0.48), dark=36), 1.12, 1.15)
    draw = ImageDraw.Draw(canvas)
    w, h = size
    draw_dc_logo(canvas, 62, size, (430, 305))
    event_stack(draw, {
        "title_1": "REVETLLA DE SANT JOAN",
        "title_2": "SOPAR I FESTA",
        "title_1_y": 455,
        "title_2_y": 522,
        "title_1_size": 82,
        "title_2_size": 68,
        "dj_y": 735,
        "dj_size": 76,
        "music_y": 822,
        "music_size": 70,
        "place_y": 942,
        "place_size": 56,
        "time_y": 1014,
        "time_size": 52,
        "time": "23 JUNY\nDE 23:30 A TANCAMENT",
    })
    draw_cbme_footer(canvas, draw, 1508, size, (285, 285), 44)
    canvas.convert("RGB").save(OUT / "dc-sant-joan-story-main.png", quality=96)


def story_music():
    size = (1080, 1920)
    canvas = polish_sky_and_fireworks(add_grade(cover(BG, size, focus_y=0.36), dark=46), 1.12, 1.15)
    draw = ImageDraw.Draw(canvas)
    w, h = size
    draw_dc_logo(canvas, 62, size, (430, 305))
    event_stack(draw, {
        "title_1": "REVETLLA DE SANT JOAN",
        "title_2": "A LA PISTA DE BALL",
        "title_1_y": 455,
        "title_2_y": 522,
        "title_1_size": 82,
        "title_2_size": 68,
        "dj_y": 735,
        "dj_size": 76,
        "music_y": 830,
        "music_size": 70,
        "place_y": 958,
        "place_size": 56,
        "time_y": 1034,
        "time_size": 66,
        "time": "DE 23:30 A TANCAMENT",
    })
    draw_cbme_footer(canvas, draw, 1508, size, (285, 285), 44)
    canvas.convert("RGB").save(OUT / "dc-sant-joan-story-music.png", quality=96)


def contact_sheet():
    files = [
        ("Feed", OUT / "dc-sant-joan-feed.png"),
        ("Story main", OUT / "dc-sant-joan-story-main.png"),
        ("Story music", OUT / "dc-sant-joan-story-music.png"),
    ]
    thumb_w = 380
    sheet = Image.new("RGB", (1420, 980), (7, 17, 28))
    draw = ImageDraw.Draw(sheet)
    text_box(draw, (40, 28, 1380, 92), "DC Beach Club · Sant Joan 2026", font(FONT_BOLD, 42), WHITE)
    x = 80
    for label, path in files:
        img = Image.open(path).convert("RGB")
        img.thumbnail((thumb_w, 780), Image.LANCZOS)
        y = 150 + (780 - img.height) // 2
        sheet.paste(img, (x, y))
        draw.rectangle((x, y, x + img.width, y + img.height), outline=GOLD, width=2)
        text_box(draw, (x, 900, x + thumb_w, 945), label, font(FONT_BOLD, 24), WHITE)
        x += 440
    sheet.save(OUT / "contact-sheet.png", quality=95)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    main_feed()
    story_main()
    story_music()
    contact_sheet()


if __name__ == "__main__":
    main()
