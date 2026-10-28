#!/usr/bin/env bash
# XLIN installer for Arch Linux + Hyprland
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XLIN_HOME="$HOME/.config/xlin"
BIN="$HOME/.local/bin"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

[[ -f /etc/arch-release ]] || { echo "XLIN installer targets Arch Linux."; exit 1; }
[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root."; exit 1; }

# ---------------------------------------------------------------- packages
aur_helper=""
for h in paru yay; do command -v "$h" >/dev/null && aur_helper="$h" && break; done

pick_repo() { # first package that exists in the repos
  local p
  for p in "$@"; do pacman -Si "$p" >/dev/null 2>&1 && { echo "$p"; return; }; done
}

say "Installing packages"
core=(hyprland waybar swaync jq socat libnotify brightnessctl networkmanager
      network-manager-applet pipewire wireplumber pavucontrol blueman
      imagemagick ttf-font-awesome inter-font gtk3 gtk4 python-gobject bluez bluez-utils power-profiles-daemon hyprlock)

pacman_fail() {
  cat <<'EOF'

!! pacman could not finish. If you saw "404" errors, your package database is
   out of date. Update the whole system first, then run this installer again:

       sudo pacman -Syu
       ./install.sh
EOF
  exit 1
}

sudo pacman -S --needed --noconfirm "${core[@]}" || pacman_fail

# Wi-Fi and Bluetooth only work when their background services are running
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon || \
  echo "(could not start NetworkManager/bluetooth services; Wi-Fi/Bluetooth pages may stay empty)"

# Terminal font (monospace with icons). Falls back to the plain version, then to what you have.
sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd 2>/dev/null || \
  sudo pacman -S --needed --noconfirm ttf-jetbrains-mono 2>/dev/null || \
  echo "(JetBrains Mono not installed; the terminal will use another monospace font)"

# Icon font for the bar and control panel (works whatever Font Awesome version is installed)
sudo pacman -S --needed --noconfirm ttf-nerd-fonts-symbols || echo "(icon font not installed, icons may be blank)"
fc-cache -f >/dev/null 2>&1 || true

wall_pkg="$(pick_repo awww swww hyprpaper)"
sudo pacman -S --needed --noconfirm ${wall_pkg:+"$wall_pkg"} || pacman_fail
# rofi is optional now: the app drawer is XLIN's own (only the clipboard/shortcut pickers still use it)
rofi_pkg="$(pick_repo rofi-wayland rofi)"
[[ -n "$rofi_pkg" ]] && { sudo pacman -S --needed --noconfirm "$rofi_pkg" || echo "(rofi not installed, that is fine)"; }

# A file manager is optional: XLIN uses whichever one you already have
have_fm=0
for fm in thunar nautilus dolphin nemo pcmanfm; do command -v "$fm" >/dev/null 2>&1 && have_fm=1; done
((have_fm)) || echo "(no file manager found. Install one you like, e.g. 'sudo pacman -S thunar'; Super+E opens it)"

if ! pacman -Si nwg-dock-hyprland >/dev/null 2>&1 && [[ -n "$aur_helper" ]]; then
  "$aur_helper" -S --needed --noconfirm nwg-dock-hyprland
else
  sudo pacman -S --needed --noconfirm nwg-dock-hyprland || \
    echo "!! nwg-dock-hyprland not found. Install it from the AUR, then run: xlin doctor"
fi

# Font: XLIN uses DM Sans when it is installed and falls back to Inter (already installed above).
# DM Sans is optional and is not installed automatically, because AUR helpers can resolve
# the name to a huge "all Google fonts" package.

# Daily-use extras: screenshots, clipboard history, auto-lock, night light, screen-share portal
for pkg in vte4 gtk4-layer-shell udisks2 gvfs gvfs-smb grim slurp wl-clipboard cliphist hypridle hyprsunset xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent; do
  sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1 || echo "   (could not install $pkg)"
done

# XLIN Terminal needs vte4; if that is not possible, install kitty so there is always a terminal
python3 -c "import gi; gi.require_version('Vte','3.91')" >/dev/null 2>&1 || \
  sudo pacman -S --needed --noconfirm kitty >/dev/null 2>&1 || echo "   (no terminal could be installed: sudo pacman -S vte4)"

# ------------------------------------------------------------------- files
say "Installing XLIN to $XLIN_HOME"
mkdir -p "$XLIN_HOME" "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/swaync"
cp -r "$SRC/themes" "$SRC/templates" "$XLIN_HOME/"
mkdir -p "$XLIN_HOME/wallpapers"
cp "$SRC"/assets/wallpapers/*.jpg "$XLIN_HOME/wallpapers/"
cp "$SRC/config/shell/xlin.bash" "$XLIN_HOME/shell.bash"
cp "$SRC/config/kitty/kitty.conf" "$XLIN_HOME/kitty.conf"

# /usr/local/bin is on every session's PATH, including Hyprland's exec-once and Waybar clicks
sudo install -m 755 "$SRC/bin/xlin" /usr/local/bin/xlin
sudo install -m 755 "$SRC/bin/xlin-dock-watch" /usr/local/bin/xlin-dock-watch
sudo install -m 755 "$SRC/bin/xlin-settings" /usr/local/bin/xlin-settings
sudo install -m 755 "$SRC/bin/xlin-tools" /usr/local/bin/xlin-tools
sudo install -m 755 "$SRC/bin/xlin-welcome" /usr/local/bin/xlin-welcome
sudo install -m 755 "$SRC/bin/xlin-files" /usr/local/bin/xlin-files
sudo install -m 755 "$SRC/bin/xlin-monitor" /usr/local/bin/xlin-monitor
sudo install -m 755 "$SRC/bin/xlin-store" /usr/local/bin/xlin-store
sudo install -m 755 "$SRC/bin/xlin-media" /usr/local/bin/xlin-media
sudo install -m 755 "$SRC/bin/xlin-terminal" /usr/local/bin/xlin-terminal
sudo install -m 755 "$SRC/bin/xlin-desktop" /usr/local/bin/xlin-desktop
sudo install -m 755 "$SRC/bin/xlin-launcher" /usr/local/bin/xlin-launcher
sudo install -m 755 "$SRC/bin/xlin-start" /usr/local/bin/xlin-start
sudo install -D -m 644 "$SRC/lib/xlin_ui.py" /usr/local/lib/xlin/xlin_ui.py
mkdir -p "$HOME/.local/share/applications"
cp "$SRC"/config/applications/dev.xlin.*.desktop "$HOME/.local/share/applications/"
mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"
cp "$SRC"/assets/icons/*.svg "$HOME/.local/share/icons/hicolor/scalable/apps/"
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
mkdir -p "$HOME/.local/share/icons"
cp -a "$SRC/assets/cursors/." "$HOME/.local/share/icons/"
mkdir -p "$XLIN_HOME/wallpapers" "$XLIN_HOME/state"
echo "$SRC" >"$XLIN_HOME/state/source"

backup() { [[ -e "$1" ]] && cp -a "$1" "$1.bak-$STAMP" && echo "   backed up $1" || true; }

# Waybar prefers a file called `config` over `config.jsonc`, so move an old one aside
if [[ -f "$HOME/.config/waybar/config" ]]; then
  mv "$HOME/.config/waybar/config" "$HOME/.config/waybar/config.bak-$STAMP"
  echo "   moved old waybar config aside"
fi

backup "$HOME/.config/waybar/config.jsonc"
cp "$SRC/config/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
cp "$SRC/config/waybar/config.jsonc" "$XLIN_HOME/waybar-base.jsonc"
backup "$HOME/.config/swaync/config.json"
cp "$SRC/config/swaync/config.json" "$HOME/.config/swaync/config.json"
cp "$SRC/config/hypr/xlin.conf" "$HOME/.config/hypr/xlin.conf"

# ------------------------------------------------------- hyprland.conf hook
HC="$HOME/.config/hypr/hyprland.conf"
touch "$HC"
backup "$HC"
/usr/local/bin/xlin hook      # puts the XLIN line last in hyprland.conf, so the shortcuts always work

# ------------------------------------------------------------------- theme
say "Applying light theme"
export XLIN_HOME
/usr/local/bin/xlin theme light || true
/usr/local/bin/xlin terminal || true
/usr/local/bin/xlin adapt || true

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  say "Starting XLIN now"
  hyprctl reload >/dev/null 2>&1 || true
  /usr/local/bin/xlin restart || true   # restarts the bar so old configs are replaced
fi

say "Done. Run 'xlin doctor' to check everything. If something is missing, run 'xlin start'."
