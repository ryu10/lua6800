#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LUA_BIN="${LUA_BIN:-${LUAJIT_BIN:-luajit}}"
LUA_ARGS="${LUA_ARGS:-}"
LUA_PID=""
CLEANED_UP=0

if ! command -v screen >/dev/null 2>&1; then
  echo "Error: screen is not installed."
  echo "Ubuntu: sudo apt install screen"
  echo "macOS:  brew install screen"
  exit 1
fi

if ! command -v "$LUA_BIN" >/dev/null 2>&1; then
  echo "Error: $LUA_BIN not found (set LUA_BIN or LUAJIT_BIN to override)."
  exit 1
fi

if [ ! -f "$ROOT_DIR/moon6800/cpu.lua" ]; then
  echo "Error: moon6800 submodule is missing."
  echo "Run: git submodule update --init --recursive"
  exit 1
fi

cleanup() {
  if [ "$CLEANED_UP" -eq 1 ]; then return; fi
  CLEANED_UP=1
  if [ -n "$LUA_PID" ] && kill -0 "$LUA_PID" 2>/dev/null; then
    kill -TERM "$LUA_PID" 2>/dev/null || true
  fi
  stty sane 2>/dev/null || true
}

trap cleanup EXIT INT TERM

cd "$ROOT_DIR"

STDERR_LOG=$(mktemp)

# shellcheck disable=SC2086
"$LUA_BIN" $LUA_ARGS main.lua "$@" 2>"$STDERR_LOG" &
LUA_PID=$!

PTY_PATH=""
for _ in $(seq 1 50); do
  if ! kill -0 "$LUA_PID" 2>/dev/null; then
    echo "Error: emulator exited early." >&2
    cat "$STDERR_LOG" >&2
    rm -f "$STDERR_LOG"
    exit 1
  fi
  PTY_PATH=$(grep -m1 "^PTY slave: " "$STDERR_LOG" 2>/dev/null | sed 's/^PTY slave: //' || true)
  if [ -n "$PTY_PATH" ]; then
    break
  fi
  sleep 0.1
done

rm -f "$STDERR_LOG"

if [ -z "$PTY_PATH" ]; then
  echo "Error: timed out waiting for PTY slave path." >&2
  exit 1
fi

echo "PTY slave: $PTY_PATH"
echo "Connecting with screen... (To exit: Ctrl+A, then K)"

screen "$PTY_PATH"
