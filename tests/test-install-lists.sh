#!/usr/bin/env bash
# Every program in bin/ must be installed through scripts/files.sh (used by install.sh and update.sh) and removed by `xlin uninstall`;
# every desktop entry and lib file too. Catches a new app that is forgotten in one of the three.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
for f in "$ROOT"/bin/xlin*; do
  [[ -f "$f" ]] || continue
  n="$(basename "$f")"
  grep -qE "(^|[ (])$n([ )]|\$)" "$ROOT/scripts/files.sh" || { echo "FAIL: scripts/files.sh does not install $n"; fail=1; }
  sed -n '/^cmd_uninstall() {/,/^}/p' "$ROOT/bin/xlin" | grep -qE "/usr/local/bin/$n\b" || { echo "FAIL: uninstall does not remove $n"; fail=1; }
done
for f in "$ROOT"/lib/*; do
  [[ -f "$f" ]] || continue
  n="$(basename "$f")"
  grep -q "$n" "$ROOT/scripts/files.sh" || { echo "FAIL: lib/$n missing in scripts/files.sh"; fail=1; }
done
for sc in install.sh update.sh; do
  grep -q 'xlin_install_files' "$ROOT/$sc" || { echo "FAIL: $sc does not call xlin_install_files"; fail=1; }
done
for sc in install.sh update.sh scripts/deps.sh scripts/files.sh; do
  [[ -x "$ROOT/$sc" ]] || { echo "FAIL: $sc is not executable (chmod +x)"; fail=1; }
done
((fail)) && exit 1
echo "All install list tests passed."
