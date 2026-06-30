from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "print"
LOGO_PATH = ROOT / "assets" / "img" / "LOGO TRANSPARENTE.png"
PARTNER_IMAGE_PATHS = [
    ROOT / "assets" / "img" / "danihoms.jpg",
    ROOT / "assets" / "img" / "litus.jpeg",
    ROOT / "assets" / "img" / "dj-controller-2026-04-17.jpeg",
    ROOT / "assets" / "img" / "inma-ortiz.jpeg",
    ROOT / "assets" / "img" / "onedaydj.jpg",
    ROOT / "assets" / "img" / "RumbaCatalana.jpeg",
    ROOT / "assets" / "img" / "bailaoras.jpeg",
    ROOT / "assets" / "img" / "flamenco.jpg",
]

WIDTH = 3508
HEIGHT = 2480
PANEL_W = WIDTH // 3

WHITE = (250, 248, 244)
INK = (33, 33, 33)
MUTED = (78, 78, 78)
CORAL = (237, 118, 91)
ORANGE = (240, 152, 74)
TURQUOISE = (98, 207, 214)
PALE_TURQUOISE = (184, 236, 238)
LINE = (226, 205, 192)

FONT_SANS = "/System/Library/Fonts/Avenir Next.ttc"
FONT_SCRIPT = "/System/Library/Fonts/Supplemental/Helvetica.ttc"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Helvetica Bold.ttf"
FONT_SCALE = 1.50
FONT_SCRIPT_SCALE = 0.90


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        scale = FONT_SCALE * (FONT_SCRIPT_SCALE if path == FONT_SCRIPT else 1.0)
        return ImageFont.truetype(path, size=max(1, int(size * scale)))
    except OSError:
        return ImageFont.load_default()


