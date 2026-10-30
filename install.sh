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
# Everything XLIN needs is installed here (only what is missing). The same step runs on every update.
say "Installing dependencies"
source "$SRC/scripts/deps.sh"
xlin_deps || echo "(some packages are missing; fix them, then run: xlin deps)"

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
sudo install -m 755 "$SRC/bin/xlin-debug" /usr/local/bin/xlin-debug
sudo install -m 755 "$SRC/bin/xlin-terminal" /usr/local/bin/xlin-terminal
sudo install -m 755 "$SRC/bin/xlin-desktop" /usr/local/bin/xlin-desktop
sudo install -m 755 "$SRC/bin/xlin-start" /usr/local/bin/xlin-start
sudo install -D -m 644 "$SRC/lib/hyprland.sh" /usr/local/lib/xlin/hyprland.sh
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
cp "$SRC/config/hypr/xlin.conf" "$SRC/config/hypr/xlin.lua" "$HOME/.config/hypr/"

# ----------------------------------------------- hook XLIN into the Hyprland config
# Hyprland 0.55+ reads hyprland.lua (0.57 dropped hyprland.conf); older versions read hyprland.conf.
# `xlin hook` picks the right one, keeps a backup, and puts XLIN last so its shortcuts always work.
for hc in "$HOME/.config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.conf"; do
  [[ -f "$hc" ]] && backup "$hc"
done
/usr/local/bin/xlin hook

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
