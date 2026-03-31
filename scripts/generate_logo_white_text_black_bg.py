from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
INPUT = ROOT / "assets" / "img" / "LOGO TRANSPARENTE.png"
OUTPUT = ROOT / "assets" / "img" / "logo-white-text-black-bg.png"


def main() -> None:
    image = Image.open(INPUT).convert("RGBA")
    pixels = image.load()
    width, height = image.size

    # Recolor only the lower text block, preserving the icon above.
    text_top = int(height * 0.60)

    for y in range(text_top, height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a < 70:
                continue

            luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b

            if a >= 120 and luminance < 95:
                pixels[x, y] = (255, 255, 255, a)

    background = Image.new("RGBA", image.size, (0, 0, 0, 255))
    background.alpha_composite(image)
    background.save(OUTPUT)
    print(f"saved {OUTPUT}")


if __name__ == "__main__":
    main()
