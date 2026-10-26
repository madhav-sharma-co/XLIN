# Changelog

## 0.10.0
- `xlin update` and `xlin update check`; Settings -> About shows the version and has an Update XLIN button

## 0.9.3
- Fix: the Settings Appearance page did not open (missing accent colour row code)
- Screenshots: clear "Screenshot taken, saved in Pictures/Screenshots" notification, and a failure notification with the reason

## 0.9.2
- Shortcuts can no longer be taken over by another config: the installer and `./update.sh` put the XLIN line last in hyprland.conf (`xlin hook`)
- `xlin keys check` shows every XLIN shortcut and what it does now; `xlin keys fix` repairs clashes (also runs at login)
- `xlin doctor` checks the shortcuts
- GTK apps request Gdk 4.0 explicitly (no more warnings)

## 0.9.1
- XLIN Files: picture thumbnails, right-click menu

## 0.9.0
- XLIN Files: search, copy/cut/paste, drag and drop, Trash restore

## 0.8.0
- XLIN Files: browse, rename, new folder, trash

## 0.7.0
- Notes tool (plain .md files), quick note (Super+Shift+N)

## 0.6.0
- Accent colours, first-run Welcome tour, `xlin uninstall`, fuller `xlin doctor`

## 0.5.0
- Screenshots, volume/brightness popup, auto-lock, night light, clipboard history

## 0.4.0
- XLIN CLI: wifi, bluetooth, sound, brightness, battery, status, help, tab completion
- Lock screen, power menu, battery menu, mnemonic shortcuts

## 0.1 - 0.3
- Top bar, launcher, dock, control panel, Settings, Tools (calculator, calendar), XLIN Terminal
