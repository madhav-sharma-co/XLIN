#!/usr/bin/env python3
"""Draws the XLIN cursor themes (XLIN = light, XLIN-Dark = dark) and writes
them as real X cursors. Needs Pillow only. Run: python3 scripts/make-cursors.py
Output: assets/cursors/XLIN and assets/cursors/XLIN-Dark (already committed)."""
import math
import os
import struct
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "cursors")
SIZES = (24, 32, 48, 64)
SS = 8  # supersampling

THEMES = {
    # XLIN = for the light desktop (dark cursor); XLIN-Dark = for the dark desktop (white cursor)
    "XLIN":      dict(fill=(36, 36, 40),    line=(255, 255, 255), accent=(10, 132, 255)),
    "XLIN-Dark": dict(fill=(255, 255, 255), line=(28, 28, 30),    accent=(64, 156, 255)),
}


class Canvas:
    """Draw on a 32x32 design grid; S is the output size in pixels."""

    def __init__(self, S):
        self.S, self.k = S, S * SS / 32.0
        self.n = S * SS

    def mask(self):
        return Image.new("L", (self.n, self.n), 0)

    def pt(self, p):
        return (p[0] * self.k, p[1] * self.k)

    def poly(self, pts, m=None):
        m = m or self.mask()
        ImageDraw.Draw(m).polygon([self.pt(p) for p in pts], fill=255)
        return m

    def rrect(self, x0, y0, x1, y1, r, m=None):
        m = m or self.mask()
        ImageDraw.Draw(m).rounded_rectangle([x0 * self.k, y0 * self.k, x1 * self.k, y1 * self.k],
                                            radius=r * self.k, fill=255)
        return m

    def circle(self, cx, cy, r, m=None):
        m = m or self.mask()
        ImageDraw.Draw(m).ellipse([(cx - r) * self.k, (cy - r) * self.k, (cx + r) * self.k, (cy + r) * self.k], fill=255)
        return m

    def ring(self, cx, cy, r, w, a0=0, a1=360, m=None):
        m = m or self.mask()
        d = ImageDraw.Draw(m)
        box = [(cx - r) * self.k, (cy - r) * self.k, (cx + r) * self.k, (cy + r) * self.k]
        d.arc(box, a0, a1, fill=255, width=max(1, int(w * self.k)))
        return m

    def line(self, a, b, w, m=None):
        m = m or self.mask()
        d = ImageDraw.Draw(m)
        d.line([self.pt(a), self.pt(b)], fill=255, width=max(1, int(w * self.k)))
        for p in (a, b):
            self.circle(p[0], p[1], w / 2, m)
        return m

    def soften(self, m, r=0.9):
        """round every corner a little"""
        b = m.filter(ImageFilter.GaussianBlur(r * self.k))
        return b.point(lambda v: 255 if v > 128 else 0)

    def grow(self, m, r):
        size = int(r * self.k) * 2 + 1
        return m.filter(ImageFilter.MaxFilter(size if size % 2 else size + 1))

    def rot(self, m, deg, c=(16, 16)):
        return m.rotate(deg, center=self.pt(c), resample=Image.BICUBIC)


def compose(c, parts, theme):
    """parts: list of (mask, colour-or-None); None = fill colour with outline."""
    out = Image.new("RGBA", (c.n, c.n), (0, 0, 0, 0))
    union = c.mask()
    for m, _ in parts:
        union = ImageChops.lighter(union, m)
    outline = c.grow(union, 1.15)
    # soft shadow
    sh = ImageChops.offset(outline, 0, int(0.9 * c.k)).filter(ImageFilter.GaussianBlur(1.1 * c.k))
    shadow = Image.new("RGBA", (c.n, c.n), (0, 0, 0, 255))
    shadow.putalpha(sh.point(lambda v: int(v * 0.38)))
    out = Image.alpha_composite(out, shadow)
    line = Image.new("RGBA", (c.n, c.n), theme["line"] + (255,))
    line.putalpha(outline)
    out = Image.alpha_composite(out, line)
    for m, col in parts:
        layer = Image.new("RGBA", (c.n, c.n), (col or theme["fill"]) + (255,))
        layer.putalpha(m)
        out = Image.alpha_composite(out, layer)
    return out.resize((c.S, c.S), Image.LANCZOS)


