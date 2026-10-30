#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# shellcheck source=../lib/config-backups.sh
source "$ROOT/lib/config-backups.sh"

# The generated-file tracking helpers live in bin/xlin; load only those
# definitions so these tests never execute the desktop command dispatcher.
export HOME="$TMP/home"
mkdir -p "$HOME"
# shellcheck disable=SC1090
source <(sed -n '/^track_generated_file() {/,/^}/p; /^restore_generated_file() {/,/^}/p; /^write_opacity() {/,/^cmd_opacity() {/ { /^cmd_opacity() {/d; p; }; /^write_anim() {/,/^cmd_animations() {/ { /^cmd_animations() {/d; p; }; /^apply_gtk_theme() {/,/^cmd_theme() {/ { /^cmd_theme() {/d; p; }' "$ROOT/bin/xlin")

mkdir -p "$TMP/config"
file="$TMP/config/config.json"
printf 'original\n' >"$file"
xlin_backup_once "$file" 20260101-010101
printf 'updated\n' >"$file"
xlin_backup_once "$file" 20260102-020202
[[ "$(cat "$file.bak-20260101-010101")" == original ]] || { echo "FAIL: first backup content changed" >&2; exit 1; }
[[ ! -e "$file.bak-20260102-020202" ]] || { echo "FAIL: duplicate backup was created" >&2; exit 1; }

# Give the lexically later backup an earlier mtime; timestamp ordering must win.
printf 'later\n' >"$file.bak-20260103-030303"
touch -t 202610301300 "$file.bak-20260101-010101"
touch -t 202610301200 "$file.bak-20260103-030303"
printf 'generated\n' >"$file"
xlin_restore_oldest_backup "$file" >/dev/null
[[ "$(cat "$file")" == original ]] || { echo "FAIL: did not restore earliest timestamped backup" >&2; exit 1; }
echo "All config backup tests passed."

# Existing files must be restored after XLIN replaces them.
existing="$TMP/config/existing.css"
printf 'user stylesheet\n' >"$existing"
track_generated_file "$existing"
printf 'XLIN stylesheet\n' >"$existing"
restore_generated_file "$existing" >/dev/null
[[ "$(cat "$existing")" == "user stylesheet" ]] || { echo "FAIL: original generated-file backup was not restored" >&2; exit 1; }
[[ ! -e "$existing.xlin-backup" ]] || { echo "FAIL: generated-file backup sidecar remained" >&2; exit 1; }

# If copying the backup fails, keep both the current file and original backup.
failure="$TMP/config/restore-failure.css"
printf 'user original\n' >"$failure"
track_generated_file "$failure"
printf 'current generated\n' >"$failure"
cp() { return 1; }
if restore_generated_file "$failure" >/dev/null 2>&1; then
  echo "FAIL: restore unexpectedly succeeded when backup copy failed" >&2
  exit 1
fi
unset -f cp
[[ "$(cat "$failure")" == "current generated" ]] || { echo "FAIL: failed restore deleted the current file" >&2; exit 1; }
[[ "$(cat "$failure.xlin-backup")" == "user original" ]] || { echo "FAIL: failed restore damaged the original backup" >&2; exit 1; }
restore_generated_file "$failure" >/dev/null
[[ "$(cat "$failure")" == "user original" ]] || { echo "FAIL: retry did not restore original after transient failure" >&2; exit 1; }

# Files created by XLIN must be removed when no original existed.
created="$TMP/config/created.css"
track_generated_file "$created"
printf 'XLIN-created file\n' >"$created"
restore_generated_file "$created" >/dev/null
[[ ! -e "$created" && ! -e "$created.xlin-created" ]] || { echo "FAIL: XLIN-created file was not removed" >&2; exit 1; }

# Symlinks must be restored as symlinks, not flattened into regular files.
target="$TMP/config/target.css"
link="$TMP/config/link.css"
printf 'symlink target\n' >"$target"
ln -s "$target" "$link"
track_generated_file "$link"
printf 'generated regular file\n' >"$link"
restore_generated_file "$link" >/dev/null
[[ -L "$link" && "$(readlink "$link")" == "$target" ]] || { echo "FAIL: original symlink was not restored" >&2; exit 1; }

# Opacity output must preserve pre-existing Hyprland and Kitty config files.
mkdir -p "$HOME/.config/hypr" "$HOME/.config/kitty"
printf 'user hypr opacity\n' >"$HOME/.config/hypr/xlin-opacity.conf"
printf 'user lua opacity\n' >"$HOME/.config/hypr/xlin-opacity.lua"
printf 'user kitty opacity\n' >"$HOME/.config/kitty/xlin-opacity.conf"
write_opacity 0.90 0.82 quiet
[[ "$(cat "$HOME/.config/hypr/xlin-opacity.conf.xlin-backup")" == "user hypr opacity" ]] || { echo "FAIL: Hyprland opacity backup missing" >&2; exit 1; }
[[ "$(cat "$HOME/.config/hypr/xlin-opacity.lua.xlin-backup")" == "user lua opacity" ]] || { echo "FAIL: Lua opacity backup missing" >&2; exit 1; }
[[ "$(cat "$HOME/.config/kitty/xlin-opacity.conf.xlin-backup")" == "user kitty opacity" ]] || { echo "FAIL: Kitty opacity backup missing" >&2; exit 1; }
restore_generated_file "$HOME/.config/hypr/xlin-opacity.conf" >/dev/null
restore_generated_file "$HOME/.config/hypr/xlin-opacity.lua" >/dev/null
restore_generated_file "$HOME/.config/kitty/xlin-opacity.conf" >/dev/null
[[ "$(cat "$HOME/.config/hypr/xlin-opacity.conf")" == "user hypr opacity" ]] || { echo "FAIL: Hyprland opacity config not restored" >&2; exit 1; }
[[ "$(cat "$HOME/.config/hypr/xlin-opacity.lua")" == "user lua opacity" ]] || { echo "FAIL: Lua opacity config not restored" >&2; exit 1; }
[[ "$(cat "$HOME/.config/kitty/xlin-opacity.conf")" == "user kitty opacity" ]] || { echo "FAIL: Kitty opacity config not restored" >&2; exit 1; }

