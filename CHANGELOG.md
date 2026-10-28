# Changelog

## 0.26.2
- Fix: the fullscreen button is now real fullscreen, exactly like Super+F
- Fix: the hide button hides the window it belongs to (not whichever is focused); Super+H brings back the last hidden window, `xlin unhide all` brings back every one
- Top bar: the current-app name shows "Files" instead of "dev.xlin.Files"; clicking the date and time opens the Calendar

## 0.26.1
- Lock screen shows the battery level (top right) next to the time, date, name and password field
- The app drawer has a close button (panels only get a close button)

## 0.26.0
- Every XLIN app window (Settings, Files, Monitor, Terminal, Welcome, Calculator, Calendar, Notes, Screenshot) now has the same three buttons in its top corner: hide, fullscreen, close. The Tools menu stays a plain dropdown
- Hide moves the window out of sight; Super+H (or `xlin unhide`) brings hidden windows back
- Smoother panel animations (control panel, drawer and menus fade and pop in instead of sliding)

## 0.25.1
- App drawer matched to the old rofi look: DM Sans fonts, exact width and row height, always five columns, highlight follows the mouse, fixed 78px distance from the screen edge

## 0.25.0
- The app drawer is now XLIN's own (`xlin-launcher`, GTK + layer-shell) and no longer needs rofi: same look, same place above the Run Bar, same search, pinned/recent first, arrows + Enter, Alt+P pin, Alt+U unpin, Esc or a click outside closes
- rofi is optional now (installer and `xlin doctor`); it is only a fallback if the drawer cannot start, and is still used by the clipboard and shortcut pickers
- New: `xlin launch-app <id>`

## 0.24.0
- Desktop: icons and widgets now drag smoothly (one gesture on the whole desktop, so the pointer no longer jitters), lift with a shadow while moving, are kept on screen and glide into their grid cell when dropped
- New widgets: Battery, Media player (needs playerctl), Notes (shows recent notes, add a quick note), To-do list, Timer (with notification)
- Files and folders in ~/Desktop now appear as icons (double-click to open, right-click to Move to Trash)
- Desktop menu: New folder, Show desktop icons, Small / Medium / Large icons, Arrange icons; click an icon to select it

## 0.23.1
- Fix: Settings -> About -> Update XLIN did nothing when Kitty was not installed. It now opens XLIN Terminal (and falls back to foot, alacritty, gnome-terminal, konsole or xterm)
- Kitty is no longer required: the installer only installs it if XLIN Terminal cannot run, and `xlin doctor` checks XLIN Terminal instead

## 0.23.0
- Settings: new Bars page (show or hide the Settings, Tools, Wi-Fi, Bluetooth, Sound, Battery, Power and Control panel buttons on the top bar; Run Bar auto-hide and icon size) and a General page (desktop menu and widgets, cursor size, terminal choice, auto-lock and delay, night light)
- The bottom bar is now called the Run Bar everywhere (Settings, Welcome, README); `xlin runbar` is the command (`xlin dock` still works)
- Tab completion knows the new commands

## 0.22.0
- Calculator, Calendar and Notes now open in the middle of the screen (the Tools menu itself stays under the top bar); extra tools open a little offset so they do not hide each other
- New tool in the Tools menu: Screenshot (select an area, a window or the whole screen, with an optional 3 or 5 second delay, and a button for the Screenshots folder)

## 0.21.1
- Fix: copies and new zip files were numbered after the extension ("Archive.zip 2"); now "Archive 2.zip"
- Fix: Files restore from Trash gives a clear message when the trash record is missing
- Fix: if ImageMagick is missing, the theme wallpaper and the lock screen fall back to a built-in wallpaper instead of a missing file
- Fix: the installer no longer fails when the optional terminal / desktop packages (vte4, gtk4-layer-shell) or the USB / network packages are unavailable; they install one by one

## 0.21.0
- Terminal: search the scrollback (Ctrl+Shift+F), Ctrl+click links, a + button and x on tabs, Ctrl+scroll to zoom, drop files to paste their paths, Ctrl+Shift+N for a new window in the same folder

## 0.20.0
- Right-click the desktop for a menu: Add app shortcut, Widgets (clock, calendar, system), Next wallpaper / Choose picture, Terminal, Files, Settings
- Desktop shortcut icons (double-click to open, right-click to remove) and widgets, drag to arrange; positions are remembered in ~/.config/xlin/desktop.json
- New: `xlin desktop on|off|restart` (needs gtk4-layer-shell, installed by the installer)

## 0.19.0
- New app: XLIN Terminal (VTE): tabs (Ctrl+Shift+T), XLIN colours and font that follow `xlin theme`, copy/paste menu, text zoom. Super+Return / Super+T open it; `xlin term [-d folder] [-e cmd]` from the command line
- `xlin terminal use kitty` switches back to Kitty; Kitty is also the automatic fallback if VTE is missing

## 0.18.0
- New app: XLIN Monitor (Super+M, or `xlin monitor`): CPU, memory, disk and network cards, and a live list of your apps with End / Force quit
- Fix: the Welcome window rule was still the old size, so the new wallpaper page was cut off

## 0.17.0
- Welcome: new "Pick a wallpaper" page with thumbnails (and your own picture), a final "You're all set" page, and visible error messages instead of silent failures
- Fix: changing the wallpaper right after install could do nothing (the wallpaper daemon was not ready yet). XLIN now waits for it, supports old and new hyprpaper, and reports the real error

## 0.16.0
- Eight built-in wallpapers (light: dawn, mist, lagoon, blossom; dark: midnight, nebula, ember, forest). Super+W / Settings -> Appearance -> Next cycles through them; `scripts/make-wallpapers.py` redraws them

## 0.15.0
- Proper icons for XLIN's own apps (Settings, Files, Notes, Calculator, Calendar, Tools, Welcome, Power): the dock and launcher show them instead of the orange X. `scripts/make-icons.py` redraws them

## 0.14.0
- Own mouse cursor: XLIN (dark, for the light desktop) and XLIN-Dark (white, for the dark desktop), rounded with a soft shadow, accent-blue busy spinner. Follows the theme switch automatically; `xlin cursor 24|32|48|64` changes the size
- `scripts/make-cursors.py` redraws the cursors (Pillow only)

## 0.13.1
- Fix: update.sh wrote a damaged install-folder record, so Settings -> About -> Update XLIN said it needed a git install. It is repaired, and `xlin update` now also finds a clone in the usual places (~/XLIN, ~/Downloads/XLIN ...)

## 0.13.0
- XLIN Files: "Connect to server..." opens network folders (smb://, sftp://, ftp://, dav://); asks for a password in a window when needed (gvfs is installed by the installer)

## 0.12.0
- XLIN Files: right-click -> Open with... (pick an app, optionally make it the default for that file type)
- XLIN Files: right-click -> Extract here (zip, tar.*, 7z, rar, iso) and Compress to .zip

## 0.11.0
- XLIN Files: USB drives and other removable disks appear under "Drives" in the sidebar; click to mount and open, ⏏ to safely remove (needs udisks2, installed by the installer)

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
