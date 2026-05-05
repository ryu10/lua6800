# EDMON02 テスト中操作

1. eaglet02-firmware リポの edmon02/ ディレクトリで edmon02-lua6800.s を開発
2. make で `edmon02-lua6800-64k.bin` が生成される（されない場合は `make_lua6800_edmon.sh` を実行）
3. lua6800 リポの edmon02/ ディレクトリに `edmon02-lua6800-64k.bin` をコピー
4. lua6800 リポで `./run-m6800.sh <IMAGE>` を実行して、`<IMAGE>` に `edmon02/edmon02-lua6800-64k.bin` を指定してエミュレータを起動
5. エミュレータの画面に Edmon02 プロンプト `$` が表示されることを確認

注:

EDMON02 バイナリは実機ROMどおり `$F800-$FFFF` に配置されます。64k バイナリファイルは前方 62kB ぶん 0xff パディングされています。