#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LUAJIT_BIN="${LUAJIT_BIN:-luajit}"

if ! command -v "$LUAJIT_BIN" >/dev/null 2>&1; then
  echo "error: luajit not found (set LUAJIT_BIN to override)" >&2
  exit 1
fi

cd "$ROOT_DIR"
exec "$LUAJIT_BIN" main.lua "$@"
