# SBC6800 Lua

[SBC6800](http://www.amy.hi-ho.ne.jp/officetetsu/storage/sbc6800_techdata.pdf) のような ACIA + RAM 構成の MC6800 SBC をエミュレートします。

Lua ベースの mc6800 エミュレータ、[moon6800](https://github.com/tobiasvl/moon6800) が中核になっています。

## 使い方

```bash
./run-m6800.sh <IMAGE>
```

`<IMAGE>` には64kBのバイナリファイルを指定してください。例えば mikbug（ACIA 対応版）のバイナリを `0xf800-` に含む 64kB バイナリを指定すると mikbug が動きます。

なお現行ではバイナリファイルの 0xF800-0xFFFF の部分が ROM としてマップされるため、ROM イメージはこの範囲に配置されている必要があります。

`main.lua` を適宜変更して ROM/RAM/ACIA/TIMER をマッピングしてください。

例

```bash
./run-m6800.sh mikbug/mikbug.bin
```

端末環境として screen を使用しているため、終了するには `Ctrl-a k` を押してください。

## 仕様

moon6800 の CPU エミュレーションコードを一部補完したものを使用しています（`.gitmodule` 参照）。

I/O デバイスとして ACIA を実装しています。ACIA のレジスタは以下のアドレスにマップされています。

```lua
local ACIA_STATUS = 0x8018
local ACIA_DATA = 0x8019
```

## 確認済みおよび制限事項

- macos 動作確認済み
- linux 動作確認済み
- moon6800 由来の既知の TODO が残っている: サイクル数が未確定の命令、JSR 系で PC インクリメントのタイミングが怪しい箇所、HCF 命令のバリアント、PIA の IRQ 選択・周辺ピン動作、CPU 初期化時の I フラグなど。詳細は `moon6800/opcodes.lua`・`instructions.lua`・`pia.lua`・`cpu.lua` 内の `TODO` コメントを参照してください。
- ACIA モジュールが moon6800 のモジュールインターフェイスに合致していないため、モジュールモデルが中途半端になっている（io_pty モジュールは作り込んでいるが、ram.lua や eprom.lua と同じインターフェースを持っていない）。