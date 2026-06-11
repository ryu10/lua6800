# SBC6800 Lua

[SBC6800](http://www.amy.hi-ho.ne.jp/officetetsu/storage/sbc6800_techdata.pdf) のような ACIA + RAM 構成の MC6800 SBC をエミュレートします。

Lua ベースの mc6800 エミュレータ、[moon6800](https://github.com/tobiasvl/moon6800) が中核になっています。

## 使い方

```bash
./run-m6800.sh <IMAGE>
```

`<IMAGE>` は 64 KB のバイナリファイルです。ただし ROM 領域に読み込まれるのは `0xF800-0xFFFF` の 2 KB のみ（バイナリファイルの末尾 2 KB）です。

終了するには `Ctrl-a k` を押してください。

## 例

EDMON02 を実行: 
```bash
./run-m6800.sh edmon02/edmon02.bin
``` 
MIKBUG を実行: 
```bash
./run-m6800.sh mikbug/mikbug.bin
``` 


## 仕様

moon6800 の CPU エミュレーションコードを一部補完したものを使用しています（`.gitmodule` 参照）。

I/O デバイスとして ACIA を実装しています。ACIA のレジスタは以下のアドレスにマップされています。

```lua
local ACIA_STATUS = 0x8018
local ACIA_DATA = 0x8019
```

ステップ動作用の割込みタイマを実装しています。[EDMON02](./edmon02/readme.md) で利用されます。

```lua
local TIMER_START_ADDR = 0x8000
local TIMER_RESET_ADDR = 0x8001
```

`main.lua` を適宜変更して ROM/RAM/ACIA/TIMER をリマップできます。

## 確認済みおよび制限事項

- macos 動作確認済み
- linux 動作確認済み
  
- moon6800 由来の既知の TODO が残っている: サイクル数が未確定の命令、JSR 系で PC インクリメントのタイミングが怪しい箇所、HCF 命令のバリアント、PIA の IRQ 選択・周辺ピン動作、CPU 初期化時の I フラグなど。詳細は `moon6800/opcodes.lua`・`instructions.lua`・`pia.lua`・`cpu.lua` 内の `TODO` コメントを参照してください。
- ACIA モジュールが moon6800 のモジュールインターフェイスに合致していないため、モジュールモデルが中途半端になっている（io_pty モジュールは作り込んでいるが、ram.lua や eprom.lua と同じインターフェースを持っていない）。
