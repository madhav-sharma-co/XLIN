#!/usr/bin/env bash
# Focused regression tests for the Hyprland compatibility helpers.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME/.config/hypr"

have() { command -v "$1" >/dev/null 2>&1; }
# shellcheck source=../lib/hyprland.sh
source "$ROOT/lib/hyprland.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok - $*"; }

# Version comparison must handle minor and patch versions numerically.
hypr_version() { printf '%s\n' "0.57.1"; }
hypr_ge 0.55 || fail "0.57.1 should be >= 0.55"
hypr_ge 0.57 || fail "0.57.1 should be >= 0.57"
if hypr_ge 0.58; then fail "0.57.1 must not be >= 0.58"; fi
pass "version comparisons"

# Config detection honors an existing Lua config and the 0.57+ default.
rm -f "$HOME/.config/hypr/hyprland.lua"
hypr_version() { printf '%s\n' "0.56.2"; }
_HYPR_MODE=""
[[ "$(hypr_mode)" == conf ]] || fail "older install without Lua file should use conf"
: >"$HOME/.config/hypr/hyprland.lua"
_HYPR_MODE=""
[[ "$(hypr_mode)" == lua ]] || fail "existing Lua config should use lua"
rm -f "$HOME/.config/hypr/hyprland.lua"
hypr_version() { printf '%s\n' "0.57.0"; }
_HYPR_MODE=""
[[ "$(hypr_mode)" == lua ]] || fail "0.57+ should use Lua"
pass "config mode detection"

# Legacy dispatches must retain their expected hyprctl arguments.
is_lua() { return 1; }
HYPR_CALLS="$TMP/hyprctl-calls"
hyprctl() { printf '%s\n' "$*" >>"$HYPR_CALLS"; }
: >"$HYPR_CALLS"
hy_move_silent 3 0xabc
hy_focus address:0xabc
hy_dpms off
hy_exit
grep -Fxq 'dispatch movetoworkspacesilent 3,address:0xabc' "$HYPR_CALLS" || fail "legacy move dispatch"
grep -Fxq 'dispatch focuswindow address:0xabc' "$HYPR_CALLS" || fail "legacy focus dispatch"
grep -Fxq 'dispatch dpms off' "$HYPR_CALLS" || fail "legacy DPMS dispatch"
grep -Fxq 'dispatch exit' "$HYPR_CALLS" || fail "legacy exit dispatch"
pass "legacy dispatch commands"

# Lua dispatches must preserve the structured API calls.
is_lua() { return 0; }
hy_lua() { printf '%s\n' "$1" >>"$HYPR_CALLS"; }
: >"$HYPR_CALLS"
hy_move_silent 3 0xabc
hy_focus address:0xabc
hy_dpms off
hy_exit
grep -Fq 'hl.dsp.window.move' "$HYPR_CALLS" || fail "Lua move dispatch"
grep -Fq 'hl.dsp.focus' "$HYPR_CALLS" || fail "Lua focus dispatch"
grep -Fq 'action = "disable"' "$HYPR_CALLS" || fail "Lua DPMS-off dispatch"
grep -Fq 'hl.dsp.exit()' "$HYPR_CALLS" || fail "Lua exit dispatch"
pass "Lua dispatch commands"

echo "All Hyprland helper tests passed."
