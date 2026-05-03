#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LUA_BIN="${LUA_BIN:-${LUAJIT_BIN:-luajit}}"
VTTY="$ROOT_DIR/vtty"
SOCAT_PID=""

if ! command -v socat >/dev/null 2>&1; then
  echo "Error: socat is not installed."
  echo "Ubuntu: sudo apt install socat"
  echo "macOS:  brew install socat"
  exit 1
fi

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
  echo -e "\n[Cleanup] Killing processes and restoring terminal..."
  if [ -n "$SOCAT_PID" ]; then
    kill -TERM -"$SOCAT_PID" 2>/dev/null || true
  fi
  rm -f "$VTTY"
  stty sane 2>/dev/null || true
}

trap cleanup EXIT INT TERM

rm -f "$VTTY"
cd "$ROOT_DIR"

echo "Creating PTY at $VTTY..."

socat PTY,link="$VTTY",raw,echo=0,isig=0,icanon=0 \
  EXEC:"$LUA_BIN main.lua",pty,raw,echo=0,isig=0,icanon=0 &

SOCAT_PID=$!

while [ ! -L "$VTTY" ]; do sleep 0.1; done

echo "PTY Ready. Connecting with screen..."
echo "To exit screen, press Ctrl+A, then K"

screen "$VTTY"
