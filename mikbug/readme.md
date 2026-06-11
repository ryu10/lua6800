# mikbug for lua6800

## 起動法

```bash
./run-m6800.sh mikbug/mikbug.bin
```

## メモリマップ

`$0000-$7FFF` : RAM

`$8000-$8001` : ステップ割り込みタイマ。MIKBUG では未使用

`$8018-$8019` : ACIA ステータス・データレジスタ

`'9000-$F7FF` : RAM 2

`$F800-$FFFF` : ROM (MIKBUG)

## プログラム実行

Mikbug の `VAR = $F300` です。G コマンドの実行アドレスは `$F348`、`$F349` です。
