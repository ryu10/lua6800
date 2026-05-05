# lua6800 -- moon6800 ベース 6800 SBC エミュレータ

いわゆる SBC6800 のような ACIA + RAM 構成をエミュレートします。

## 使い方

```bash
./run-m6800.sh <IMAGE>
```

`<IMAGE>` には64kBのバイナリファイルを指定してください。例えば mikbug（ACIA 対応版）のバイナリを `0xe000-` に含む 64kB バイナリを指定すると mikbug が動きます。

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