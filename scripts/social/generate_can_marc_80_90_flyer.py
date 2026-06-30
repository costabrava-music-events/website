from pathlib import Path
import math
import random

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "social" / "can-marc-80-90-2026-07-17"
SOURCE = OUT / "source"
CBME_LOGO = ROOT / "assets" / "brand" / "cbme" / "logo-hero-white-text.png"
CAN_MARC_LOGO = ROOT / "assets" / "brand" / "partners" / "can-marc" / "logo-el-jardi-can-marc.png"
GENERATED_BG = SOURCE / "imagegen-boombox-background.png"

FONT_BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"


def font(path, size):
    try:
        return ImageFont.truetype(path, size=size)
    except OSError:
        return ImageFont.load_default(size=size)


def fit_logo(path, size, white=False):
    logo = Image.open(path).convert("RGBA")
    if white:
        px = logo.load()
        for y in range(logo.height):
            for x in range(logo.width):
                r, g, b, a = px[x, y]
                alpha = max(a, min(255, max(r, g, b) * 8))
                if max(r, g, b) < 8:
                    alpha = 0
                px[x, y] = (255, 246, 220, alpha)
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
    logo.thumbnail(size, Image.LANCZOS)
    return logo


def paste_logo(canvas, logo, xy):
    shadow = logo.filter(ImageFilter.GaussianBlur(10))
    canvas.alpha_composite(ImageEnhance.Brightness(shadow).enhance(0), (xy[0] + 4, xy[1] + 6))
    canvas.alpha_composite(logo, xy)


def cover(path, size, focal_y=0.5):
    img = Image.open(path).convert("RGB")
    ratio = max(size[0] / img.width, size[1] / img.height)
    resized = img.resize((int(img.width * ratio), int(img.height * ratio)), Image.LANCZOS)
    x = (resized.width - size[0]) // 2
    y = int((resized.height - size[1]) * focal_y)
    y = max(0, min(y, resized.height - size[1]))
    return resized.crop((x, y, x + size[0], y + size[1])).convert("RGBA")


def glow_line(draw, points, color, width):
    for blur_width, alpha in ((width * 5, 35), (width * 2, 70), (width, color[3])):
        draw.line(points, fill=(color[0], color[1], color[2], alpha), width=blur_width, joint="curve")


def add_grid(canvas):
    w, h = canvas.size
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    horizon = int(h * 0.68)
    for i in range(12):
        x = int(w * i / 11)
        glow_line(draw, (w // 2, horizon, x, h), (0, 226, 255, 85), 2)
    for i in range(12):
        y = horizon + int((h - horizon) * (i / 11) ** 1.75)
        glow_line(draw, (0, y, w, y), (255, 58, 204, 95), 2)
    return Image.alpha_composite(canvas, layer.filter(ImageFilter.GaussianBlur(0.2)))


def add_vinyl(draw, cx, cy, radius, color):
    for r in range(radius, 18, -18):
        alpha = int(18 + 100 * r / radius)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(color[0], color[1], color[2], alpha), width=3)
    draw.ellipse((cx - 26, cy - 26, cx + 26, cy + 26), fill=(255, 210, 87, 180))
    draw.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=(8, 8, 16, 255))


def add_cassette(draw, x, y, scale):
    w = int(300 * scale)
    h = int(175 * scale)
    draw.rounded_rectangle((x, y, x + w, y + h), radius=int(18 * scale), outline=(255, 246, 220, 120), width=max(2, int(3 * scale)), fill=(8, 8, 18, 120))
    draw.rectangle((x + int(34 * scale), y + int(42 * scale), x + w - int(34 * scale), y + int(92 * scale)), outline=(0, 226, 255, 100), width=max(2, int(2 * scale)))
    for cx in (x + int(95 * scale), x + int(205 * scale)):
        draw.ellipse((cx - int(28 * scale), y + int(105 * scale), cx + int(28 * scale), y + int(161 * scale)), outline=(255, 58, 204, 150), width=max(2, int(3 * scale)))


def add_boombox(draw, w, h):
    scale = w / 1080
    bw = int(760 * scale)
    bh = int(270 * scale)
    x = (w - bw) // 2
    y = int(h * 0.69)
    draw.rounded_rectangle((x, y, x + bw, y + bh), radius=int(28 * scale), fill=(8, 9, 22, 175), outline=(255, 246, 220, 115), width=max(2, int(4 * scale)))
    draw.rectangle((x + int(250 * scale), y + int(55 * scale), x + bw - int(250 * scale), y + int(135 * scale)), outline=(0, 226, 255, 145), width=max(2, int(3 * scale)))
    draw.line((x + int(290 * scale), y + int(88 * scale), x + bw - int(290 * scale), y + int(88 * scale)), fill=(255, 58, 204, 145), width=max(2, int(3 * scale)))
    for sx in (x + int(145 * scale), x + bw - int(145 * scale)):
        for r, color in ((92, (0, 226, 255, 135)), (67, (255, 58, 204, 150)), (38, (255, 218, 132, 140))):
            rr = int(r * scale)
            draw.ellipse((sx - rr, y + int(138 * scale) - rr, sx + rr, y + int(138 * scale) + rr), outline=color, width=max(2, int(4 * scale)))
        draw.ellipse((sx - int(12 * scale), y + int(126 * scale), sx + int(12 * scale), y + int(150 * scale)), fill=(5, 6, 18, 230))
    for i in range(8):
        bx = x + int((300 + i * 24) * scale)
        bar_h = int((22 + (i % 4) * 15) * scale)
        draw.rectangle((bx, y + int(178 * scale) - bar_h, bx + int(10 * scale), y + int(178 * scale)), fill=(255, 218, 132, 135))