# ------------------------------------------------------------------ shapes
def arrow_mask(c):
    return c.soften(c.poly([(6, 4), (6, 25.5), (11.4, 20.4), (15.2, 28.4), (19, 26.7),
                            (15.3, 18.9), (22.6, 18.9)]), 0.7)


def shape_arrow(c, t):
    return [(arrow_mask(c), None)], (6, 4)


def shape_text(c, t):
    m = c.mask()
    c.rrect(14.6, 6, 17.4, 26, 1.0, m)
    c.rrect(10.6, 5, 21.4, 7.6, 1.2, m)
    c.rrect(10.6, 24.4, 21.4, 27, 1.2, m)
    return [(c.soften(m, 0.3), None)], (16, 16)


def shape_hand(c, t):
    m = c.mask()
    c.rrect(11, 3.5, 15.6, 16, 2.3, m)       # index
    c.rrect(15.2, 11, 19, 17, 1.8, m)        # middle knuckle
    c.rrect(18.6, 12, 22.2, 18, 1.8, m)      # ring
    c.rrect(22, 13.5, 25.4, 19, 1.7, m)      # little
    c.rrect(7.5, 14.5, 25.4, 27, 5, m)       # palm
    c.poly([(7.5, 17), (10, 12.6), (12.5, 16), (12.5, 22), (8, 22)], m)  # thumb
    return [(c.soften(m, 0.5), None)], (13.3, 4)


def shape_grab(c, t):
    m = c.mask()
    for i, x in enumerate((8.5, 12.7, 16.9, 21.1)):
        c.rrect(x, 9.5 + (0.8 if i in (0, 3) else 0), x + 3.8, 18, 1.9, m)
    c.rrect(7.5, 14, 25, 26, 5, m)
    c.poly([(7, 18), (5.5, 14.5), (9, 15)], m)
    return [(c.soften(m, 0.5), None)], (16, 16)


def shape_grabbing(c, t):
    m = c.mask()
    for i, x in enumerate((8.8, 12.8, 16.8, 20.8)):
        c.rrect(x, 13, x + 3.7, 19, 1.8, m)
    c.rrect(7.5, 15.5, 25, 26, 5, m)
    return [(c.soften(m, 0.5), None)], (16, 17)


def shape_cross(c, t):
    m = c.mask()
    c.line((16, 5), (16, 27), 2.2, m)
    c.line((5, 16), (27, 16), 2.2, m)
    dot = c.circle(16, 16, 2.1)
    return [(m, None), (dot, t["accent"])], (16, 16)


def arrow_head_poly(tip, direction, size=5.2, half=4.2):
    dx, dy = direction
    px, py = -dy, dx
    bx, by = tip[0] - dx * size, tip[1] - dy * size
    return [tip, (bx + px * half, by + py * half), (bx - px * half, by - py * half)]


def double_arrow(c, vertical=True, both=True):
    m = c.mask()
    if vertical:
        c.line((16, 8), (16, 24), 2.6, m)
        c.poly(arrow_head_poly((16, 3.8), (0, -1)), m)
        c.poly(arrow_head_poly((16, 28.2), (0, 1)), m)
    else:
        c.line((8, 16), (24, 16), 2.6, m)
        c.poly(arrow_head_poly((3.8, 16), (-1, 0)), m)
        c.poly(arrow_head_poly((28.2, 16), (1, 0)), m)
    return c.soften(m, 0.35)


def shape_ns(c, t):
    return [(double_arrow(c, True), None)], (16, 16)


def shape_ew(c, t):
    return [(double_arrow(c, False), None)], (16, 16)


def shape_fdiag(c, t):  # top-left <-> bottom-right
    return [(c.rot(double_arrow(c, True), 45), None)], (16, 16)


def shape_bdiag(c, t):  # top-right <-> bottom-left
    return [(c.rot(double_arrow(c, True), -45), None)], (16, 16)


