import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


PROJECT_ROOT = Path(r"C:\Users\10385\Projects\drug_expiry_app")
ANDROID_RES = PROJECT_ROOT / "android" / "app" / "src" / "main" / "res"
ASSET_ICON = PROJECT_ROOT / "assets" / "icon"
IOS_ICONSET = PROJECT_ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
WEB_SPLASH = PROJECT_ROOT / "web" / "splash" / "img"

CYAN = (6, 182, 212, 255)
BLUE = (37, 99, 235, 255)
NAVY = (15, 23, 42, 255)
FACE = (248, 250, 252, 255)
FACE_EDGE = (219, 234, 254, 255)
GREEN = (16, 185, 129, 255)
WHITE = (255, 255, 255, 255)

ANDROID_FOREGROUND_SIZES = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}
ANDROID_ICON_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def lerp(first, second, amount):
    return tuple(int(first[index] * (1 - amount) + second[index] * amount) for index in range(4))


def gradient_background(size):
    image = Image.new("RGBA", (size, size))
    pixels = image.load()
    for y in range(size):
        for x in range(size):
            diagonal = (x + y) / (2 * max(size - 1, 1))
            radial = math.hypot(x - size * 0.28, y - size * 0.18) / (size * 1.1)
            amount = max(0.0, min(1.0, diagonal * 0.55 + radial * 0.45))
            pixels[x, y] = lerp(CYAN, BLUE, amount)
    return image


def draw_check(draw, center, radius, color):
    x, y = center
    width = max(2, int(radius * 0.18))
    draw.line(
        [(x - radius * 0.45, y), (x - radius * 0.08, y + radius * 0.34), (x + radius * 0.52, y - radius * 0.36)],
        fill=color,
        width=width,
        joint="curve",
    )


def draw_clock(image, scale=1.0, include_badge=True):
    size = image.width
    draw_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(draw_layer)
    center = size / 2
    radius = size * 0.32 * scale
    face_center = (center, center - size * 0.01)

    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_radius = radius * 1.06
    shadow_draw.ellipse(
        [
            face_center[0] - shadow_radius,
            face_center[1] - shadow_radius + size * 0.025,
            face_center[0] + shadow_radius,
            face_center[1] + shadow_radius + size * 0.025,
        ],
        fill=(2, 6, 23, 95),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(1, int(size * 0.025))))
    image.alpha_composite(shadow)

    draw.ellipse(
        [
            face_center[0] - radius,
            face_center[1] - radius,
            face_center[0] + radius,
            face_center[1] + radius,
        ],
        fill=FACE,
        outline=FACE_EDGE,
        width=max(2, int(size * 0.018)),
    )

    for index in range(12):
        angle = math.radians(index * 30 - 90)
        outer = radius * 0.84
        inner = radius * (0.71 if index % 3 == 0 else 0.77)
        tick_width = max(2, int(size * (0.017 if index % 3 == 0 else 0.011)))
        start = (face_center[0] + math.cos(angle) * inner, face_center[1] + math.sin(angle) * inner)
        end = (face_center[0] + math.cos(angle) * outer, face_center[1] + math.sin(angle) * outer)
        draw.line([start, end], fill=NAVY, width=tick_width)

    def hand(angle_degrees, length, width):
        angle = math.radians(angle_degrees - 90)
        end = (face_center[0] + math.cos(angle) * radius * length, face_center[1] + math.sin(angle) * radius * length)
        draw.line([face_center, end], fill=NAVY, width=max(2, int(size * width)))

    hand(300, 0.48, 0.026)
    hand(60, 0.68, 0.018)
    center_radius = max(3, int(size * 0.035))
    draw.ellipse(
        [
            face_center[0] - center_radius,
            face_center[1] - center_radius,
            face_center[0] + center_radius,
            face_center[1] + center_radius,
        ],
        fill=NAVY,
    )
    image.alpha_composite(draw_layer)

    if include_badge:
        badge = Image.new("RGBA", image.size, (0, 0, 0, 0))
        badge_draw = ImageDraw.Draw(badge)
        badge_radius = size * 0.115 * scale
        badge_center = (center + radius * 0.67, center + radius * 0.67)
        badge_draw.ellipse(
            [
                badge_center[0] - badge_radius * 1.1,
                badge_center[1] - badge_radius * 1.1,
                badge_center[0] + badge_radius * 1.1,
                badge_center[1] + badge_radius * 1.1,
            ],
            fill=WHITE,
        )
        badge_draw.ellipse(
            [
                badge_center[0] - badge_radius,
                badge_center[1] - badge_radius,
                badge_center[0] + badge_radius,
                badge_center[1] + badge_radius,
            ],
            fill=GREEN,
        )
        draw_check(badge_draw, badge_center, badge_radius, WHITE)
        image.alpha_composite(badge)


def make_foreground(size):
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_clock(image, scale=1.15, include_badge=True)
    return image


def make_full_icon(size):
    image = gradient_background(size)
    draw_clock(image, scale=1.0, include_badge=True)
    return image


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(PROJECT_ROOT), image.size)


def generate_android():
    for density, size in ANDROID_FOREGROUND_SIZES.items():
        save(make_foreground(size), ANDROID_RES / f"drawable-{density}" / "ic_launcher_foreground.png")
    for density, size in ANDROID_ICON_SIZES.items():
        save(make_full_icon(size), ANDROID_RES / f"mipmap-{density}" / "ic_launcher.png")
        save(make_full_icon(size), ANDROID_RES / f"drawable-{density}" / "splash.png")
    save(make_full_icon(1024), ASSET_ICON / "app_icon.png")
    save(make_foreground(1024), ASSET_ICON / "app_icon_foreground.png")
    save(make_full_icon(1024), ANDROID_RES / "drawable" / "splash.png")


def generate_ios():
    contents_path = IOS_ICONSET / "Contents.json"
    if not contents_path.exists():
        return
    contents = json.loads(contents_path.read_text(encoding="utf-8"))
    for image_info in contents.get("images", []):
        filename = image_info.get("filename")
        size_text = image_info.get("size")
        scale_text = image_info.get("scale", "1x")
        if not filename or not size_text:
            continue
        width = int(float(size_text.split("x")[0]) * int(scale_text[0]))
        save(make_full_icon(width), IOS_ICONSET / filename)


def generate_web():
    for path in WEB_SPLASH.glob("*.png"):
        with Image.open(path) as existing:
            size = existing.size
        save(make_full_icon(max(size)), path)


def main():
    generate_android()
    generate_ios()
    generate_web()
    print("done")


if __name__ == "__main__":
    main()