def make_background(size):
    focal_y = 0.5 if size[1] > size[0] else 0.68
    canvas = cover(GENERATED_BG, size, focal_y=focal_y)
    w, h = size
    shade = Image.new("RGBA", size, (0, 0, 0, 0))
    shade_draw = ImageDraw.Draw(shade)
    for y in range(h):
        center = max(0, 1 - abs(y - h * 0.42) / (h * 0.34))
        shade_draw.line((0, y, w, y), fill=(0, 0, 0, int(18 + center * 55)))
    return Image.alpha_composite(canvas, shade)


def center_text(draw, y, text, text_font, fill, stroke=(0, 0, 0), stroke_width=0):
    bbox = draw.textbbox((0, 0), text, font=text_font, stroke_width=stroke_width)
    x = (draw.im.size[0] - (bbox[2] - bbox[0])) // 2
    draw.text((x, y), text, font=text_font, fill=fill, stroke_fill=stroke, stroke_width=stroke_width)
    return y + bbox[3] - bbox[1]


def draw_flyer(size, output, layout):
    canvas = make_background(size)
    draw = ImageDraw.Draw(canvas)
    w, h = size
    scale = w / 1080

    cbme_h = int((155 if layout == "story" else 105) * scale)
    can_marc_h = int((330 if layout == "story" else 245) * scale)
    cbme = fit_logo(CBME_LOGO, (cbme_h, cbme_h))
    can_marc = fit_logo(CAN_MARC_LOGO, (int(can_marc_h * 1.65), can_marc_h), white=True)
    paste_logo(canvas, can_marc, ((w - can_marc.width) // 2, int(28 * scale)))

    if layout == "story":
        panel = (int(135 * scale), int(320 * scale), w - int(135 * scale), int(1000 * scale))
        y = int(450 * scale)
        title_size = int(116 * scale)
        years_size = int(164 * scale)
        gap = int(36 * scale)
        name_size = int(54 * scale)
        time_size = int(42 * scale)
        place_size = int(34 * scale)
        pill_y = int(1055 * scale)
    else:
        panel = (int(145 * scale), int(195 * scale), w - int(145 * scale), int(750 * scale))
        y = int(285 * scale)
        title_size = int(78 * scale)
        years_size = int(116 * scale)
        gap = int(22 * scale)
        name_size = int(48 * scale)
        time_size = int(38 * scale)
        place_size = int(26 * scale)
        pill_y = h - int(245 * scale)

    y = center_text(draw, y, "DJ DANI HOMS", font(FONT_BOLD, name_size), (255, 218, 132), stroke_width=int(2 * scale))
    y += gap
    y = center_text(draw, y, "FESTA", font(FONT_BLACK, title_size), (255, 255, 255), stroke_width=int(5 * scale))
    y += int(18 * scale)
    y = center_text(draw, y, "80s/90s", font(FONT_BLACK, years_size), (0, 232, 255), stroke=(255, 58, 204), stroke_width=int(5 * scale))
    y += int(52 * scale)
    y = center_text(draw, y, "DISSABTE 18/07/2026", font(FONT_BLACK, int(46 * scale)), (255, 218, 132), stroke_width=int(3 * scale))
    y += int(20 * scale)
    y = center_text(draw, y, "A PARTIR DE LES 22:00", font(FONT_BOLD, time_size), (255, 255, 255), stroke_width=int(2 * scale))
    y += int(24 * scale)
    center_text(draw, y, "LLOC: EL JARDÍ DE CAN MARC A BEGUR", font(FONT_BOLD, place_size), (255, 246, 220), stroke_width=int(1 * scale))

    pill_w = int(770 * scale)
    pill_h = int(86 * scale)
    px = (w - pill_w) // 2
    draw.rounded_rectangle((px, pill_y, px + pill_w, pill_y + pill_h), radius=int(12 * scale), fill=(255, 58, 204), outline=(255, 218, 132), width=int(3 * scale))
    center_text(draw, pill_y + int(22 * scale), "ENTRADA 20 EUR · A PARTIR DE 40 ANYS", font(FONT_BLACK, int(30 * scale)), (8, 8, 18))

    footer_font = font(FONT_BOLD, int(28 * scale))
    footer_y = h - int(58 * scale)
    left = "Costa Brava Music Events"
    left_bbox = draw.textbbox((0, 0), left, font=footer_font)
    left_x = int(64 * scale)
    cbme_y = h - int((190 if layout == "story" else 150) * scale)
    paste_logo(canvas, cbme, (left_x + (left_bbox[2] - cbme.width) // 2, cbme_y))
    draw.text((left_x, footer_y), left, font=footer_font, fill=(240, 244, 250))
    right = "El Jardí de Can Marc - Begur"
    bbox = draw.textbbox((0, 0), right, font=footer_font)
    right_x = w - int(64 * scale) - bbox[2]
    small_can_marc = fit_logo(CAN_MARC_LOGO, (int(cbme_h * 1.05), cbme_h), white=True)
    paste_logo(canvas, small_can_marc, (right_x + (bbox[2] - small_can_marc.width) // 2, cbme_y))
    draw.text((right_x, footer_y), right, font=footer_font, fill=(240, 244, 250))

    canvas.convert("RGB").save(output, quality=96)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    SOURCE.mkdir(parents=True, exist_ok=True)
    make_background((1080, 1920)).convert("RGB").save(SOURCE / "retro-80s-90s-new-background.png", quality=96)
    draw_flyer((1080, 1920), OUT / "dj-dani-homs-can-marc-80s-90s-story.png", "story")
    draw_flyer((1080, 1080), OUT / "dj-dani-homs-can-marc-80s-90s-post.png", "post")


if __name__ == "__main__":
    main()
