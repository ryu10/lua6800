#!/bin/bash

# 必要なツールの確認
if ! command -v socat &> /dev/null; then
    echo "Error: socat is not installed."
    echo "Ubuntu: sudo apt install socat"
    echo "macOS:  brew install socat"
    exit 1
fi

# 仮想デバイス名
VTTY="./vtty"

# 以前の残骸を削除
rm -f "$VTTY"

echo "Creating PTY at $VTTY..."

# socatでPTYとLuaプログラムを接続
# raw,echo=0 はOS側の余計な加工（エコーや行編集）を無効化する設定
socat PTY,link="$VTTY",raw,echo=0 EXEC:"luajit acia_emu.lua",pty,stderr &
SOCAT_PID=$!

# リンクが生成されるのを待機
while [ ! -L "$VTTY" ]; do sleep 0.1; done

echo "PTY Ready. Connecting with screen..."
echo "To exit screen, press Ctrl+A, then K"

# screenで接続
screen "$VTTY"

# screen終了後に後片付け
kill $SOCAT_PID
rm -f "$VTTY"
