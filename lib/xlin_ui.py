"""Shared pieces for the XLIN apps: the three window buttons (hide, fullscreen, close) and the title bar.

Panels (control panel, launcher, app drawer) are not windows: they only get a close button.
"""
import subprocess

from gi.repository import Gtk


def _hypr(*args):
    try:
        subprocess.Popen(["hyprctl", "dispatch", *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def hide_window(_win=None):
    """Send the focused window out of sight (Super+H or the Run Bar brings it back)."""
    _hypr("movetoworkspacesilent", "special:xlin-hidden")


def toggle_fullscreen(_win=None):
    _hypr("fullscreen", "1")        # fills the screen but keeps the bars; same again to leave it


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
