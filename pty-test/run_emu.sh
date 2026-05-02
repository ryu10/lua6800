#!/bin/bash

# 必要なツールの確認
if ! command -v socat &> /dev/null; then
    echo "Error: socat is not installed."
    echo "Ubuntu: sudo apt install socat"
    echo "macOS:  brew install socat"
    exit 1
fi

# 終了時に端末を元に戻す関数
# 掃除用関数
cleanup() {
    echo -e "\n[Cleanup] Killing processes and restoring terminal..."
    # socatとその子プロセス(Lua)をグループごとまとめてKill
    # マイナス記号をPIDに付けるとプロセスグループ全体に信号を送れる
    if [ ! -z "$SOCAT_PID" ]; then
        kill -TERM -"$SOCAT_PID" 2>/dev/null
    fi
    rm -f "$VTTY"
    stty sane
}

# 割り込み信号を受け取ったらcleanupを実行
# Ctrl-C や終了時に cleanup を実行
trap cleanup EXIT INT TERM

# 仮想デバイス名
VTTY="./vtty"

# 以前の残骸を削除
rm -f "$VTTY"

echo "Creating PTY at $VTTY..."

# socatでPTYとLuaプログラムを接続
# 修正ポイント: 
# 1. EXEC ではなく PTY を二つ作るか、EXEC に pty,raw を指定する
# 2. 内部の Lua プログラム側にも「端末としての属性」を強制する
# socat PTY,link="$VTTY",raw,echo=0 \
#       EXEC:"luajit acia_emu.lua",pty,raw,echo=0,stderr &
# socat PTY,link="$VTTY",raw,echo=0 \
#             EXEC:"luajit acia_emu.lua",pty,raw,echo=0 &
# 入出力ともに一切の加工を禁止する設定
socat PTY,link="$VTTY",raw,echo=0,isig=0,icanon=0 \
      EXEC:"luajit acia_emu.lua",pty,raw,echo=0,isig=0,icanon=0 &

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
