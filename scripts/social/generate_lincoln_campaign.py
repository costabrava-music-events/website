from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "social" / "lincoln-2026-05-29"
SOURCE = OUT / "source"
LINCOLN = ROOT / "assets" / "brand" / "partners" / "lincoln"
CBME = ROOT / "assets" / "brand" / "cbme"

BG = SOURCE / "gpt-background-v2-90s.png"
LINCOLN_ORIGINAL = LINCOLN / "logo-original.jpg"
LINCOLN_ALPHA = LINCOLN / "logo-transparent.png"
CBME_LOGO = CBME / "logo-hero-white-text.png"

GOLD = (229, 188, 80)
GOLD_LIGHT = (255, 226, 137)
BLUE = (48, 126, 255)
PINK = (211, 54, 194)
WHITE = (248, 249, 252)
MUTED = (196, 203, 214)

FONT_BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_NARROW = "/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf"


def font(path, size):
    try:
        return ImageFont.truetype(path, size=size)
    except OSError:
        return ImageFont.load_default(size=size)


def cover(path, size):
    img = Image.open(path).convert("RGB")
    ratio = max(size[0] / img.width, size[1] / img.height)
    resized = img.resize((int(img.width * ratio), int(img.height * ratio)), Image.LANCZOS)
    x = (resized.width - size[0]) // 2
    y = (resized.height - size[1]) // 2
    return resized.crop((x, y, x + size[0], y + size[1]))


def make_lincoln_alpha():
    img = Image.open(LINCOLN_ORIGINAL).convert("RGBA")
    pixels = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            brightness = max(r, g, b)
            if brightness < 28:
                pixels[x, y] = (r, g, b, 0)
            elif brightness < 52:
                pixels[x, y] = (r, g, b, int((brightness - 28) * 5))
    img.save(LINCOLN_ALPHA)


