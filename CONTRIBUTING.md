# Contributing to Xlin-soft

Thanks for helping. Xlin-soft is a Hyprland desktop on Arch Linux, written mostly in Bash and
GTK4 Python.

## Layout
- `bin/xlin` - the command line (everything is a `cmd_*` function)
- `bin/xlin-*` - the GTK4 apps (PyGObject); `lib/xlin_ui.py` - code they share (title bar, theme reload, sizes, menus)
- `themes/` - colour palettes (`light.sh`, `dark.sh`); `templates/` - config files with `@C_NAME@` placeholders
- `config/` - Hyprland (`xlin.lua` for 0.55+, `xlin.conf` for older: keep both in step), Waybar, swaync, Kitty and shell files
- `scripts/deps.sh` - the one list of packages, used by install, update and `xlin deps`
- `install.sh` (first install) and `update.sh` (update without reinstalling packages)

## Before you open a pull request
    bash -n bin/xlin install.sh update.sh config/shell/xlin.bash
    shellcheck bin/xlin            # optional but welcome
    python3 -m py_compile bin/xlin-* lib/xlin_ui.py
    xlin doctor

Please say which Hyprland version you tested on. Keep corners at 10-12px, keep the light and
dark themes in step, and add new commands to `xlin help` and the Tab completion in
`config/shell/xlin.bash`.

## Adding a theme
Copy `themes/dark.sh`, change the `C_*` values, and run `xlin theme <name>`.
