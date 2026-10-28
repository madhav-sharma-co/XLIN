"""Shared pieces for the XLIN apps: the three window buttons (hide, fullscreen, close) and the title bar.

Panels (control panel, launcher, app drawer) are not windows: they only get a close button.
"""
import json
import os
import subprocess

from gi.repository import Gtk


def _hypr(*args):
    try:
        subprocess.Popen(["hyprctl", *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def _address(win):
    """Hyprland's address for this very window (not whichever one happens to be focused)."""
    try:
        out = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=2).stdout
        mine = [c for c in json.loads(out) if c.get("pid") == os.getpid()]
    except Exception:
        return None
    if len(mine) > 1:
        title = win.get_title() if win is not None else None
        same = [c for c in mine if c.get("title") == title]
        mine = same or mine
    return mine[0]["address"] if mine else None


def hide_window(win=None):
    """Send this window out of sight (Super+H or `xlin unhide` brings it back)."""
    addr = _address(win)
    if addr:
        _hypr("dispatch", "movetoworkspacesilent", f"special:xlin-hidden,address:{addr}")


def toggle_fullscreen(win=None):
    """Real fullscreen, exactly like Super+F; press again to leave it."""
    addr = _address(win)
    if addr:
        _hypr("--batch", f"dispatch focuswindow address:{addr} ; dispatch fullscreen 0")


def _button(glyph, tip, css, fn):
    b = Gtk.Button(label=glyph)
    b.add_css_class("win-btn")
    b.add_css_class(css)
    b.set_tooltip_text(tip)
    b.set_focusable(False)
    b.connect("clicked", lambda _b: fn())
    return b


def close_button(win):
    return _button("✕", "Close", "win-close", win.close)


def controls(win, hide=True, full=True):
    """The row of buttons: hide, fullscreen, close (in that order, like Windows)."""
    box = Gtk.Box(spacing=4)
    box.add_css_class("win-controls")
    if hide:
        box.append(_button("–", "Hide", "win-hide", lambda: hide_window(win)))
    if full:
        box.append(_button("▢", "Fullscreen", "win-full", lambda: toggle_fullscreen(win)))
    box.append(close_button(win))
    return box


def titlebar(win, title, hide=True, full=True):
    """Replace the system title bar with XLIN's: title on the left, buttons on the right, drag to move."""
    handle = Gtk.WindowHandle()
    strip = Gtk.Box(spacing=8)
    strip.add_css_class("xlin-titlebar")
    label = Gtk.Label(label=title, xalign=0, hexpand=True)
    label.add_css_class("tool-title")
    strip.append(label)
    strip.append(controls(win, hide, full))
    handle.set_child(strip)
    win.set_titlebar(handle)
    return label
