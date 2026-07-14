from PIL import Image, ImageDraw
import os
import math

ROOT = r"C:\Users\10385\Projects\drug_expiry_app\android\app\src\main\res"
ORANGE_LIGHT = (251, 146, 60, 255)
ORANGE_DARK  = (234, 88, 12, 255)
WHITE        = (255, 255, 255, 255)
INK          = (124, 45, 18, 255)

FG_DPI = {"mdpi":108, "hdpi":162, "xhdpi":216, "xxhdpi":324, "xxxhdpi":432}
LAUNCHER_DPI = {"mdpi":48, "hdpi":72, "xhdpi":96, "xxhdpi":144, "xxxhdpi":192}

def gradient_bg(size, c1, c2):
    img = Image.new("RGBA", (size, size))
    px = img.load()
    cx = cy = size / 2
    maxd = math.hypot(cx, cy)
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / maxd
            d = min(1.0, max(0.0, d))
            r = int(c1[0] * (1 - d) + c2[0] * d)
            g = int(c1[1] * (1 - d) + c2[1] * d)
            b = int(c1[2] * (1 - d) + c2[2] * d)
            px[x, y] = (r, g, b, 255)
    return img

# adaptive foreground: transparent bg + center clock face
def make_foreground(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = cy = size / 2
    R  = size * 0.34
    draw.ellipse([cx - R, cy - R, cx + R, cy + R], fill=WHITE)
    stroke = max(1, int(size * 0.012))
    draw.ellipse([cx - R, cy - R, cx + R, cy + R], outline=INK, width=stroke)
    dot_r = size * 0.022
    for ang_deg in (0, 90, 180, 270):
        a = math.radians(ang_deg - 90)
        dx = cx + (R - R * 0.18) * math.cos(a)
        dy = cy + (R - R * 0.18) * math.sin(a)
        draw.ellipse([dx - dot_r, dy - dot_r, dx + dot_r, dy + dot_r], fill=INK)
    # hour hand -> 10 oclock
    hour_a = math.radians(300 - 90)
    hx1 = cx + (R * 0.42) * math.cos(hour_a)
    hy1 = cy + (R * 0.42) * math.sin(hour_a)
    h_w = max(2, int(size * 0.032))
    draw.line([(cx, cy), (hx1, hy1)], fill=INK, width=h_w)
    # minute hand -> 2 oclock
    min_a = math.radians(60 - 90)
    mx1 = cx + (R * 0.62) * math.cos(min_a)
    my1 = cy + (R * 0.62) * math.sin(min_a)
    m_w = max(1, int(size * 0.022))
    draw.line([(cx, cy), (mx1, my1)], fill=INK, width=m_w)
    cap_r = size * 0.034
    draw.ellipse([cx - cap_r, cy - cap_r, cx + cap_r, cy + cap_r], fill=INK)
    return img

# legacy / splash: orange gradient bg + center clock face
def make_full_icon(size):
    bg = gradient_bg(size, ORANGE_LIGHT, ORANGE_DARK)
    fg_size = int(size * 0.74)
    fg = make_foreground(fg_size)
    bg.paste(fg, ((size - fg_size) // 2, (size - fg_size) // 2), fg)
    return bg

def save(img, rel):
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p, "PNG")
    print("wrote", rel, img.size)

def main():
    for dpi, sz in FG_DPI.items():
        save(make_foreground(sz), f"drawable-{dpi}/ic_launcher_foreground.png")
    for dpi, sz in LAUNCHER_DPI.items():
        save(make_full_icon(sz), f"mipmap-{dpi}/ic_launcher.png")
    for dpi, sz in LAUNCHER_DPI.items():
        save(make_full_icon(sz), f"drawable-{dpi}/splash.png")
    print("done.")

if __name__ == "__main__":
    main()
