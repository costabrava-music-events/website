from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
IMG = ROOT / "assets" / "img"
OUT = ROOT / "assets" / "social" / "week-1"

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


def overlay(img):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    w, h = img.size
    for y in range(h):
        alpha = int(190 * (y / h))
        draw.line([(0, y), (w, y)], fill=(0, 0, 0, alpha))
    return Image.alpha_composite(img.convert("RGBA"), layer)


def wrap(draw, text, text_font, max_width):
    words = text.split()
    lines = []
    current = ""
    for word in words:
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


def draw_text_block(draw, xy, title, subtitle=None, max_width=860, title_size=82):
    x, y = xy
    title_font = font(title_size)
    sub_font = font(34, bold=False)
    for line in wrap(draw, title, title_font, max_width):
        draw.text((x, y), line, fill="white", font=title_font)
        y += title_size + 10
    if subtitle:
        y += 24
        for line in wrap(draw, subtitle, sub_font, max_width):
            draw.text((x, y), line, fill=(235, 238, 242), font=sub_font)
            y += 46


def add_brand(draw, size):
    draw.text((70, 70), "COSTA BRAVA", fill="white", font=font(30))
    draw.text((70, 108), "MUSIC EVENTS", fill=(245, 210, 145), font=font(30))
    draw.line((70, 155, 270, 155), fill=(245, 210, 145), width=4)


def save_reel_cover(filename, image, title, subtitle):
    size = (1080, 1920)
    canvas = overlay(cover(IMG / image, size))
    draw = ImageDraw.Draw(canvas)
    add_brand(draw, size)
    draw_text_block(draw, (70, 1340), title, subtitle, title_size=86)
    canvas.convert("RGB").save(OUT / filename, quality=95)


def save_story(filename, title, subtitle, image="hero-beach-1600.jpg"):
    size = (1080, 1920)
    canvas = overlay(cover(IMG / image, size).filter(ImageFilter.GaussianBlur(1.2)))
    draw = ImageDraw.Draw(canvas)
    add_brand(draw, size)
    draw.rounded_rectangle((80, 1320, 1000, 1680), radius=36, fill=(255, 255, 255, 235))
    draw.text((130, 1370), title, fill=(18, 24, 38), font=font(66))
    for i, line in enumerate(wrap(draw, subtitle, font(38, bold=False), 780)):
        draw.text((130, 1480 + i * 52), line, fill=(45, 55, 72), font=font(38, bold=False))
    canvas.convert("RGB").save(OUT / filename, quality=95)


def save_post(filename, image, title, subtitle):
    size = (1080, 1350)
    canvas = overlay(cover(IMG / image, size))
    draw = ImageDraw.Draw(canvas)
    add_brand(draw, size)
    draw_text_block(draw, (70, 900), title, subtitle, title_size=76)
    canvas.convert("RGB").save(OUT / filename, quality=95)


def save_carousel():
    size = (1080, 1350)
    slides = [
        ("La música de una boda no empieza en la fiesta", "Guía rápida para ordenar cada momento"),
        ("Ceremonia", "Emoción sin invadir. La música acompaña, no tapa."),
        ("Cóctel", "Ambiente elegante para conversar y abrir el evento."),
        ("Cena", "Ritmo suave, energía estable y volumen cuidado."),
        ("Fiesta", "Lectura de pista, mezcla real y cambios a tiempo."),
        ("Final", "El ultimo tema tambien forma parte del recuerdo."),
        ("Te ayudamos a diseñarlo", "Dinos fecha, espacio y estilo de boda."),
    ]
    photos = [
        "hero-beach-1600.jpg",
        "inma-ortiz.jpeg",
        "flamenco.jpg",
        "abstract-venue-card-1200.jpg",
        "albert_bit_dj.JPG",
        "onedaydj.jpg",
        "logo-white-text-black-bg.png",
    ]
    for index, (title, subtitle) in enumerate(slides, start=1):
        bg = cover(IMG / photos[index - 1], size)
        bg = ImageEnhance.Color(bg).enhance(0.85)
        canvas = overlay(bg)
        draw = ImageDraw.Draw(canvas)
        add_brand(draw, size)
        draw_text_block(draw, (70, 820), title, subtitle, title_size=66)
        draw.text((880, 1225), f"{index}/7", fill=(245, 210, 145), font=font(34))
        canvas.convert("RGB").save(OUT / f"carousel-03-musica-momentos-{index:02d}.png", quality=95)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    save_reel_cover(
        "reel-01-boda-costa-brava-cover.png",
        "hero-beach-1600.jpg",
        "Así suena una boda en Costa Brava",
        "DJ, música en vivo, sonido e iluminación a medida.",
    )
    save_story(
        "story-02-encuesta-dj-musica-vivo.png",
        "Tu evento",
        "¿Qué prefieres: DJ, música en vivo o combinar ambos?",
        "flamenco.jpg",
    )
    save_carousel()
    save_reel_cover(
        "reel-04-montaje-cover.png",
        "albert_bit_dj.JPG",
        "Lo que el invitado no ve",
        "Sonido probado, luces ajustadas y cabina lista.",
    )
    save_story(
        "story-05-preguntas-bodas.png",
        "Bodas",
        "Déjanos tu pregunta sobre música, sonido o iluminación.",
        "abstract-venue-card-1200.jpg",
    )
    save_post(
        "post-06-albert-bit.png",
        "albert_bit_dj.JPG",
        "Artista destacado",
        "Alb3rt Bit - DJ profesional para bodas y eventos privados.",
    )
    save_story(
        "story-07-repost-testimonio.png",
        "Momentos reales",
        "Esta semana compartimos eventos, pistas y propuestas en vivo.",
        "onedaydj.jpg",
    )


if __name__ == "__main__":
    main()
