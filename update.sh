#!/usr/bin/env bash
# Update XLIN from this folder. Missing dependencies are installed automatically.
#   ./update.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XLIN_HOME="$HOME/.config/xlin"
export XLIN_HOME

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root."; exit 1; }
say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

say "Copying XLIN files"
mkdir -p "$XLIN_HOME/state" "$XLIN_HOME/wallpapers" "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/swaync"
echo "$SRC" >"$XLIN_HOME/state/source"
cp -r "$SRC/themes" "$SRC/templates" "$XLIN_HOME/"
mkdir -p "$XLIN_HOME/wallpapers"
cp "$SRC"/assets/wallpapers/*.jpg "$XLIN_HOME/wallpapers/"
cp "$SRC/config/shell/xlin.bash" "$XLIN_HOME/shell.bash"
cp "$SRC/config/kitty/kitty.conf" "$XLIN_HOME/kitty.conf"
cp "$SRC/config/hypr/xlin.conf" "$SRC/config/hypr/xlin.lua" "$HOME/.config/hypr/"
# Keep the first user-config backup across repeated updates. The installer uses
# the same .bak- timestamp convention, so its original backup is respected.
STAMP="$(date +%Y%m%d-%H%M%S)"
backup_once() {
  local file="$1"
  [[ -e "$file" || -L "$file" ]] || return 0
  if compgen -G "$file.bak-*" >/dev/null; then
    echo "   existing backup preserved for $file"
    return 0
  fi
  cp -a -- "$file" "$file.bak-$STAMP"
  echo "   backed up $file"
}

backup_once "$HOME/.config/waybar/config.jsonc"
cp "$SRC/config/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
cp "$SRC/config/waybar/config.jsonc" "$XLIN_HOME/waybar-base.jsonc"
backup_once "$HOME/.config/swaync/config.json"
cp "$SRC/config/swaync/config.json" "$HOME/.config/swaync/config.json"

say "Checking dependencies (installs anything that is missing)"
source "$SRC/scripts/deps.sh"
xlin_deps || echo "(some packages are missing; the message above says which)"

say "Installing the xlin commands (asks for your password once)"
sudo rm -f /usr/local/bin/xlin-launcher      # the App drawer was merged into the Launcher
for b in xlin xlin-dock-watch xlin-settings xlin-tools xlin-welcome xlin-files xlin-monitor xlin-terminal xlin-desktop xlin-start xlin-store xlin-media xlin-debug; do
  sudo install -m 755 "$SRC/bin/$b" "/usr/local/bin/$b"
done

sudo install -D -m 644 "$SRC/lib/xlin_ui.py" /usr/local/lib/xlin/xlin_ui.py
mkdir -p "$HOME/.local/share/applications"
cp "$SRC"/config/applications/dev.xlin.*.desktop "$HOME/.local/share/applications/"
mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"
cp "$SRC"/assets/icons/*.svg "$HOME/.local/share/icons/hicolor/scalable/apps/"
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
mkdir -p "$HOME/.local/share/icons"
cp -a "$SRC/assets/cursors/." "$HOME/.local/share/icons/"

/usr/local/bin/xlin hook || true

say "Applying theme and terminal"
theme="$(cat "$XLIN_HOME/state/theme" 2>/dev/null || echo light)"
/usr/local/bin/xlin theme "$theme" || true
/usr/local/bin/xlin terminal || true
/usr/local/bin/xlin adapt || true

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  hyprctl reload >/dev/null 2>&1 || true
  /usr/local/bin/xlin restart || true
fi
say "Done. Open a new terminal."
