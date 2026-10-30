#!/usr/bin/env python3
"""Draws Xlin-soft's built-in wallpapers: soft blurred colour fields with a little grain.
Needs Pillow and numpy. Run: python3 scripts/make-wallpapers.py   -> assets/wallpapers/*.jpg"""
import os

import numpy as np
from PIL import Image, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "wallpapers")
W, H = 2560, 1440

# name: (base top, base bottom, [(x, y, radius, colour, strength)])  x,y,radius in 0..1 of the width/height
WALLS = {
    "dawn":     ("#fdf1e7", "#f3d9e8", [(.15, .85, .55, "#ffb88c", .85), (.85, .15, .50, "#c9b6ff", .75), (.55, .55, .35, "#ffd9e6", .6)]),
    "mist":     ("#eef3fb", "#dfe8f5", [(.20, .20, .50, "#bcd4ff", .8), (.85, .80, .55, "#d6c9ff", .7), (.60, .40, .30, "#ffffff", .8)]),
    "lagoon":   ("#e6f6f6", "#cfe9ee", [(.10, .75, .55, "#7fd8d0", .75), (.90, .20, .50, "#8fc3ff", .7), (.55, .90, .35, "#b6f0e0", .7)]),
    "blossom":  ("#fff0f3", "#ffe1ec", [(.80, .25, .55, "#ff9fc0", .75), (.15, .80, .50, "#ffc9a8", .7), (.50, .50, .30, "#ffffff", .7)]),
    "midnight": ("#0e1220", "#161b30", [(.15, .85, .55, "#2a3d8f", .85), (.85, .15, .50, "#4a2a8a", .7), (.60, .60, .30, "#1d6fa8", .45)]),
    "nebula":   ("#120e22", "#1d1233", [(.20, .25, .55, "#6a2fb0", .8), (.85, .75, .55, "#c0357d", .6), (.55, .50, .30, "#2a4cc0", .5)]),
    "ember":    ("#17100f", "#241513", [(.85, .85, .55, "#b8431f", .75), (.15, .20, .50, "#7a1f4a", .6), (.55, .60, .30, "#e08a2c", .35)]),
    "forest":   ("#0c1613", "#12211c", [(.15, .80, .55, "#1f7a5a", .75), (.85, .20, .50, "#1e4a7a", .6), (.55, .55, .30, "#4aa87a", .35)]),
}


def rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def draw(name, spec, seed):
    top, bot, blobs = spec
    y = np.linspace(0, 1, H, dtype=np.float32)[:, None, None]
    img = rgb(top) * (1 - y) + rgb(bot) * y
    img = np.broadcast_to(img, (H, W, 3)).copy()
    xs = np.linspace(0, 1, W, dtype=np.float32)[None, :]
    ys = np.linspace(0, H / W, H, dtype=np.float32)[:, None]
    for cx, cy, r, col, s in blobs:
        d = np.sqrt((xs - cx) ** 2 + (ys - cy * H / W) ** 2) / r
        a = np.clip(1 - d, 0, 1) ** 2 * s
        img = img * (1 - a[..., None]) + rgb(col) * a[..., None]
    rng = np.random.default_rng(seed)
    img += rng.normal(0, 1.6, (H, W, 1)).astype(np.float32)   # grain, hides banding
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for i, (n, spec) in enumerate(WALLS.items()):
        im = draw(n, spec, i)
        im.save(os.path.join(OUT, f"xlin-{n}.jpg"), quality=90, optimize=True)
        print("wrote", n)
