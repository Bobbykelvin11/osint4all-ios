#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw

SIZE = 1024
OUT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "OSINT4ALL",
    "Assets.xcassets",
    "AppIcon.appiconset",
    "AppIcon-1024.png",
)

os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)

SCALE = 2
W = SIZE * SCALE
H = SIZE * SCALE

img = Image.new("RGB", (W, H), (14, 21, 36))
draw = ImageDraw.Draw(img)

# Subtle radial gradient
cx, cy = W // 2, H // 2
for r in range(W, 0, -16):
    t = 1.0 - (r / W)
    col = (
        int(14 + 14 * t),
        int(21 + 32 * t),
        int(36 + 56 * t),
    )
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)

# 2x2 start.me-style bookmark dashboard tiles + magnifying/radar accent
pad = 360
gap = 96
tile_size = (W - 2 * pad - gap) // 2
radius = 110

tiles = [
    (pad, pad, (35, 149, 237), True),                     # Top-left: bright start.me blue
    (pad + tile_size + gap, pad, (30, 45, 72), False),    # Top-right: dark slate
    (pad, pad + tile_size + gap, (30, 45, 72), False),    # Bottom-left: dark slate
    (pad + tile_size + gap, pad + tile_size + gap, (255, 255, 255), True),  # Bottom-right: white
]

for x, y, fill_col, is_accent in tiles:
    draw.rounded_rectangle(
        [x, y, x + tile_size, y + tile_size],
        radius=radius,
        fill=fill_col,
        outline=(74, 170, 245) if not is_accent else None,
        width=16 if not is_accent else 0,
    )

# Inside Top-Left tile: 3 white bookmark list lines
tx, ty = pad + 115, pad + 140
for i in range(3):
    ly = ty + i * 115
    lw = 340 if i != 1 else 260
    draw.rounded_rectangle([tx, ly, tx + lw, ly + 44], radius=22, fill=(255, 255, 255))

# Inside Top-Right tile: radar/target glyph in cyan
rx = pad + tile_size + gap + tile_size // 2
ry = pad + tile_size // 2
draw.ellipse([rx - 150, ry - 150, rx + 150, ry + 150], outline=(35, 149, 237), width=28)
draw.ellipse([rx - 75, ry - 75, rx + 75, ry + 75], outline=(255, 255, 255), width=22)
draw.ellipse([rx - 22, ry - 22, rx + 22, ry + 22], fill=(35, 149, 237))

# Inside Bottom-Left tile: network nodes
bx = pad + tile_size // 2
by = pad + tile_size + gap + tile_size // 2
pts = [(bx - 120, by + 80), (bx, by - 100), (bx + 120, by + 80)]
draw.line([pts[0], pts[1], pts[2], pts[0]], fill=(100, 190, 255), width=20)
for px, py in pts:
    draw.ellipse([px - 38, py - 38, px + 38, py + 38], fill=(255, 255, 255))

# Inside Bottom-Right tile (white): bold blue magnifying glass
mx = pad + tile_size + gap + tile_size // 2 - 28
my = pad + tile_size + gap + tile_size // 2 - 28
draw.ellipse([mx - 120, my - 120, mx + 120, my + 120], outline=(18, 98, 178), width=42)
draw.line([(mx + 82, my + 82), (mx + 200, my + 200)], fill=(18, 98, 178), width=48)
draw.ellipse([mx + 176, my + 176, mx + 224, my + 224], fill=(18, 98, 178))

final = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
final.save(OUT_PATH, "PNG")
print(f"Generated icon at {OUT_PATH} ({SIZE}x{SIZE})")
