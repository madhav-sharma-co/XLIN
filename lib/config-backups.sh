#!/usr/bin/env bash
# Shared, idempotent backup helpers for user configuration files.

xlin_backup_once() {
  local file="$1" stamp="${2:-${STAMP:-}}"
  [[ -e "$file" || -L "$file" ]] || return 0
  if compgen -G "$file.bak-*" >/dev/null; then
    echo "   existing backup preserved for $file"
    return 0
  fi
  [[ -n "$stamp" ]] || stamp="$(date +%Y%m%d-%H%M%S)"
  cp -a -- "$file" "$file.bak-$stamp"
  echo "   backed up $file"
}

# Backup names contain sortable timestamps; cp -a preserves mtimes, so mtime
# order is not a reliable way to determine which backup was created first.
xlin_restore_oldest_backup() {
  local file="$1" backup
  backup="$(compgen -G "$file.bak-*" | LC_ALL=C sort | head -n1)"
  [[ -n "$backup" ]] || return 1
  cp -a -- "$backup" "$file" || return 1
  echo "restored $file"
}
