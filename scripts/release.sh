#!/usr/bin/env bash
# Build xlin-<version>.tar.gz from this folder:  scripts/release.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ver="$(grep -m1 '^XLIN_VERSION=' bin/xlin | cut -d'"' -f2)"
name="xlin-$ver"
find . -name __pycache__ -type d -prune -exec rm -rf {} +
tar czf "../$name.tar.gz" --transform "s|^\.|$name|" --exclude=.git --exclude='*.tar.gz' .
echo "built ../$name.tar.gz"
