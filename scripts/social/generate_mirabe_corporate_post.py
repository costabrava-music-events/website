from pathlib import Path
import shutil

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "social" / "mirabe-2026-05-19"
SOURCE = OUT / "source"
DOC = ROOT / "docs" / "social" / "mirabe-2026-05-19-publishing-pack.md"
DOWNLOADS = Path("/Users/albertbitdj/Downloads")
INPUTS = {
    "room": DOWNLOADS / "WhatsApp Image 2026-05-19 at 21.37.29.jpeg",
    "speaker": DOWNLOADS / "WhatsApp Image 2026-05-19 at 21.37.29 (3).jpeg",
    "technical": DOWNLOADS / "WhatsApp Image 2026-05-19 at 21.37.29 (4).jpeg",
    "ambience": DOWNLOADS / "WhatsApp Image 2026-05-19 at 21.37.29 (2).jpeg",
}

SIZE = (1080, 1350)
def cover(path, size=SIZE, focal_y=0.5):
    img = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
    ratio = max(size[0] / img.width, size[1] / img.height)
    resized = img.resize((int(img.width * ratio), int(img.height * ratio)), Image.LANCZOS)
    x = (resized.width - size[0]) // 2
    y = int(resized.height * focal_y - size[1] / 2)
    y = max(0, min(y, resized.height - size[1]))
    return resized.crop((x, y, x + size[0], y + size[1]))


def enhance(img):
    img = ImageEnhance.Color(img).enhance(0.96)
    img = ImageEnhance.Contrast(img).enhance(1.08)
    img = ImageEnhance.Sharpness(img).enhance(1.08)
    return img


def add_vignette(img):
    canvas = img.convert("RGBA")
    w, h = canvas.size
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for y in range(h):
        alpha = max(0, int((y - h * 0.55) * 0.18))
        draw.line((0, y, w, y), fill=(0, 0, 0, min(alpha, 110)))
    for x in range(w):
        edge = max(0, 80 - min(x, w - x))
        if edge:
            draw.line((x, 0, x, h), fill=(0, 0, 0, min(edge, 70)))
    return Image.alpha_composite(canvas, overlay)


def blur_area(img, area):
    canvas = img.convert("RGBA")
    patch = canvas.crop(area).filter(ImageFilter.GaussianBlur(14))
    canvas.paste(patch, area)
    return canvas


def mask_room_screen(img):
    canvas = img.convert("RGBA")
    area = (130, 300, 700, 610)
    patch = canvas.crop(area).filter(ImageFilter.GaussianBlur(12))
    canvas.paste(patch, area)
    return canvas


def save_slide(key, out_name, focal_y, blur_areas=()):
    img = enhance(cover(INPUTS[key], focal_y=focal_y))
    canvas = add_vignette(img)
    for area in blur_areas:
        canvas = blur_area(canvas, area)
    canvas.convert("RGB").save(OUT / out_name, quality=95)


def write_review():
    html = """<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Mirabé · Evento corporativo</title>
    <style>
      body { margin: 0; background: #0b0d10; color: white; font-family: Arial, sans-serif; }
      main { max-width: 1180px; margin: 0 auto; padding: 32px 20px; }
      h1 { margin: 0 0 8px; font-size: 30px; }
      p, pre { color: #c8ced8; }
      a { color: #f0d08a; }
      .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(245px, 1fr)); gap: 16px; }
      img { width: 100%; display: block; border-radius: 8px; background: #050608; }
      .copy { margin-top: 28px; background: #151920; border: 1px solid #2a3039; border-radius: 8px; padding: 18px; }
      pre { white-space: pre-wrap; font-family: Arial, sans-serif; line-height: 1.45; margin: 0; }
    </style>
  </head>
  <body>
    <main>
      <h1>Mirabé · Evento corporativo</h1>
      <p>Borrador para revisión. Propuesta: carrusel de 3 slides, no publicar hasta aprobación.</p>
      <p><a href="../../../docs/social/mirabe-2026-05-19-publishing-pack.md">Ver pack de publicación</a></p>
      <section class="grid">
        <img src="mirabe-corporate-01-room.png" alt="">
        <img src="mirabe-corporate-02-speaker.png" alt="">
        <img src="mirabe-corporate-03-room-wide.png" alt="">
      </section>
      <section class="copy">
        <pre>Ayer estuvimos en Mirabé dando soporte técnico a un evento corporativo: pantalla, sonido, microfonía y seguimiento de la presentación.

Un trabajo discreto, pero importante: que se escuche bien, que se vea claro y que el evento avance con naturalidad.

Con @homsdani al frente del montaje y la coordinación técnica.

Eventos corporativos, presentaciones y celebraciones privadas en Barcelona, Girona y Costa Brava.

#EventoCorporativo #MirabeBarcelona #SonidoEventos #EventosBarcelona #CostaBravaMusicEvents #CorporateEvents #DaniHoms</pre>
      </section>
    </main>
  </body>
</html>
"""
    (OUT / "review.html").write_text(html, encoding="utf-8")


def write_doc():
    DOC.parent.mkdir(parents=True, exist_ok=True)
    DOC.write_text(
        """# Mirabé - Evento corporativo

Estado: borrador para revisión. No publicar hasta aprobación.

Fecha del evento: 19/05/2026.

Formato recomendado: carrusel Instagram de 3 slides.

Motivo: solo hay fotos verticales, sin vídeo. Un carrusel queda más natural que un reel montado con fotos.

## Assets

- Slide 1: `assets/social/mirabe-2026-05-19/mirabe-corporate-01-room.png`
- Slide 2: `assets/social/mirabe-2026-05-19/mirabe-corporate-02-speaker.png`
- Slide 3: `assets/social/mirabe-2026-05-19/mirabe-corporate-03-room-wide.png`
- Review: `assets/social/mirabe-2026-05-19/review.html`

## Tratamiento aplicado

- Recorte 4:5 para feed.
- Corrección ligera de contraste, color y nitidez.
- Texto sensible de pantalla suavizado.
- Sin nombres de cliente ni datos internos.
- Sin textos ni logos sobre las imágenes.

## Caption

> Ayer estuvimos en Mirabé dando soporte técnico a un evento corporativo: pantalla, sonido, microfonía y seguimiento de la presentación.
>
> Un trabajo discreto, pero importante: que se escuche bien, que se vea claro y que el evento avance con naturalidad.
>
> Con @homsdani al frente del montaje y la coordinación técnica.
>
> Eventos corporativos, presentaciones y celebraciones privadas en Barcelona, Girona y Costa Brava.

Hashtags:

`#EventoCorporativo #MirabeBarcelona #SonidoEventos #EventosBarcelona #CostaBravaMusicEvents #CorporateEvents #DaniHoms`

## Publicación

- Etiquetar/mencionar a `@homsdani`.
- Ubicación sugerida: Mirabé Barcelona.
- No etiquetar clientes ni asistentes.
""",
        encoding="utf-8",
    )


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    for key, src in INPUTS.items():
        shutil.copy2(src, SOURCE / f"{key}.jpeg")

    save_slide("room", "mirabe-corporate-01-room.png", 0.56, blur_areas=((130, 300, 700, 610),))
    save_slide("speaker", "mirabe-corporate-02-speaker.png", 0.54)
    save_slide("technical", "mirabe-corporate-03-room-wide.png", 0.50, blur_areas=((360, 470, 704, 586),))
    write_review()
    write_doc()


if __name__ == "__main__":
    main()
