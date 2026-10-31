#!/usr/bin/env bash
# XLIN may stop hypridle / hyprsunset only when it started them itself (pid file + matching arguments).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'jobs -p | xargs -r kill 2>/dev/null; rm -rf "$TMP"' EXIT
export HOME="$TMP/home" STATE="$TMP/state"
mkdir -p "$HOME/.config/hypr" "$STATE" "$TMP/bin"
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok - $*"; }

# load just the two helpers from bin/xlin
eval "$(sed -n '/^owned_pid() {/,/^}/p;/^stop_owned() {/p' "$ROOT/bin/xlin")"

# stand-ins named like the real programs (the process name must match)
cp "$(command -v sleep)" "$TMP/bin/hypridle"
cp "$(command -v sleep)" "$TMP/bin/hyprsunset"
conf="$HOME/.config/hypr/xlin-hypridle.conf"
alive() { kill -0 "$1" 2>/dev/null; }

# 1. XLIN's own hypridle (recorded pid, XLIN's config) is found and stopped
( exec -a "hypridle -c $conf" "$TMP/bin/hypridle" 60 ) & own=$!
echo "$own" >"$STATE/hypridle.pid"; sleep 0.2
[[ "$(owned_pid hypridle)" == "$own" ]] || fail "own hypridle not recognised"
stop_owned hypridle; sleep 0.2
alive "$own" && fail "own hypridle was not stopped"
[[ ! -f "$STATE/hypridle.pid" ]] || fail "pid file left behind"
pass "own hypridle stopped"

# 2. a hypridle you started yourself (no pid file) is left alone
( exec -a "hypridle -c /home/me/mine.conf" "$TMP/bin/hypridle" 60 ) & mine=$!
sleep 0.2
owned_pid hypridle >/dev/null && fail "foreign hypridle looked like ours"
stop_owned hypridle
alive "$mine" || fail "foreign hypridle was killed"
pass "foreign hypridle untouched"

# 3. a stale pid file that now points at someone else's hypridle (pid reuse) is ignored
echo "$mine" >"$STATE/hypridle.pid"
owned_pid hypridle >/dev/null && fail "pid reuse was treated as ours"
stop_owned hypridle
alive "$mine" || fail "reused pid was killed"
[[ ! -f "$STATE/hypridle.pid" ]] || fail "stale pid file not removed"
pass "reused pid ignored"
kill "$mine" 2>/dev/null || true

# 4. hyprsunset: only with XLIN's arguments
( exec -a "hyprsunset -t 4000" "$TMP/bin/hyprsunset" 60 ) & sun=$!
echo "$sun" >"$STATE/hyprsunset.pid"; sleep 0.2
[[ "$(owned_pid hyprsunset)" == "$sun" ]] || fail "own hyprsunset not recognised"
stop_owned hyprsunset; sleep 0.2
alive "$sun" && fail "own hyprsunset not stopped"
( exec -a "hyprsunset --identity" "$TMP/bin/hyprsunset" 60 ) & other=$!
echo "$other" >"$STATE/hyprsunset.pid"; sleep 0.2
owned_pid hyprsunset >/dev/null && fail "foreign hyprsunset looked like ours"
pass "hyprsunset ownership"
echo "All process ownership tests passed."
