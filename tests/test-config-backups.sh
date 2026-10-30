#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# shellcheck source=../lib/config-backups.sh
source "$ROOT/lib/config-backups.sh"

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
