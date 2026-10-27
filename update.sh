#!/usr/bin/env bash
# Update XLIN from this folder WITHOUT installing packages.
# Use this after downloading a newer xlin.tar.gz:   ./update.sh
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
cp "$SRC/config/hypr/xlin.conf" "$HOME/.config/hypr/xlin.conf"
cp "$SRC/config/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
cp "$SRC/config/waybar/config.jsonc" "$XLIN_HOME/waybar-base.jsonc"
cp "$SRC/config/swaync/config.json" "$HOME/.config/swaync/config.json"

say "Power modes need power-profiles-daemon (skipped if you have it)"
sudo pacman -S --needed --noconfirm power-profiles-daemon || echo "(could not install it; the battery menu will show how)"
sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true

say "Lock screen"
sudo pacman -S --needed --noconfirm hyprlock || echo "(could not install hyprlock; Super+L will tell you)"

say "Daily-use extras (screenshots, clipboard, auto-lock, night light, portals)"
for pkg in vte4 gtk4-layer-shell udisks2 gvfs gvfs-smb grim slurp wl-clipboard cliphist hypridle hyprsunset xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent; do
  sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1 || echo "   (could not install $pkg)"
done
# XLIN Terminal needs vte4; if that is not possible, install kitty so there is always a terminal
python3 -c "import gi; gi.require_version('Vte','3.91')" >/dev/null 2>&1 || \
  sudo pacman -S --needed --noconfirm kitty >/dev/null 2>&1 || echo "   (no terminal could be installed: sudo pacman -S vte4)"
systemctl --user enable --now hyprpolkitagent.service >/dev/null 2>&1 || true

say "Installing the xlin commands (asks for your password once)"
for b in xlin xlin-dock-watch xlin-settings xlin-tools xlin-welcome xlin-files xlin-monitor xlin-terminal xlin-desktop xlin-launcher; do
  sudo install -m 755 "$SRC/bin/$b" "/usr/local/bin/$b"
done

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
