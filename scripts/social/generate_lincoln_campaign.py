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


def base(size, crop_y=0):
    img = cover(BG, (size[0], int(size[1] * 1.05)))
    if crop_y:
        img = img.crop((0, crop_y, size[0], crop_y + size[1]))
    else:
        img = img.crop((0, 0, size[0], size[1]))
    img = ImageEnhance.Contrast(img).enhance(1.08)
    img = ImageEnhance.Color(img).enhance(1.05)
    return add_vignette(img)


def draw_main_flyer(size, output, story=False):
    canvas = base(size)
    draw = ImageDraw.Draw(canvas)
    w, h = size

    lincoln = logo(LINCOLN_ALPHA, (470 if not story else 520, 260 if not story else 300))
    cbme = logo(CBME_LOGO, (128 if not story else 150, 128 if not story else 150))

    paste_logo(canvas, lincoln, (w // 2, int(h * 0.155 if not story else h * 0.15)))
    paste_logo(canvas, cbme, (w - 108 if not story else w - 118, 112 if not story else 130), glow=False)

    top = int(h * (0.29 if not story else 0.32))
    panel_h = 690 if not story else 830
    rounded_rect(
        draw,
        (82, top, w - 82, top + panel_h),
        34,
        (0, 0, 0, 142),
        (216, 178, 77, 150),
        3,
    )

    text_center(draw, (w // 2, top + (70 if not story else 86)), "VIERNES 29 MAYO", font(FONT_BOLD, 46 if not story else 54), GOLD_LIGHT, 1)
    text_center(draw, (w // 2, top + (185 if not story else 232)), "LINCOLN\n90'S", font(FONT_BLACK, 112 if not story else 130), WHITE, 3, (0, 0, 0), 0)
    text_center(draw, (w // 2, top + (334 if not story else 407)), "DJ DANI HOMS", font(FONT_BLACK, 54 if not story else 68), GOLD_LIGHT, 2, (0, 0, 0))
    text_center(draw, (w // 2, top + (403 if not story else 492)), "90s DANCE HOUSE · REMEMBER CLASSICS", font(FONT_NARROW, 37 if not story else 42), GOLD_LIGHT, 1)

    pill_y = top + (470 if not story else 585)
    rounded_rect(draw, (145, pill_y, w - 145, pill_y + (86 if not story else 102)), 28, (7, 24, 64, 210), (70, 145, 255, 180), 2)
    text_center(draw, (w // 2, pill_y + (43 if not story else 51)), "A PARTIR DE LAS 23:00 · HASTA CIERRE", font(FONT_BOLD, 35 if not story else 37), WHITE, 1)

    text_center(draw, (w // 2, top + (605 if not story else 750)), "Los mejores remembers y clásicos dance de los 90", font(FONT_REG, 30 if not story else 36), MUTED)

    footer_y = h - (106 if not story else 150)
    text_center(draw, (w // 2, footer_y), "Sala de Festa Lincoln  ·  Costa Brava Music Events", font(FONT_BOLD, 30 if not story else 38), WHITE)
    text_center(draw, (w // 2, footer_y + (42 if not story else 54)), "@costabrava_music_events", font(FONT_REG, 25 if not story else 34), (210, 218, 230))

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