def bold_font(size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(FONT_BOLD, size=max(1, int(size * FONT_SCALE)))
    except OSError:
        return font(FONT_SANS, size)


def text_box(draw, xy, text, fill, ft, max_width, spacing=8):
    x, y = xy
    words = text.split()
    lines = []
    current = ""
    for word in words:
        test = word if not current else f"{current} {word}"
        if draw.textlength(test, font=ft) <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    joined = "\n".join(lines)
    draw.multiline_text((x, y), joined, fill=fill, font=ft, spacing=spacing)
    bbox = draw.multiline_textbbox((x, y), joined, font=ft, spacing=spacing)
    return bbox[3]


def justified_text_box(draw, xy, text, fill, ft, max_width, spacing=8, paragraph_gap=None):
    x, y = xy
    paragraphs = text.split("\n\n")
    bbox = draw.textbbox((0, 0), "Ag", font=ft)
    line_h = bbox[3] - bbox[1]
    paragraph_gap = spacing * 2 if paragraph_gap is None else paragraph_gap
    current_y = y

    for p_index, paragraph in enumerate(paragraphs):
        words = paragraph.split()
        lines = []
        current = []
        for word in words:
            test = " ".join(current + [word])
            if draw.textlength(test, font=ft) <= max_width:
                current.append(word)
            else:
                if current:
                    lines.append(current)
                current = [word]
        if current:
            lines.append(current)

        for i, line_words in enumerate(lines):
            line_text = " ".join(line_words)
            if i == len(lines) - 1 or len(line_words) == 1:
                draw.text((x, current_y), line_text, fill=fill, font=ft)
            else:
                words_width = sum(draw.textlength(word, font=ft) for word in line_words)
                gap = (max_width - words_width) / (len(line_words) - 1)
                current_x = x
                for j, word in enumerate(line_words):
                    draw.text((current_x, current_y), word, fill=fill, font=ft)
                    current_x += draw.textlength(word, font=ft)
                    if j < len(line_words) - 1:
                        current_x += gap
            current_y += line_h + spacing

        if p_index < len(paragraphs) - 1:
            current_y += paragraph_gap

    return current_y


def draw_divider(draw, x, y, width, color=CORAL):
    draw.line((x, y, x + width, y), fill=color, width=4)


def paste_logo(base, center_x, top_y, target_w):
    logo = Image.open(LOGO_PATH).convert("RGBA")
    ratio = target_w / logo.width
    target_h = int(logo.height * ratio)
    logo = logo.resize((int(target_w), target_h), Image.LANCZOS)
    left = int(center_x - logo.width / 2)
    base.paste(logo, (left, top_y), logo)
    return top_y + logo.height


def fill_cover_rect(image, target_w, target_h):
    scale = max(target_w / image.width, target_h / image.height)
    resized = image.resize((max(1, int(image.width * scale)), max(1, int(image.height * scale))), Image.LANCZOS)
    left = max(0, (resized.width - target_w) // 2)
    top = max(0, (resized.height - target_h) // 2)
    return resized.crop((left, top, left + target_w, top + target_h))


def paste_partner_collage(base, panel_left, panel_right, start_y, end_y):
    visible_paths = [path for path in PARTNER_IMAGE_PATHS if path.exists()][:8]
    if not visible_paths:
        return

    cols = 2
    rows = (len(visible_paths) + cols - 1) // cols
    inner_w = max(120, panel_right - panel_left)
    inner_h = max(120, end_y - start_y)

    overlap_x = 0.82
    overlap_y = 0.68
    max_d_by_w = inner_w / (1.0 + overlap_x)
    max_d_by_h = inner_h / (1.0 + (rows - 1) * overlap_y)
    diameter = int(max(132, min(max_d_by_w, max_d_by_h) * 1.18))

    step_x = int(diameter * overlap_x)
    step_y = int(diameter * overlap_y)
    layout_w = diameter + step_x
    layout_h = diameter + (rows - 1) * step_y
    origin_x = int(panel_left + (inner_w - layout_w) / 2)
    origin_y = int(start_y + (inner_h - layout_h) / 2)

    first_col = [visible_paths[i] for i in range(0, len(visible_paths), 2)]
    second_col = [visible_paths[i] for i in range(1, len(visible_paths), 2)][::-1]

    ordered_paths = []
    for row in range(rows):
        ordered_paths.append(first_col[row] if row < len(first_col) else None)
        ordered_paths.append(second_col[row] if row < len(second_col) else None)

    draw = ImageDraw.Draw(base)
    for idx, img_path in enumerate(ordered_paths):
        if img_path is None:
            continue
        row = idx // cols
        col = idx % cols
        x = origin_x + col * step_x
        y = origin_y + row * step_y

        with Image.open(img_path).convert("RGB") as src:
            tile = fill_cover_rect(src, diameter, diameter).convert("RGBA")

        mask = Image.new("L", (diameter, diameter), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.ellipse((0, 0, diameter - 1, diameter - 1), fill=255)
        base.paste(tile, (x, y), mask)
        draw.ellipse((x, y, x + diameter - 1, y + diameter - 1), outline=WHITE, width=7)


def draw_wave_band(draw, top_y):
    import math

    def ribbon(x0, x1, base_y, amp1, amp2, phase1, phase2, color, bands=5, gap=12, thickness=11, step=18, highlight=None):
        for band in range(bands):
            top_pts = []
            bottom_pts = []
            x = x0
            offset = band * gap
            while x <= x1:
                t = (x - x0) / max(1, (x1 - x0))
                curve = top_y + base_y + amp1 * math.sin((t * 1.9 + phase1) * math.pi) + amp2 * math.sin((t * 3.6 + phase2) * math.pi) + 10 * math.exp(-((t - 0.60) / 0.22) ** 2)
                top_pts.append((x, curve + offset))
                bottom_pts.append((x, curve + offset + thickness))
                x += step
            poly = top_pts + list(reversed(bottom_pts))
            draw.polygon(poly, fill=color)
            if highlight is not None and band == 0:
                draw.line(top_pts, fill=highlight, width=2)

    ribbon(0, 1600, 176, 27, 8, 0.08, 0.34, (242, 167, 86), bands=5, gap=14, thickness=18, highlight=(251, 214, 163))
    ribbon(220, 2340, 202, 31, 10, 0.27, 0.10, (238, 118, 92), bands=5, gap=14, thickness=18, highlight=(250, 184, 165))
    ribbon(1020, 3140, 188, 29, 8, 0.01, 0.24, (93, 199, 208), bands=5, gap=14, thickness=18, highlight=(176, 233, 236))
    ribbon(1540, 3508, 220, 32, 10, 0.18, 0.60, (176, 231, 234), bands=5, gap=14, thickness=18, highlight=(223, 246, 247))


def draw_separators(draw):
    for i in range(1, 3):
        x = i * PANEL_W
        draw.line((x, 120, x, HEIGHT - 120), fill=LINE, width=3)


def draw_service_icon(draw, x, y, label):
    size = 82
    cx = x + size / 2
    cy = y + size / 2
    draw.ellipse((x, y, x + size, y + size), fill=CORAL)
    fg = WHITE
    if label == "DJ":
        draw.arc((x + 16, y + 16, x + 66, y + 50), start=200, end=340, fill=fg, width=3)
        draw.line((x + 22, y + 38, x + 22, y + 54), fill=fg, width=3)
        draw.line((x + 60, y + 38, x + 60, y + 54), fill=fg, width=3)
        draw.ellipse((x + 32, y + 31, x + 50, y + 49), outline=fg, width=3)
    elif label == "MIC":
        draw.rounded_rectangle((x + 31, y + 16, x + 51, y + 44), radius=7, outline=fg, width=3)
        draw.line((x + 41, y + 44, x + 41, y + 60), fill=fg, width=3)
        draw.arc((x + 24, y + 24, x + 58, y + 58), start=20, end=160, fill=fg, width=3)
        draw.line((x + 30, y + 63, x + 52, y + 63), fill=fg, width=3)
    elif label == "LX":
        draw.polygon([(cx, y + 16), (x + 24, y + 36), (x + 58, y + 36)], outline=fg, fill=None)
        draw.line((x + 24, y + 36, x + 58, y + 36), fill=fg, width=3)
        draw.line((x + 28, y + 44, x + 20, y + 58), fill=fg, width=3)
        draw.line((x + 54, y + 44, x + 62, y + 58), fill=fg, width=3)
        draw.line((x + 41, y + 38, x + 41, y + 60), fill=fg, width=2)
    elif label == "LINK":
        draw.arc((x + 18, y + 25, x + 45, y + 55), start=300, end=140, fill=fg, width=3)
        draw.arc((x + 37, y + 25, x + 64, y + 55), start=120, end=320, fill=fg, width=3)
        draw.line((x + 34, y + 45, x + 49, y + 35), fill=fg, width=3)
    elif label == "CORP":
        draw.rectangle((x + 22, y + 24, x + 58, y + 58), outline=fg, width=3)
        draw.line((x + 32, y + 24, x + 32, y + 58), fill=fg, width=2)
        draw.line((x + 48, y + 24, x + 48, y + 58), fill=fg, width=2)
        draw.line((x + 22, y + 39, x + 58, y + 39), fill=fg, width=2)
    elif label == "FX":
        draw.line((cx, y + 16, cx, y + 64), fill=fg, width=3)
        draw.line((x + 18, cy, x + 64, cy), fill=fg, width=3)
        draw.line((x + 24, y + 24, x + 58, y + 58), fill=fg, width=3)
        draw.line((x + 58, y + 24, x + 24, y + 58), fill=fg, width=3)
    else:
        draw.ellipse((x + 28, y + 28, x + 54, y + 54), outline=fg, width=3)


def draw_contact_row(draw, x, y, glyph, text):
    size = 76
    draw.rounded_rectangle((x, y, x + size, y + size), radius=12, fill=CORAL)
    fg = WHITE
    if glyph == "PHONE":
        draw.text((x + size / 2, y + size / 2), "T", fill=fg, font=font(FONT_SANS, 34), anchor="mm")
    elif glyph == "MAIL":
        draw.rectangle((x + 18, y + 22, x + 58, y + 48), outline=fg, width=4)
        draw.line((x + 18, y + 22, x + 38, y + 38), fill=fg, width=4)
        draw.line((x + 58, y + 22, x + 38, y + 38), fill=fg, width=4)
    elif glyph == "WEB":
        draw.ellipse((x + 18, y + 18, x + 58, y + 58), outline=fg, width=4)
        draw.line((x + 38, y + 18, x + 38, y + 58), fill=fg, width=3)
        draw.arc((x + 22, y + 18, x + 54, y + 58), start=90, end=270, fill=fg, width=3)
        draw.arc((x + 22, y + 18, x + 54, y + 58), start=270, end=90, fill=fg, width=3)
    elif glyph == "IG":
        draw.rounded_rectangle((x + 18, y + 18, x + 58, y + 58), radius=10, outline=fg, width=4)
        draw.ellipse((x + 28, y + 28, x + 48, y + 48), outline=fg, width=4)
        draw.ellipse((x + 45, y + 25, x + 50, y + 30), fill=fg)
    text_font = font(FONT_SANS, 36)
    text_bbox = draw.textbbox((0, 0), text, font=text_font)
    icon_center = y + size / 2
    text_y = icon_center - (text_bbox[3] - text_bbox[1]) / 2 - text_bbox[1]
    draw.text((x + 104, text_y), text, fill=INK, font=text_font)


def panel_bounds(index):
    left = index * PANEL_W
    right = WIDTH if index == 2 else (index + 1) * PANEL_W
    return left, right


def draw_outside():
    img = Image.new("RGB", (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    draw_separators(draw)
    draw_wave_band(draw, 2115)

    left, right = panel_bounds(0)
    x = left + 84
    heading_font = bold_font(52)
    sub_font = font(FONT_SANS, 36)
    draw.text((x, 140), "Música que transforma\nel ambiente de tu evento", fill=INK, font=heading_font, spacing=18)
    draw_divider(draw, x, 332, 430)
    block_w = PANEL_W - 180
    text_end_y = justified_text_box(draw, (x, 430), "Somos especialistas en crear atmósferas musicales a medida para bodas, fiestas privadas, fiestas mayores, vermuts, inauguraciones y eventos corporativos.\n\n\n\n\n\nCombinamos dirección artística, técnica y musical, para que cada momento suene como tú quieres.", MUTED, sub_font, block_w, spacing=20)
    paste_partner_collage(img, left + 84, right - 84, int(text_end_y + 148), 2170)

    left, right = panel_bounds(1)
    x = left + 80
    draw.text((x, 140), "¿Hablamos?", fill=INK, font=bold_font(50))
    draw_divider(draw, x, 246, 260)
    draw.text((x, 338), "Te orientamos según:", fill=MUTED, font=font(FONT_SANS, 40))
    bullets = ["espacio", "horario", "número de invitados", "estilo musical", "tipo de invitados"]
    y = 455
    for bullet in bullets:
        bullet_font = font(FONT_SANS, 30)
        bbox = draw.textbbox((0, 0), bullet, font=bullet_font)
        text_h = bbox[3] - bbox[1]
        text_y = y - bbox[1]
        cy = text_y + text_h / 2
        draw.ellipse((x, cy - 6, x + 12, cy + 6), fill=CORAL)
        draw.text((x + 28, text_y), bullet, fill=INK, font=bullet_font)
        y += 82
    y += 86
    draw_contact_row(draw, x, y, "PHONE", "687 962 905 · 619 840 206")
    y += 92
    draw_contact_row(draw, x, y, "MAIL", "info@costabravamusicevents.com")
    y += 92
    draw_contact_row(draw, x, y, "WEB", "costabravamusicevents.com")
    y += 92
    draw_contact_row(draw, x, y, "IG", "@costabrava_music_events")
    paste_logo(img, (left + right) // 2, 1710, 560)

    left, right = panel_bounds(2)
    cx = (left + right) // 2
    body_font = font(FONT_SANS, 36)
    tagline_font = bold_font(56)
    logo_bottom = paste_logo(img, cx, 8, 1260)
    cover_title = "Música, sonido y luz que\nhacen vibrar tu espacio"
    title_bbox = draw.multiline_textbbox((0, 0), cover_title, font=tagline_font, spacing=18)
    title_x = cx - (title_bbox[2] - title_bbox[0]) / 2
    draw.multiline_text((title_x, logo_bottom + 48), cover_title, fill=INK, font=tagline_font, spacing=18, align="center")
    y = logo_bottom + 48 + (title_bbox[3] - title_bbox[1])
    justified_text_box(draw, (left + 120, y + 110), "Creamos experiencias sonoras que conectan con tu público y transforman el ambiente.", MUTED, body_font, PANEL_W - 300, spacing=18)

    return img


def draw_inside():
    img = Image.new("RGB", (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    draw_separators(draw)
    draw_wave_band(draw, 2100)

    heading_font = bold_font(52)
    bullet_font = font(FONT_SANS, 29)
    small_font = font(FONT_SANS, 26)

    left, right = panel_bounds(0)
    x = left + 82
    draw.text((x, 140), "Ofrecemos", fill=INK, font=heading_font)
    draw_divider(draw, x, 270, 320)
    y = 360
    offers = [
        ("DJ", "DJ's profesionales y repertorio adaptado a cada público y momento."),
        ("MIC", "Música en directo de todos los estilos\nPop · Rock · Jazz · Soul · Flamenco · Rumba · Chill · Electrónica · Clásica · Mediterránea."),
        ("LX", "Sonido e iluminación premium para interiores y exteriores, con equipos profesionales."),
        ("LINK", "Coordinación integral con equipos, venues y proveedores para garantizar fluidez."),
    ]
    for icon, bullet in offers:
        draw_service_icon(draw, x, y + 4, icon)
        y = text_box(draw, (x + 96, y), bullet, INK, bullet_font, PANEL_W - 374, spacing=22) + 96
    text_box(draw, (x, y + 24), "Tú imaginas el ambiente, nosotros lo hacemos sonar.", TURQUOISE, font(FONT_SCRIPT, 48), PANEL_W - 280, spacing=10)

    left, right = panel_bounds(1)
    x = left + 82
    draw.text((x, 140), "Dirección musical y\nsolvencia técnica", fill=INK, font=heading_font, spacing=16)
    draw_divider(draw, x, 360, 430)
    points = [
        "Dirección musical personalizada según estilo, público y momento.",
        "Sonido y ejecución impecable con equipamiento profesional y criterio técnico.",
        "Experiencia en venues exigentes, espacios singulares y entornos y eventos premium.",
        "Coordinación con equipos y proveedores para que todo fluya sin imprevistos.",
    ]
    y = 450
    for idx, point in enumerate(points, start=1):
        draw.ellipse((x, y - 2, x + 68, y + 66), fill=ORANGE)
        num_font = font(FONT_SANS, 40)
        draw.text((x + 34, y + 32), str(idx), fill=WHITE, font=num_font, anchor="mm")
        y = text_box(draw, (x + 82, y), point, INK, bullet_font, PANEL_W - 318, spacing=16) + 52
    draw.text((x, y + 12), "Servicios", fill=INK, font=heading_font)
    draw_divider(draw, x, y + 108, 260, color=ORANGE)
    y += 150
    services = [
        ("DJ", "DJ sets para bodas, sunsets, vermuts y fiestas privadas."),
        ("MIC", "Música en directo: artistas y bandas de todos los estilos."),
        ("LX", "Sonorización e iluminación para espacios interiores y exteriores."),
        ("CORP", "Eventos corporativos, fiestas de empresa, inauguraciones y activaciones de marca."),
        ("FX", "Producción integral, decoración, ambientación y efectos especiales."),
    ]
    for icon, item in services:
        draw_service_icon(draw, x, y + 6, icon)
        y = text_box(draw, (x + 96, y), item, MUTED, small_font, PANEL_W - 344, spacing=16) + 36

    left, right = panel_bounds(2)
    x = left + 82
    draw.text((x, 140), "Espacios donde la música\nha sido protagonista", fill=INK, font=heading_font, spacing=16)
    draw_divider(draw, x, 360, 430)
    y = 450
    section_title_font = bold_font(36)
    tag_font = font(FONT_SANS, 28)

    def draw_tag_row(start_y, color, title, labels):
        draw.text((x, start_y), title, fill=color, font=section_title_font)
        cursor_x = x
        cursor_y = start_y + 80
        max_x = right - 90
        for label in labels:
            label_w = int(draw.textlength(label, font=tag_font) + 98)
            if cursor_x + label_w > max_x:
                cursor_x = x
                cursor_y += 78
            tag_h = 72
            draw.rounded_rectangle((cursor_x, cursor_y, cursor_x + label_w, cursor_y + tag_h), radius=26, outline=color, width=3, fill=(255, 252, 248))
            draw.text((cursor_x + label_w / 2, cursor_y + tag_h / 2), label, fill=INK, font=tag_font, anchor="mm")
            cursor_x += label_w + 22
        return cursor_y + 150

    y = draw_tag_row(y, ORANGE, "A · Gran formato y corporativo", ["FC Barcelona", "BCN en las Alturas", "Ajuntament de Palamós"])
    y += 120
    y = draw_tag_row(y, CORAL, "B · Celebración privada y venues", ["Cap Sa Sal", "Can Marc", "Bellport"])
    y += 120
    y = draw_tag_row(y, TURQUOISE, "C · Nightlife y acto público", ["Red Fish", "Sea Sea Club", "La Ruïna", "Lincoln", "Venteo Platja d'Aro"])

    text_box(draw, (x, y + 18), "Referencias que demuestran solvencia, criterio y versatilidad.", TURQUOISE, font(FONT_SCRIPT, 44), PANEL_W - 285, spacing=14)

    return img

def save_outputs(name, image):
    png_path = OUT_DIR / f"{name}.png"
    pdf_path = OUT_DIR / f"{name}.pdf"
    image.save(png_path, quality=95)
    image.save(pdf_path, "PDF", resolution=300.0)
    return png_path, pdf_path


def save_preview(outside, inside):
    preview = Image.new("RGB", (WIDTH, HEIGHT * 2 + 120), (245, 242, 238))
    preview.paste(outside, (0, 0))
    preview.paste(inside, (0, HEIGHT + 120))
    preview_path = OUT_DIR / "cbme-trifold-spanish-preview.png"
    preview.save(preview_path, quality=95)
    return preview_path


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    outside = draw_outside()
    inside = draw_inside()
    save_outputs("cbme-trifold-spanish-outside", outside)
    save_outputs("cbme-trifold-spanish-inside", inside)
    save_preview(outside, inside)


if __name__ == "__main__":
    main()