def shape_move(c, t):
    m = c.mask()
    c.line((16, 7), (16, 25), 2.4, m)
    c.line((7, 16), (25, 16), 2.4, m)
    for d in ((0, -1), (0, 1), (-1, 0), (1, 0)):
        c.poly(arrow_head_poly((16 + d[0] * 12.6, 16 + d[1] * 12.6), d, 4.6, 3.8), m)
    return [(c.soften(m, 0.35), None)], (16, 16)


def shape_no(c, t):
    ring = c.ring(16, 16, 9.5, 3.4)
    ring = ImageChops.lighter(ring, c.line((9.6, 22.4), (22.4, 9.6), 3.4))
    return [(c.soften(ring, 0.3), (230, 60, 60))], (16, 16)


def shape_help(c, t):
    a = arrow_mask(c)
    badge = c.circle(23, 23, 6.2)
    q = Image.new("L", (c.n, c.n), 0)
    try:
        f = ImageFont.load_default(size=int(11 * c.k))
        d = ImageDraw.Draw(q)
        d.text((23 * c.k, 23.4 * c.k), "?", fill=255, font=f, anchor="mm")
    except Exception:
        pass
    return [(a, None), (badge, t["accent"]), (q, (255, 255, 255))], (6, 4)


def shape_copy(c, t):
    a = arrow_mask(c)
    badge = c.circle(24, 24, 5.6)
    plus = c.line((24, 21, ), (24, 27), 1.7)
    plus = ImageChops.lighter(plus, c.line((21, 24), (27, 24), 1.7))
    return [(a, None), (badge, t["accent"]), (plus, (255, 255, 255))], (6, 4)


def spinner_frame(c, ang, cx=16, cy=16, r=9, w=3.4):
    base = c.ring(cx, cy, r, w)
    arc = c.ring(cx, cy, r, w, ang, ang + 100)
    return base, arc


def shape_wait(c, t, ang=0):
    base, arc = spinner_frame(c, ang)
    return [(c.soften(base, 0.2), (200, 204, 212)), (arc, t["accent"])], (16, 16)


def shape_progress(c, t, ang=0):
    a = arrow_mask(c)
    cx, cy, r, w = 23.5, 23.5, 5, 2.6
    disc = c.circle(cx, cy, 7.4)
    base = c.ring(cx, cy, r, w)
    arc = c.ring(cx, cy, r, w, ang, ang + 100)
    return [(a, None), (disc, t["fill"]), (base, (200, 204, 212)), (arc, t["accent"])], (6, 4)


# name -> (builder, frames). Aliases listed separately.
STATIC = {
    "left_ptr": shape_arrow, "text": shape_text, "pointer": shape_hand, "grab": shape_grab,
    "grabbing": shape_grabbing, "crosshair": shape_cross, "ns-resize": shape_ns, "ew-resize": shape_ew,
    "nwse-resize": shape_fdiag, "nesw-resize": shape_bdiag, "move": shape_move,
    "not-allowed": shape_no, "help": shape_help, "copy": shape_copy,
}
ANIMATED = {"wait": shape_wait, "progress": shape_progress}
FRAMES, DELAY = 12, 80

ALIASES = {
    "default": "left_ptr", "arrow": "left_ptr", "top_left_arrow": "left_ptr", "context-menu": "left_ptr",
    "pointing_hand": "pointer", "hand1": "pointer", "hand2": "pointer", "openhand": "grab", "grabbing": "grabbing",
    "closedhand": "grabbing", "dnd-none": "left_ptr", "xterm": "text", "ibeam": "text", "vertical-text": "text",
    "cross": "crosshair", "tcross": "crosshair", "cross_reverse": "crosshair", "plus": "crosshair",
    "fleur": "move", "all-scroll": "move", "size_all": "move", "dnd-move": "move",
    "sb_v_double_arrow": "ns-resize", "row-resize": "ns-resize", "n-resize": "ns-resize", "s-resize": "ns-resize",
    "top_side": "ns-resize", "bottom_side": "ns-resize", "size_ver": "ns-resize", "v_double_arrow": "ns-resize",
    "sb_h_double_arrow": "ew-resize", "col-resize": "ew-resize", "e-resize": "ew-resize", "w-resize": "ew-resize",
    "left_side": "ew-resize", "right_side": "ew-resize", "size_hor": "ew-resize", "h_double_arrow": "ew-resize",
    "nw-resize": "nwse-resize", "se-resize": "nwse-resize", "top_left_corner": "nwse-resize",
    "bottom_right_corner": "nwse-resize", "size_fdiag": "nwse-resize",
    "ne-resize": "nesw-resize", "sw-resize": "nesw-resize", "top_right_corner": "nesw-resize",
    "bottom_left_corner": "nesw-resize", "size_bdiag": "nesw-resize",
    "forbidden": "not-allowed", "no-drop": "not-allowed", "crossed_circle": "not-allowed", "dnd-no-drop": "not-allowed",
    "question_arrow": "help", "whats_this": "help", "left_ptr_help": "help",
    "dnd-copy": "copy", "alias": "copy", "dnd-link": "copy", "link": "copy",
    "watch": "wait", "left_ptr_watch": "progress", "half-busy": "progress", "dnd-ask": "help",
}


