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
source <(sed -n '/^track_generated_file() {/,/^}/p; /^restore_generated_file() {/,/^}/p' "$ROOT/bin/xlin")

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
printf 'user stylesheet\\n' >"$existing"
track_generated_file "$existing"
printf 'XLIN stylesheet\\n' >"$existing"
restore_generated_file "$existing" >/dev/null
[[ "$(cat "$existing")" == "user stylesheet" ]] || { echo "FAIL: original generated-file backup was not restored" >&2; exit 1; }
[[ ! -e "$existing.xlin-backup" ]] || { echo "FAIL: generated-file backup sidecar remained" >&2; exit 1; }

# Files created by XLIN must be removed when no original existed.
created="$TMP/config/created.css"
track_generated_file "$created"
printf 'XLIN-created file\\n' >"$created"
restore_generated_file "$created" >/dev/null
[[ ! -e "$created" && ! -e "$created.xlin-created" ]] || { echo "FAIL: XLIN-created file was not removed" >&2; exit 1; }

# Symlinks must be restored as symlinks, not flattened into regular files.
target="$TMP/config/target.css"
link="$TMP/config/link.css"
printf 'symlink target\\n' >"$target"
ln -s "$target" "$link"
track_generated_file "$link"
printf 'generated regular file\\n' >"$link"
restore_generated_file "$link" >/dev/null
[[ -L "$link" && "$(readlink "$link")" == "$target" ]] || { echo "FAIL: original symlink was not restored" >&2; exit 1; }

echo "Generated-file backup tests passed."
