from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "social" / "week-2026-05-25"
SOURCE = OUT / "source"
LOGO = ROOT / "assets" / "brand" / "cbme" / "logo-hero-white-text.png"

FONT_BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"


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


def add_depth(img):
    img = ImageEnhance.Contrast(img).enhance(1.08)
    img = ImageEnhance.Color(img).enhance(0.96)
    canvas = img.convert("RGBA")
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    w, h = canvas.size
    for y in range(h):
        alpha = int(34 + 180 * (y / h) ** 1.7)
        draw.line((0, y, w, y), fill=(0, 0, 0, alpha))
    draw.rectangle((0, 0, w, h), fill=(0, 0, 0, 18))
    return Image.alpha_composite(canvas, layer)


def add_logo(canvas):
    logo = Image.open(LOGO).convert("RGBA")
    logo.thumbnail((168, 168), Image.LANCZOS)
    shadow = logo.filter(ImageFilter.GaussianBlur(8))
    canvas.alpha_composite(ImageEnhance.Brightness(shadow).enhance(0), (64, 58))
    canvas.alpha_composite(logo, (60, 54))


def draw_post(source, output, eyebrow, title, subtitle, footer, accent):
    size = (1080, 1350)
    canvas = add_depth(cover(source, size))
    add_logo(canvas)
    draw = ImageDraw.Draw(canvas)

    x = 70
    y = 780
    draw.text((x, y), eyebrow.upper(), fill=accent, font=font(FONT_BOLD, 30))
    y += 58

    title_font = font(FONT_BLACK, 76)
    for line in wrap(draw, title, title_font, 900):
        draw.text((x, y), line, fill=(250, 250, 250), font=title_font, stroke_width=2, stroke_fill=(0, 0, 0))
        y += 86

    y += 18
    subtitle_font = font(FONT_REG, 35)
    for line in wrap(draw, subtitle, subtitle_font, 880):
        draw.text((x, y), line, fill=(226, 231, 238), font=subtitle_font)
        y += 47

    draw.line((x, 1220, 400, 1220), fill=accent, width=4)
    draw.text((x, 1244), footer, fill=(230, 235, 242), font=font(FONT_BOLD, 28))
    canvas.convert("RGB").save(output, quality=96)


def write_review():
    html = """<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Semana 25/05 · Instagram CBME</title>
    <style>
      body { margin: 0; background: #08090d; color: #fff; font-family: Arial, sans-serif; }
      main { max-width: 980px; margin: 0 auto; padding: 32px 20px; }
      h1 { margin: 0 0 8px; font-size: 30px; }
      p { color: #cbd1dc; }
      .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 18px; align-items: start; }
      article { background: #151821; border: 1px solid #2a3039; border-radius: 8px; overflow: hidden; }
      img { display: block; width: 100%; aspect-ratio: 4 / 5; object-fit: cover; background: #050608; }
      .body { padding: 14px; }
      h2 { margin: 0 0 8px; font-size: 17px; }
      .meta { color: #f0d08a; font-size: 13px; margin: 0; }
    </style>
  </head>
  <body>
    <main>
      <h1>Semana 25/05 · Instagram CBME</h1>
      <p>Visuales nuevos generados para revisión antes de publicar o programar.</p>
      <section class="grid">
        <article>
          <img src="post-01-sonorizacion-dj.png" alt="">
          <div class="body"><h2>Sonorización + DJ</h2><p class="meta">Post feed · castellano · 25/05</p></div>
        </article>
        <article>
          <img src="post-02-boda-can-marc.png" alt="">
          <div class="body"><h2>Boda Can Marc</h2><p class="meta">Post feed · catalán · 31/05 o 01/06</p></div>
        </article>
      </section>
      <p><a href="../../../docs/social/instagram-next-events-publishing-pack.md">Ver copies y pendientes</a></p>
    </main>
  </body>
</html>
"""
    (OUT / "review.html").write_text(html, encoding="utf-8")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    draw_post(
        SOURCE / "sonorizacion-dj-source.png",
        OUT / "post-01-sonorizacion-dj.png",
        "Sonido + DJ",
        "Cuando el DJ tambi\u00e9n cuida el sonido",
        "Micro, volumen y montaje coordinados para que el evento funcione de principio a final.",
        "Costa Brava Music Events",
        (242, 196, 107),
    )
    draw_post(
        SOURCE / "can-marc-official-7.webp",
        OUT / "post-02-boda-can-marc.png",
        "Bodes Costa Brava",
        "Cerim\u00f2nia i festa en una mateixa producci\u00f3",
        "Cada moment necessita una energia diferent: entrada, c\u00f2ctel, sopar, primer ball i pista.",
        "Costa Brava Music Events",
        (236, 212, 154),
    )
    write_review()


if __name__ == "__main__":
    main()