def text_center(draw, xy, text, text_font, fill, stroke=0, stroke_fill=(0, 0, 0), spacing=0):
    x, y = xy
    lines = text.split("\n")
    total_h = 0
    boxes = []
    for line in lines:
        box = draw.textbbox((0, 0), line, font=text_font, stroke_width=stroke)
        boxes.append(box)
        total_h += box[3] - box[1] + spacing
    total_h -= spacing
    yy = y - total_h // 2
    for line, box in zip(lines, boxes):
        w = box[2] - box[0]
        h = box[3] - box[1]
        draw.text(
            (x - w // 2, yy),
            line,
            font=text_font,
            fill=fill,
            stroke_width=stroke,
            stroke_fill=stroke_fill,
        )
        yy += h + spacing


def rounded_rect(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def add_vignette(img):
    w, h = img.size
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for y in range(h):
        alpha = int(80 * abs(y - h / 2) / (h / 2))
        draw.line((0, y, w, y), fill=(0, 0, 0, alpha))
    for x in range(w):
        alpha = int(95 * abs(x - w / 2) / (w / 2))
        draw.line((x, 0, x, h), fill=(0, 0, 0, alpha))
    return Image.alpha_composite(img.convert("RGBA"), layer)


def add_depth(img):
    canvas = img.convert("RGBA")
    w, h = canvas.size
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rectangle((0, 0, w, h), fill=(0, 0, 0, 28))
    for y in range(h):
        top = max(0, 180 - y)
        bottom = max(0, y - int(h * 0.58))
        alpha = min(160, int(top * 0.72 + bottom * 0.42))
        draw.line((0, y, w, y), fill=(0, 0, 0, alpha))
    return Image.alpha_composite(canvas, layer)


def logo(path, max_size):
    img = Image.open(path).convert("RGBA")
    img.thumbnail(max_size, Image.LANCZOS)
    return img


def paste_logo(canvas, img, center, glow=True):
    x = int(center[0] - img.width / 2)
    y = int(center[1] - img.height / 2)
    if glow:
        shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
        shadow.alpha_composite(img)
        shadow = shadow.filter(ImageFilter.GaussianBlur(18))
        canvas.alpha_composite(shadow, (x, y))
    canvas.alpha_composite(img, (x, y))


def text_left(draw, xy, text, text_font, fill, stroke=0, stroke_fill=(0, 0, 0), spacing=0):
    x, y = xy
    lines = text.split("\n")
    yy = y
    for line in lines:
        draw.text(
            (x, yy),
            line,
            font=text_font,
            fill=fill,
            stroke_width=stroke,
            stroke_fill=stroke_fill,
        )
        box = draw.textbbox((0, 0), line, font=text_font, stroke_width=stroke)
        yy += box[3] - box[1] + spacing


def divider(draw, x, y, w):
    draw.line((x, y, x + w, y), fill=(229, 188, 80, 210), width=4)
    draw.line((x, y + 10, x + int(w * 0.45), y + 10), fill=(48, 126, 255, 180), width=3)


def base(size, crop_y=0):
    img = cover(BG, (size[0], int(size[1] * 1.05)))
    if crop_y:
        img = img.crop((0, crop_y, size[0], crop_y + size[1]))
    else:
        img = img.crop((0, 0, size[0], size[1]))
    img = ImageEnhance.Contrast(img).enhance(1.12)
    img = ImageEnhance.Color(img).enhance(1.08)
    return add_depth(add_vignette(img))


def draw_main_flyer(size, output, story=False):
    canvas = base(size)
    draw = ImageDraw.Draw(canvas)
    w, h = size

    lincoln = logo(LINCOLN_ALPHA, (360 if not story else 420, 190 if not story else 230))
    cbme = logo(CBME_LOGO, (118 if not story else 136, 118 if not story else 136))

    margin = 72 if not story else 88
    paste_logo(canvas, lincoln, (margin + lincoln.width // 2, 98 if not story else 132))
    paste_logo(canvas, cbme, (w - margin - cbme.width // 2, 96 if not story else 130), glow=False)

    card_top = 255 if not story else 315
    card_bottom = 1188 if not story else 1728
    rounded_rect(draw, (margin, card_top, w - margin, card_bottom), 34, (0, 0, 0, 118), (229, 188, 80, 130), 2)
    draw.rounded_rectangle((margin + 14, card_top + 14, w - margin - 14, card_bottom - 14), radius=26, outline=(48, 126, 255, 90), width=2)

    date_font = font(FONT_BOLD, 45 if not story else 52)
    title_font = font(FONT_BLACK, 150 if not story else 122)
    title2_font = font(FONT_BLACK, 132 if not story else 112)
    dj_font = font(FONT_BLACK, 56 if not story else 58)
    style_font = font(FONT_NARROW, 39 if not story else 32)
    time_font = font(FONT_BOLD, 38 if not story else 31)
    small_font = font(FONT_REG, 28 if not story else 31)

    x = margin + (56 if not story else 54)
    center_x = w // 2
    y = card_top + (62 if not story else 82)
    text_center(draw, (center_x, y + (28 if story else 26)), "VIERNES 29 MAYO", date_font, GOLD_LIGHT, 1)
    divider(draw, x, y + (70 if not story else 88), w - margin * 2 - 112)

    text_center(draw, (center_x, y + (200 if story else 210)), "LINCOLN", title_font, WHITE, 3)
    text_center(draw, (center_x, y + (340 if story else 355)), "90s", title2_font, WHITE, 3)

    dj_y = y + (430 if not story else 475)
    text_center(draw, (center_x, dj_y + (34 if story else 32)), "DJ DANI HOMS", dj_font, GOLD_LIGHT, 2)
    text_center(draw, (center_x, dj_y + (113 if story else 104)), "90s DANCE HOUSE · REMEMBER CLASSICS", style_font, WHITE, 1)

    pill_y = dj_y + (150 if not story else 190)
    rounded_rect(draw, (x, pill_y, w - margin - (56 if not story else 54), pill_y + (82 if not story else 104)), 24, (10, 30, 86, 218), (72, 145, 255, 180), 2)
    text_center(draw, (w // 2, pill_y + (41 if not story else 52)), "A PARTIR DE LAS 23:00 · HASTA CIERRE", time_font, WHITE, 1)

    text_center(draw, (center_x, pill_y + (178 if story else 136)), "Los mejores remembers y clásicos dance de los 90", small_font, MUTED)

    footer_y = card_bottom - (98 if not story else 190)
    divider(draw, x, footer_y - 32, w - margin * 2 - 112)
    if story:
        text_center(draw, (center_x, footer_y + 18), "Sala de Festa Lincoln", font(FONT_BOLD, 36), WHITE)
        text_center(draw, (center_x, footer_y + 64), "Costa Brava Music Events", font(FONT_BOLD, 36), WHITE)
        text_center(draw, (center_x, footer_y + 112), "@costabrava_music_events", font(FONT_REG, 32), (210, 218, 230))
    else:
        text_center(draw, (center_x, footer_y + 16), "Sala de Festa Lincoln · Costa Brava Music Events", font(FONT_BOLD, 29), WHITE)
        text_center(draw, (center_x, footer_y + 58), "@costabrava_music_events", font(FONT_REG, 25), (210, 218, 230))

    canvas.convert("RGB").save(output, quality=96)


def draw_story_countdown():
    size = (1080, 1920)
    canvas = base(size)
    draw = ImageDraw.Draw(canvas)
    w, h = size
    lincoln = logo(LINCOLN_ALPHA, (480, 270))
    paste_logo(canvas, lincoln, (w // 2, 255))
    text_center(draw, (w // 2, 555), "29 MAYO", font(FONT_BLACK, 150), WHITE, 3)
    text_center(draw, (w // 2, 705), "DJ DANI HOMS", font(FONT_BLACK, 72), GOLD_LIGHT, 2)
    text_center(draw, (w // 2, 790), "DESDE LAS 23:00", font(FONT_BOLD, 66), WHITE, 2)
    rounded_rect(draw, (118, 900, w - 118, 1160), 36, (0, 0, 0, 150), (216, 178, 77, 160), 3)
    text_center(draw, (w // 2, 995), "90'S DANCE HOUSE", font(FONT_BLACK, 76), WHITE, 2)
    text_center(draw, (w // 2, 1090), "REMEMBER CLASSICS", font(FONT_BOLD, 60), GOLD_LIGHT, 1)
    text_center(draw, (w // 2, 1400), "Activa el recordatorio", font(FONT_BOLD, 58), WHITE, 1)
    text_center(draw, (w // 2, 1480), "y ven a cerrar la noche con nosotros", font(FONT_REG, 42), MUTED)
    canvas.convert("RGB").save(OUT / "lincoln-90s-story-countdown.png", quality=96)


def draw_story_music():
    size = (1080, 1920)
    canvas = base(size)
    draw = ImageDraw.Draw(canvas)
    w, h = size
    cbme = logo(CBME_LOGO, (150, 150))
    paste_logo(canvas, cbme, (w - 125, 130), glow=False)
    text_center(draw, (w // 2, 285), "ESTE VIERNES", font(FONT_BOLD, 68), GOLD_LIGHT, 1)
    text_center(draw, (w // 2, 440), "VUELVEN\nLOS 90", font(FONT_BLACK, 160), WHITE, 3, spacing=8)
    items = ["DANCE HOUSE", "REMEMBER", "CLASSICS 90s", "HASTA CIERRE"]
    y = 760
    for item in items:
        rounded_rect(draw, (170, y, w - 170, y + 112), 28, (0, 0, 0, 150), (70, 145, 255, 125), 2)
        text_center(draw, (w // 2, y + 56), item, font(FONT_BOLD, 52), WHITE, 1)
        y += 142
    text_center(draw, (w // 2, 1458), "DJ DANI HOMS", font(FONT_BLACK, 58), WHITE, 2)
    text_center(draw, (w // 2, 1530), "LINCOLN · 29 MAYO · 23:00", font(FONT_BOLD, 48), GOLD_LIGHT, 1)
    text_center(draw, (w // 2, 1600), "hasta cierre", font(FONT_REG, 42), MUTED)
    canvas.convert("RGB").save(OUT / "lincoln-90s-story-music.png", quality=96)


def write_review():
    html = """<!doctype html>
<html lang=\"es\">
  <head>
    <meta charset=\"utf-8\" />
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
    <title>Lincoln 90s Campaign</title>
    <style>
      body { margin: 0; background: #08090d; color: #fff; font-family: Arial, sans-serif; }
      main { max-width: 1180px; margin: 0 auto; padding: 32px 20px; }
      h1 { margin: 0 0 8px; font-size: 30px; }
      p { color: #cbd1dc; }
      .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 18px; align-items: start; }
      article { background: #151821; border: 1px solid #2a3039; border-radius: 8px; overflow: hidden; }
      img { display: block; width: 100%; background: #050608; }
      .feed { aspect-ratio: 4 / 5; object-fit: cover; }
      .story { aspect-ratio: 9 / 16; object-fit: cover; }
      .body { padding: 14px; }
      h2 { margin: 0 0 8px; font-size: 17px; }
      .meta { color: #f0d08a; font-size: 13px; margin: 0; }
    </style>
  </head>
  <body>
    <main>
      <h1>Lincoln 90s · Campaña Instagram</h1>
      <p>Flyer con base GPT Image, logos reales y texto compuesto localmente para revisión antes de publicar.</p>
      <section class=\"grid\">
        <article>
          <img class=\"feed\" src=\"lincoln-90s-feed.png\" alt=\"\">
          <div class=\"body\"><h2>Publicación feed</h2><p class=\"meta\">1080x1350 · Viernes 29 mayo · 23:00</p></div>
        </article>
        <article>
          <img class=\"story\" src=\"lincoln-90s-story-main.png\" alt=\"\">
          <div class=\"body\"><h2>Story principal</h2><p class=\"meta\">1080x1920 · Flyer vertical</p></div>
        </article>
        <article>
          <img class=\"story\" src=\"lincoln-90s-story-countdown.png\" alt=\"\">
          <div class=\"body\"><h2>Story recordatorio</h2><p class=\"meta\">Sticker sugerido: cuenta atrás</p></div>
        </article>
        <article>
          <img class=\"story\" src=\"lincoln-90s-story-music.png\" alt=\"\">
          <div class=\"body\"><h2>Story música</h2><p class=\"meta\">Dance house · remember classics</p></div>
        </article>
      </section>
    </main>
  </body>
</html>
"""
    (OUT / "review.html").write_text(html, encoding="utf-8")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    LINCOLN.mkdir(parents=True, exist_ok=True)
    make_lincoln_alpha()
    draw_main_flyer((1080, 1350), OUT / "lincoln-90s-feed.png")
    draw_main_flyer((1080, 1920), OUT / "lincoln-90s-story-main.png", story=True)
    draw_story_countdown()
    draw_story_music()
    write_review()


if __name__ == "__main__":
    main()
