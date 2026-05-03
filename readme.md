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

```lua
local ACIA_STATUS = 0x8018
local ACIA_DATA = 0x8019
```

## 制限事項

- macos 動作確認済み
- linux (ubuntu) では ACIA 改行変換未対応のため mikbug のようなソフトは動きません
