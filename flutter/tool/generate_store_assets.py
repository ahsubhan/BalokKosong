from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "store_listing"
GOOGLE = OUT / "google-play"
APPLE = OUT / "app-store"
VIDEO = OUT / "video"

PURPLE_DARK = (18, 0, 36)
PURPLE = (154, 67, 239)
PURPLE_LIGHT = (206, 143, 255)
CREAM = (255, 240, 207)
WHITE = (255, 255, 255)

FONT_REGULAR = Path(r"C:\Windows\Fonts\segoeui.ttf")
FONT_BOLD = Path(r"C:\Windows\Fonts\segoeuib.ttf")


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT_REGULAR), size)


def gradient(size: tuple[int, int], top=(16, 0, 32), bottom=(45, 8, 76)) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        for x in range(w):
            glow = max(0.0, 1.0 - (((x - w * 0.75) / (w * 0.75)) ** 2 + ((y - h * 0.28) / (h * 0.55)) ** 2))
            px[x, y] = tuple(
                min(255, int(top[i] * (1 - t) + bottom[i] * t + glow * (14, 5, 24)[i]))
                for i in range(3)
            )
    return img


def add_sparkles(img: Image.Image, scale: float = 1.0) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    points = [
        (0.10, 0.18, 5), (0.88, 0.16, 7), (0.82, 0.42, 4),
        (0.14, 0.62, 6), (0.91, 0.78, 5), (0.18, 0.88, 4),
    ]
    w, h = img.size
    for rx, ry, r in points:
        x, y, rr = int(w * rx), int(h * ry), int(r * scale)
        draw.line((x - rr * 2, y, x + rr * 2, y), fill=(218, 157, 255, 130), width=max(1, rr // 2))
        draw.line((x, y - rr * 2, x, y + rr * 2), fill=(255, 236, 201, 150), width=max(1, rr // 2))


def cover(source: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    sw, sh = source.size
    factor = max(tw / sw, th / sh)
    resized = source.resize((round(sw * factor), round(sh * factor)), Image.Resampling.LANCZOS)
    x = (resized.width - tw) // 2
    y = (resized.height - th) // 2
    return resized.crop((x, y, x + tw, y + th))


def contain(source: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    factor = min(tw / source.width, th / source.height)
    return source.resize((round(source.width * factor), round(source.height * factor)), Image.Resampling.LANCZOS)


def centered(draw: ImageDraw.ImageDraw, text: str, y: int, fnt, fill, canvas_width: int) -> int:
    box = draw.textbbox((0, 0), text, font=fnt)
    x = (canvas_width - (box[2] - box[0])) // 2
    draw.text((x, y), text, font=fnt, fill=fill)
    return box[3] - box[1]


def phone_frame(canvas: Image.Image, screenshot: Image.Image, box: tuple[int, int, int, int]) -> None:
    x, y, w, h = box
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x + 8, y + 24, x + w + 8, y + h + 24), radius=54, fill=(0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.paste(shadow, (0, 0), shadow)

    draw = ImageDraw.Draw(canvas, "RGBA")
    draw.rounded_rectangle((x - 8, y - 8, x + w + 8, y + h + 8), radius=58, fill=(188, 105, 255, 220))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w, h), radius=48, fill=255)
    shot = cover(screenshot.convert("RGB"), (w, h))
    canvas.paste(shot, (x, y), mask)


def make_marketing(size: tuple[int, int], source: Path, kicker: str, title: str, subtitle: str) -> Image.Image:
    w, h = size
    img = gradient(size)
    add_sparkles(img, w / 1080)
    draw = ImageDraw.Draw(img, "RGBA")

    top = int(h * 0.055)
    centered(draw, kicker.upper(), top, font(int(w * 0.038), True), PURPLE_LIGHT, w)
    title_y = top + int(h * 0.038)
    centered(draw, title, title_y, font(int(w * 0.078), True), CREAM, w)
    sub_y = title_y + int(h * 0.075)
    centered(draw, subtitle, sub_y, font(int(w * 0.034)), (230, 208, 240), w)

    shot = Image.open(source)
    phone_y = int(h * 0.255)
    phone_w = int(w * 0.78)
    phone_h = int(h * 0.82)
    phone_frame(img, shot, ((w - phone_w) // 2, phone_y, phone_w, phone_h))
    return img


def make_feature_graphic() -> Image.Image:
    size = (1024, 500)
    img = gradient(size, (19, 0, 35), (62, 13, 101))
    add_sparkles(img, 0.8)
    draw = ImageDraw.Draw(img, "RGBA")
    draw.text((76, 120), "BALOK", font=font(82, True), fill=CREAM)
    draw.text((72, 197), "KOSONG", font=font(88, True), fill=(181, 77, 255))
    draw.text((78, 312), "HABISKAN SEMUA BALOK", font=font(28, True), fill=(229, 197, 245))

    icon = Image.open(ROOT / "assets" / "icon" / "app_icon.png").convert("RGBA")
    icon = contain(icon, (330, 330))
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((640, 60, 970, 390), fill=(158, 63, 240, 90))
    glow = glow.filter(ImageFilter.GaussianBlur(48))
    img.paste(glow, (0, 0), glow)
    img.paste(icon, (660 + (300 - icon.width) // 2, 80 + (300 - icon.height) // 2), icon)
    return img


def main() -> None:
    for folder in (GOOGLE, APPLE, VIDEO):
        folder.mkdir(parents=True, exist_ok=True)

    concepts = [
        (
            ROOT / "emulator-game.png",
            "Puzzle geser balok",
            "Kosongkan papannya",
            "Tarik setiap balok mengikuti arahnya",
        ),
        (
            ROOT / "guest-result.png",
            "Pilih gaya bermain",
            "Santai atau Tantangan",
            "Main tanpa batas atau lawan hitungan waktu",
        ),
        (
            ROOT / "settings-web-port.png",
            "Makin seru",
            "10 level penuh variasi",
            "Bentuk baru, tema baru, tantangan baru",
        ),
    ]

    for index, (source, kicker, title, subtitle) in enumerate(concepts, start=1):
        google_img = make_marketing((1080, 1920), source, kicker, title, subtitle)
        google_img.save(GOOGLE / f"{index:02d}-preview-1080x1920.png", optimize=True)

        apple_img = make_marketing((1290, 2796), source, kicker, title, subtitle)
        apple_img.save(APPLE / f"{index:02d}-preview-1290x2796.png", optimize=True)

    feature = make_feature_graphic()
    feature.save(GOOGLE / "feature-graphic-1024x500.png", optimize=True)

    icon = Image.open(ROOT / "assets" / "icon" / "app_icon.png").convert("RGBA")
    icon = contain(icon, (512, 512))
    icon_canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    icon_canvas.paste(icon, ((512 - icon.width) // 2, (512 - icon.height) // 2), icon)
    icon_canvas.save(GOOGLE / "app-icon-512x512.png", optimize=True)

    print(f"Store assets created in: {OUT}")


if __name__ == "__main__":
    main()