def xcursor(images):
    """images: list of (nominal_size, w, h, xhot, yhot, delay_ms, RGBA Image)"""
    toc = len(images)
    head = struct.pack("<4sIII", b"Xcur", 16, 0x10000, toc)
    pos = 16 + toc * 12
    entries, chunks = b"", b""
    for size, w, h, xh, yh, delay, im in images:
        px = bytearray()
        for r, g, b, a in im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata():
            px += struct.pack("<I", (a << 24) | ((r * a // 255) << 16) | ((g * a // 255) << 8) | (b * a // 255))
        chunk = struct.pack("<IIIIIIIII", 36, 0xFFFD0002, size, 1, w, h, xh, yh, delay) + bytes(px)
        entries += struct.pack("<III", 0xFFFD0002, size, pos)
        chunks += chunk
        pos += len(chunk)
    return head + entries + chunks


def build_image(builder, theme, S, **kw):
    c = Canvas(S)
    parts, hot = builder(c, theme, **kw)
    return compose(c, parts, theme), (int(round(hot[0] * S / 32)), int(round(hot[1] * S / 32)))


def write_theme(name, theme):
    d = os.path.join(OUT, name, "cursors")
    os.makedirs(d, exist_ok=True)
    for f in os.listdir(d):
        os.remove(os.path.join(d, f))
    for cname, b in STATIC.items():
        imgs = []
        for S in SIZES:
            im, (hx, hy) = build_image(b, theme, S)
            imgs.append((S, S, S, hx, hy, 0, im))
        open(os.path.join(d, cname), "wb").write(xcursor(imgs))
    for cname, b in ANIMATED.items():
        imgs = []
        for S in SIZES:
            for i in range(FRAMES):
                im, (hx, hy) = build_image(b, theme, S, ang=i * 360 // FRAMES)
                imgs.append((S, S, S, hx, hy, DELAY, im))
        open(os.path.join(d, cname), "wb").write(xcursor(imgs))
    for alias, target in ALIASES.items():
        if alias in STATIC or alias in ANIMATED:
            continue
        os.symlink(target, os.path.join(d, alias))
    open(os.path.join(OUT, name, "index.theme"), "w").write(
        "[Icon Theme]\nName=%s\nComment=XLIN cursor theme\n" % name)


def preview(path):
    cells = list(STATIC) + ["wait", "progress"]
    sheet = Image.new("RGBA", (len(cells) * 80, 2 * 90), (0, 0, 0, 0))
    for row, (name, theme) in enumerate(THEMES.items()):
        bg = (245, 246, 250, 255) if row == 0 else (40, 42, 48, 255)
        ImageDraw.Draw(sheet).rectangle([0, row * 90, sheet.width, row * 90 + 90], fill=bg)
        for i, cname in enumerate(cells):
            b = STATIC.get(cname) or ANIMATED[cname]
            im, _ = build_image(b, theme, 64)
            sheet.alpha_composite(im, (i * 80 + 8, row * 90 + 13))
    sheet.convert("RGB").save(path)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--preview":
        preview(sys.argv[2])
        sys.exit(0)
    for n, t in THEMES.items():
        write_theme(n, t)
        print("wrote", n)
