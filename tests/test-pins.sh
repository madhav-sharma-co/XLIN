#!/usr/bin/env bash
# Default pins: only Xlin-soft's own apps; Desktop has few, the Run Bar more, the Launcher the most.
# `xlin pins init` never touches pins the user already has.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
PINS="$TMP/pinned"; STATE="$TMP/state"; mkdir -p "$STATE"
eval "$(sed -n '/^RUNBAR_DEFAULT_PINS=/,/^pins_launcher_default()/p' "$ROOT/bin/xlin")"
dock_restart() { :; }
eval "$(sed -n '/^cmd_pins() {/,/^}/p' "$ROOT/bin/xlin")"

for id in "${RUNBAR_DEFAULT_PINS[@]}" "${LAUNCHER_DEFAULT_PINS[@]}"; do
  [[ "$id" == dev.xlin.* ]] || fail "$id is not an Xlin-soft app"
  [[ -f "$ROOT/config/applications/$id.desktop" ]] || fail "$id has no desktop file"
  grep -q '^NoDisplay=true' "$ROOT/config/applications/$id.desktop" && fail "$id is hidden from menus"
done
desk=$(python3 - "$ROOT/bin/xlin-desktop" <<'PY'
import re,sys
t=open(sys.argv[1]).read()
print(len(re.findall(r'"id": "dev\.xlin\.', t.split("DEFAULT = {")[1].split("}\n")[0])))
PY
)
r=${#RUNBAR_DEFAULT_PINS[@]}; l=${#LAUNCHER_DEFAULT_PINS[@]}
(( desk < r && r < l )) || fail "expected desktop($desk) < Run Bar($r) < Launcher($l)"
(( l <= 12 )) || fail "the Launcher shows at most 12 pins"

cmd_pins init
[[ "$(wc -l <"$PINS")" -eq "$r" && "$(wc -l <"$STATE/launcher_pins")" -eq "$l" ]] || fail "init did not write the defaults"
echo firefox >"$PINS"; cmd_pins init
[[ "$(cat "$PINS")" == firefox ]] || fail "init changed existing pins"
cmd_pins reset >/dev/null
[[ "$(wc -l <"$PINS")" -eq "$r" ]] || fail "reset did not restore the Run Bar pins"
echo "All pin tests passed."
