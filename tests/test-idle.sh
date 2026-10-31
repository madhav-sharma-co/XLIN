#!/usr/bin/env bash
# Auto-lock / sleep settings: the laptop sleeps after 5 min by default, and the screen locks before it sleeps.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" STATE="$TMP/state"; mkdir -p "$HOME" "$STATE"
fail() { echo "FAIL: $*" >&2; exit 1; }
eval "$(sed -n '/^idle_conf() /p;/^idle_sleep_minutes() /p;/^idle_write() {/,/^}/p' "$ROOT/bin/xlin")"
conf="$HOME/.config/hypr/xlin-hypridle.conf"
t() { grep -A2 "^listener" "$conf" | grep -E "timeout|on-timeout" | paste - - | tr -s ' \t' ' '; }

idle_write 5                                   # default: sleep after 5 min
grep -q 'timeout = 300' "$conf" && grep -q 'on-timeout = systemctl suspend' "$conf" || fail "default should suspend after 300 s"
lock=$(awk '/^    timeout = /{t=$3} /lock-session/{print t; exit}' "$conf")
[[ "$lock" -lt 300 ]] || fail "lock ($lock s) must come before sleep (300 s)"
grep -q 'xlin dpms off' "$conf" && fail "no screen-off step expected before sleep" || true

echo 10 >"$STATE/sleep_minutes"; idle_write 2
grep -q 'timeout = 600' "$conf" || fail "10 min sleep missing"
echo off >"$STATE/sleep_minutes"; idle_write 5
grep -q suspend "$conf" && fail "sleep off must not suspend" || true
grep -q 'xlin dpms off' "$conf" || fail "screen off expected when sleep is off"
echo 1 >"$STATE/sleep_minutes"; idle_write 30
grep -q 'timeout = 30$' "$conf" && grep -q 'timeout = 60$' "$conf" || fail "1 min sleep: lock at 30 s, sleep at 60 s"
echo bogus >"$STATE/sleep_minutes"; [[ "$(idle_sleep_minutes)" == 5 ]] || fail "invalid value falls back to 5"
echo "All idle tests passed."
