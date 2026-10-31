#!/usr/bin/env bash
# Every program in bin/ must be installed by install.sh and update.sh and removed by `xlin uninstall`;
# every desktop entry and lib file too. Catches a new app that is forgotten in one of the three.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
for f in "$ROOT"/bin/xlin*; do
  [[ -f "$f" ]] || continue
  n="$(basename "$f")"
  grep -q "bin/$n\"" "$ROOT/install.sh" 2>/dev/null || grep -qE "\b$n\b" "$ROOT/install.sh" || { echo "FAIL: install.sh does not install $n"; fail=1; }
  grep -qE "(^|[ ])$n([ ;]|\$)|bin/$n\"" "$ROOT/update.sh" || { echo "FAIL: update.sh does not install $n"; fail=1; }
  sed -n '/^cmd_uninstall() {/,/^}/p' "$ROOT/bin/xlin" | grep -qE "/usr/local/bin/$n\b" || { echo "FAIL: uninstall does not remove $n"; fail=1; }
done
for f in "$ROOT"/lib/*; do
  [[ -f "$f" ]] || continue
  n="$(basename "$f")"
  grep -q "$n" "$ROOT/install.sh" && grep -q "$n" "$ROOT/update.sh" || { echo "FAIL: lib/$n missing in install.sh or update.sh"; fail=1; }
done
((fail)) && exit 1
echo "All install list tests passed."
