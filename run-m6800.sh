#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LUA_BIN="${LUA_BIN:-${LUAJIT_BIN:-luajit}}"
LUA_ARGS="${LUA_ARGS:-}"
M6800_ROM="${M6800_ROM:-${1:-}}"
export M6800_ROM
VTTY="$ROOT_DIR/vtty"
SOCAT_PID=""
LUA_PID=""
CLEANED_UP=0

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

terminate_pid() {
  local pid="$1"
  if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    return
  fi

  kill -TERM "$pid" 2>/dev/null || true
  for _ in $(seq 1 20); do
    if ! kill -0 "$pid" 2>/dev/null; then
      return
    fi
    sleep 0.05
  done

  kill -KILL "$pid" 2>/dev/null || true
}

cleanup() {
  if [ "$CLEANED_UP" -eq 1 ]; then
    return
  fi
  CLEANED_UP=1

  echo -e "\n[Cleanup] Killing processes and restoring terminal..."

  if [ -n "$SOCAT_PID" ] && kill -0 "$SOCAT_PID" 2>/dev/null; then
    LUA_PID="$(pgrep -P "$SOCAT_PID" 2>/dev/null | head -n 1 || true)"
  fi

  if [ -n "$LUA_PID" ]; then
    terminate_pid "$LUA_PID"
  fi
  if [ -n "$SOCAT_PID" ]; then
    terminate_pid "$SOCAT_PID"
  fi

  rm -f "$VTTY"
  stty sane 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Kill stale instances attached to this launcher's PTY link.
for pid in $(pgrep -f "socat .*link=$VTTY" 2>/dev/null || true); do
  terminate_pid "$pid"
done

# Best-effort cleanup for screen sessions bound to this PTY path.
pkill -TERM -f "screen $VTTY|SCREEN $VTTY" 2>/dev/null || true

rm -f "$VTTY"
cd "$ROOT_DIR"

echo "Creating PTY at $VTTY..."

socat PTY,link="$VTTY",wait-slave,raw,echo=0,isig=0,icanon=0 \
  EXEC:"$LUA_BIN $LUA_ARGS main.lua",pty,raw,echo=0,isig=0,icanon=0 &

SOCAT_PID=$!
LUA_PID="$(pgrep -P "$SOCAT_PID" 2>/dev/null | head -n 1 || true)"

while [ ! -L "$VTTY" ]; do sleep 0.1; done

echo "PTY Ready. Connecting with screen..."
echo "To exit screen, press Ctrl+A, then K"

screen "$VTTY"
