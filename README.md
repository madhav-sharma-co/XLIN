# XLIN for Hyprland

A calm, clean, iPhone-style desktop for Hyprland on Arch Linux: light and dark themes, glass
panels, thin 11px corners, and its own apps (Settings, Tools, Welcome, Terminal, Lock screen).

## Install (Arch + Hyprland)

    tar xf xlin.tar.gz && cd xlin && ./install.sh
    hyprctl reload        # or log out and back in
    xlin doctor           # shows anything missing

Update later with `./update.sh` from a newer download. Remove everything with `xlin uninstall`
(your old Waybar, swaync and Kitty configs are put back).

## What you get

| Piece           | How                                                                   |
|-----------------|-----------------------------------------------------------------------|
| Top bar         | Waybar: X launcher, settings, tools, Wi-Fi, Bluetooth, sound, battery, clock, power, control panel |
| Launcher        | rofi grid above the dock. Alt+P pins, Alt+U unpins                    |
| Dock            | nwg-dock-hyprland, auto-hides, hidden when nothing runs or is pinned  |
| Control panel   | swaync: toggles, sliders and notifications (Super+C)                  |
| Settings        | XLIN Settings (GTK4): Wi-Fi, Bluetooth, Display, Sound, Appearance    |
| Tools           | Calculator and Calendar as small floating windows (Super+U)           |
| Battery / power | hover for charge, click for power mode; power menu: lock, sleep, log out, restart, power off |
| Lock screen    | hyprlock with your blurred wallpaper (Super+L), auto-lock when idle   |
| Files           | XLIN Files (Super+E): browse, search, copy/cut/paste, drag to move, Trash with restore |
| Terminal        | Kitty with the XLIN prompt and welcome card                           |
| Look            | light / dark, accent colours, window transparency (fullscreen stays solid) |
| Daily basics    | screenshots, clipboard history, night light, volume/brightness popup  |

## Keys

Press **Super+/** or run `xlin keys`. Every key is the first letter of what it does:
Super+S Settings, Super+C Control panel, Super+L Lock, Super+D Dark/light, Super+E Explorer,
Super+Q Quit window, Super+F Fullscreen, Super+Shift+F Float, Print screenshot.

## Command line

    xlin help                      everything, with help for each command
    xlin status                    one-screen overview
    xlin wifi | bluetooth | sound | brightness | battery
    xlin theme light|dark|toggle   xlin accent teal   xlin opacity 0.85
    xlin screenshot | clipboard | idle | nightlight | lock | session
    xlin doctor | uninstall

Tab completion works in the XLIN terminal.

## Notes

- Hyprland 0.53+ window and layer rule syntax is used.
- Dock flags can differ between nwg-dock-hyprland versions; see `dock_start` in `bin/xlin`.
- Logs are in `~/.cache/xlin/`.

## Contributing and licence

See [CONTRIBUTING.md](CONTRIBUTING.md). XLIN is released under the MIT licence ([LICENSE](LICENSE)).