# Animation configs must preserve user files and remove only XLIN-created files.
printf 'user animation lua\n' >"$HOME/.config/hypr/xlin-anim.lua"
printf 'user animation conf\n' >"$HOME/.config/hypr/xlin-anim.conf"
write_anim smooth
[[ "$(cat "$HOME/.config/hypr/xlin-anim.lua.xlin-backup")" == "user animation lua" ]] || { echo "FAIL: Lua animation backup missing" >&2; exit 1; }
[[ "$(cat "$HOME/.config/hypr/xlin-anim.conf.xlin-backup")" == "user animation conf" ]] || { echo "FAIL: Hyprland animation backup missing" >&2; exit 1; }
restore_generated_file "$HOME/.config/hypr/xlin-anim.lua" >/dev/null
restore_generated_file "$HOME/.config/hypr/xlin-anim.conf" >/dev/null
[[ "$(cat "$HOME/.config/hypr/xlin-anim.lua")" == "user animation lua" ]] || { echo "FAIL: Lua animation config not restored" >&2; exit 1; }
[[ "$(cat "$HOME/.config/hypr/xlin-anim.conf")" == "user animation conf" ]] || { echo "FAIL: Hyprland animation config not restored" >&2; exit 1; }

rm -f "$HOME/.config/hypr/xlin-anim.lua" "$HOME/.config/hypr/xlin-anim.conf"
write_anim off
restore_generated_file "$HOME/.config/hypr/xlin-anim.lua" >/dev/null
restore_generated_file "$HOME/.config/hypr/xlin-anim.conf" >/dev/null
[[ ! -e "$HOME/.config/hypr/xlin-anim.lua" && ! -e "$HOME/.config/hypr/xlin-anim.conf" ]] || { echo "FAIL: XLIN-created animation configs were not removed" >&2; exit 1; }

# GTK settings must preserve existing files and remove settings files XLIN created.
mkdir -p "$HOME/.config/gtk-3.0"
printf '[Settings]\ngtk-theme-name=UserTheme\n' >"$HOME/.config/gtk-3.0/settings.ini"
C_GTK_SCHEME=prefer-dark
have() { return 1; } # Keep the test independent of the host's dconf/gsettings.
apply_gtk_theme dark
[[ "$(cat "$HOME/.config/gtk-3.0/settings.ini.xlin-backup")" == "$(printf '[Settings]\ngtk-theme-name=UserTheme\n')" ]] || { echo "FAIL: GTK3 settings backup missing" >&2; exit 1; }
[[ "$(grep -c '^gtk-application-prefer-dark-theme=1$' "$HOME/.config/gtk-3.0/settings.ini")" == 1 ]] || { echo "FAIL: GTK3 dark preference was not applied" >&2; exit 1; }
[[ -f "$HOME/.config/gtk-4.0/settings.ini.xlin-created" ]] || { echo "FAIL: GTK4 created-file marker missing" >&2; exit 1; }
restore_generated_file "$HOME/.config/gtk-3.0/settings.ini" >/dev/null
restore_generated_file "$HOME/.config/gtk-4.0/settings.ini" >/dev/null
[[ "$(cat "$HOME/.config/gtk-3.0/settings.ini")" == "$(printf '[Settings]\ngtk-theme-name=UserTheme\n')" ]] || { echo "FAIL: GTK3 settings were not restored" >&2; exit 1; }
[[ ! -e "$HOME/.config/gtk-4.0/settings.ini" ]] || { echo "FAIL: XLIN-created GTK4 settings file was not removed" >&2; exit 1; }

# The ML4W-style XLIN terminal hook must preserve a pre-existing 99-xlin file.
mkdir -p "$HOME/.config/bashrc"
printf 'user shell hook\n' >"$HOME/.config/bashrc/99-xlin"
track_generated_file "$HOME/.config/bashrc/99-xlin"
printf 'XLIN shell hook\n' >"$HOME/.config/bashrc/99-xlin"
restore_generated_file "$HOME/.config/bashrc/99-xlin" >/dev/null
[[ "$(cat "$HOME/.config/bashrc/99-xlin")" == "user shell hook" ]] || { echo "FAIL: existing 99-xlin hook was not restored" >&2; exit 1; }
rm -f "$HOME/.config/bashrc/99-xlin"
track_generated_file "$HOME/.config/bashrc/99-xlin"
printf 'XLIN shell hook\n' >"$HOME/.config/bashrc/99-xlin"
restore_generated_file "$HOME/.config/bashrc/99-xlin" >/dev/null
[[ ! -e "$HOME/.config/bashrc/99-xlin" ]] || { echo "FAIL: XLIN-created 99-xlin hook was not removed" >&2; exit 1; }

echo "Generated-file backup tests passed."
