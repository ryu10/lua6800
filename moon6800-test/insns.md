# MC6800 命令セット参照

出典: https://www.8bit-era.cz/6800.html  
テスト実装用の詳細参照資料。各エントリはニモニック＋アドレッシングモードで一意。

## フラグ表記

| 記号 | 意味 |
|------|------|
| `*`  | 演算結果により変化 |
| `0`  | 常にクリア |
| `1`  | 常にセット |
| `−`  | 影響なし |

Lua コードでのフラグ名: `c` / `z` / `n` / `v` / `h` / `i`  
8bit-era.cz での列名: C / Z / S / O / Ac / I

---

## ABA (INH) — Add B to A

`$1B` · 1 byte · 2 cycles

A ← A + B

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`*` I:`−`

- C: 加算結果がビット7からキャリーを生じた場合 (result > 0xFF)
- Z: (A + B) & 0xFF == 0
- N: 結果 bit7 == 1
- V: 符号付きオーバーフロー (正+正=負 または 負+負=正)
- H: bit3 から bit4 へのキャリー

---

## ADC A (IMM) — Add with Carry to A, Immediate

`$89` · 2 bytes · 2 cycles

A ← A + imm8 + C  
オペランド: 即値 1 バイト (imm8)

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`*` I:`−`

- C: 結果 > 0xFF
- Z: (A + imm8 + C) & 0xFF == 0
- N: 結果 bit7 == 1
- V: 符号付きオーバーフロー
- H: bit3 から bit4 へのキャリー

## ADC A (DIR)
`$99` · 2 bytes · 3 cycles | A ← A + mem[addr8] + C | Flags: ADC A (IMM) と同一

## ADC A (IDX)
`$A9` · 2 bytes · 5 cycles | A ← A + mem[X + offset8] + C | 実効アドレス = X + offset8 | Flags: ADC A (IMM) と同一

## ADC A (EXT)
`$B9` · 3 bytes · 4 cycles | A ← A + mem[addr16] + C | Flags: ADC A (IMM) と同一

## ADC B (IMM)
`$C9` · 2 bytes · 2 cycles | B ← B + imm8 + C | Flags: ADC A (IMM) と同一 (対象レジスタが B)

## ADC B (DIR)
`$D9` · 2 bytes · 3 cycles | B ← B + mem[addr8] + C | Flags: ADC A (IMM) と同一

## ADC B (IDX)
`$E9` · 2 bytes · 5 cycles | B ← B + mem[X + offset8] + C | Flags: ADC A (IMM) と同一

## ADC B (EXT)
`$F9` · 3 bytes · 4 cycles | B ← B + mem[addr16] + C | Flags: ADC A (IMM) と同一

---

## ADD A (IMM) — Add to A, Immediate

`$8B` · 2 bytes · 2 cycles

A ← A + imm8  
オペランド: 即値 1 バイト

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`*` I:`−`

- C: 結果 > 0xFF
- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: 符号付きオーバーフロー
- H: bit3 から bit4 へのキャリー

## ADD A (DIR)
`$9B` · 2 bytes · 3 cycles | A ← A + mem[addr8] | Flags: ADD A (IMM) と同一

## ADD A (IDX)
`$AB` · 2 bytes · 5 cycles | A ← A + mem[X + offset8] | Flags: ADD A (IMM) と同一

## ADD A (EXT)
`$BB` · 3 bytes · 4 cycles | A ← A + mem[addr16] | Flags: ADD A (IMM) と同一

## ADD B (IMM)
`$CB` · 2 bytes · 2 cycles | B ← B + imm8 | Flags: ADD A (IMM) と同一

## ADD B (DIR)
`$DB` · 2 bytes · 3 cycles | B ← B + mem[addr8] | Flags: ADD A (IMM) と同一

## ADD B (IDX)
`$EB` · 2 bytes · 5 cycles | B ← B + mem[X + offset8] | Flags: ADD A (IMM) と同一

## ADD B (EXT)
`$FB` · 3 bytes · 4 cycles | B ← B + mem[addr16] | Flags: ADD A (IMM) と同一

---

## AND A (IMM) — Logical AND with A, Immediate

`$84` · 2 bytes · 2 cycles

A ← A & imm8  
オペランド: 即値 1 バイト

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: 常にクリア

## AND A (DIR)
`$94` · 2 bytes · 3 cycles | A ← A & mem[addr8] | Flags: AND A (IMM) と同一

## AND A (IDX)
`$A4` · 2 bytes · 5 cycles | A ← A & mem[X + offset8] | Flags: AND A (IMM) と同一

## AND A (EXT)
`$B4` · 3 bytes · 4 cycles | A ← A & mem[addr16] | Flags: AND A (IMM) と同一

## AND B (IMM)
`$C4` · 2 bytes · 2 cycles | B ← B & imm8 | Flags: AND A (IMM) と同一

## AND B (DIR)
`$D4` · 2 bytes · 3 cycles | B ← B & mem[addr8] | Flags: AND A (IMM) と同一

## AND B (IDX)
`$E4` · 2 bytes · 5 cycles | B ← B & mem[X + offset8] | Flags: AND A (IMM) と同一

## AND B (EXT)
`$F4` · 3 bytes · 4 cycles | B ← B & mem[addr16] | Flags: AND A (IMM) と同一

---

## ASL A (ACC) — Arithmetic Shift Left, A

`$48` · 1 byte · 2 cycles

C ← [7←6←5←4←3←2←1←0←0] (bit0 ← 0)

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: シフト前の bit7
- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: C XOR N (シフト後。符号変化の検出)

## ASL B (ACC)
`$58` · 1 byte · 2 cycles | B を左シフト | Flags: ASL A と同一

## ASL (IDX)
`$68` · 2 bytes · 7 cycles | mem[X + offset8] を左シフト | Flags: ASL A と同一

## ASL (EXT)
`$78` · 3 bytes · 6 cycles | mem[addr16] を左シフト | Flags: ASL A と同一

---

## ASR A (ACC) — Arithmetic Shift Right, A

`$47` · 1 byte · 2 cycles

[7→7→6→5→4→3→2→1→0] → C  (bit7 は保持、符号拡張シフト)

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: シフト前の bit0
- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1 (元の bit7 と同じ)
- V: C XOR N (シフト後)

## ASR B (ACC)
`$57` · 1 byte · 2 cycles | B を算術右シフト | Flags: ASR A と同一

## ASR (IDX)
`$67` · 2 bytes · 7 cycles | mem[X + offset8] を算術右シフト | Flags: ASR A と同一

## ASR (EXT)
`$77` · 3 bytes · 6 cycles | mem[addr16] を算術右シフト | Flags: ASR A と同一

---

## BCC (REL) — Branch if Carry Clear

`$24` · 2 bytes · 4 cycles

C == 0 なら PC ← PC + 2 + sign_extend(offset8)  
オペランド: 符号付き 8 ビットオフセット (−126〜+129 の範囲)

**Flags:** 全て影響なし  
**分岐条件:** `C == 0`

## BCS (REL) — Branch if Carry Set
`$25` · 2 bytes · 4 cycles | **分岐条件:** `C == 1` | Flags: 影響なし

## BEQ (REL) — Branch if Equal (Zero)
`$27` · 2 bytes · 4 cycles | **分岐条件:** `Z == 1` | Flags: 影響なし

## BGE (REL) — Branch if Greater or Equal (signed)
`$2C` · 2 bytes · 4 cycles | **分岐条件:** `N == V` (N XOR V == 0) | Flags: 影響なし

## BGT (REL) — Branch if Greater Than (signed)
`$2E` · 2 bytes · 4 cycles | **分岐条件:** `(not Z) AND (N == V)` | Flags: 影響なし

## BHI (REL) — Branch if Higher (unsigned)
`$22` · 2 bytes · 4 cycles | **分岐条件:** `(not C) AND (not Z)` (C OR Z == 0) | Flags: 影響なし

---

## BIT A (IMM) — Bit Test A, Immediate

`$85` · 2 bytes · 2 cycles

A & imm8 — 結果はレジスタに書き込まない、フラグのみ変化  
オペランド: 即値 1 バイト

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: (A & imm8) & 0xFF == 0
- N: (A & imm8) bit7 == 1
- V: 常にクリア

## BIT A (DIR)
`$95` · 2 bytes · 3 cycles | A & mem[addr8] | Flags: BIT A (IMM) と同一

## BIT A (IDX)
`$A5` · 2 bytes · 5 cycles | A & mem[X + offset8] | Flags: BIT A (IMM) と同一

## BIT A (EXT)
`$B5` · 3 bytes · 4 cycles | A & mem[addr16] | Flags: BIT A (IMM) と同一

## BIT B (IMM)
`$C5` · 2 bytes · 2 cycles | B & imm8 | Flags: BIT A (IMM) と同一

## BIT B (DIR)
`$D5` · 2 bytes · 3 cycles | B & mem[addr8] | Flags: BIT A (IMM) と同一

## BIT B (IDX)
`$E5` · 2 bytes · 5 cycles | B & mem[X + offset8] | Flags: BIT A (IMM) と同一

## BIT B (EXT)
`$F5` · 3 bytes · 4 cycles | B & mem[addr16] | Flags: BIT A (IMM) と同一

---

## BLE (REL) — Branch if Less or Equal (signed)
`$2F` · 2 bytes · 4 cycles | **分岐条件:** `Z OR (N != V)` | Flags: 影響なし

## BLS (REL) — Branch if Lower or Same (unsigned)
`$23` · 2 bytes · 4 cycles | **分岐条件:** `C OR Z` | Flags: 影響なし

## BLT (REL) — Branch if Less Than (signed)
`$2D` · 2 bytes · 4 cycles | **分岐条件:** `N != V` (N XOR V == 1) | Flags: 影響なし

## BMI (REL) — Branch if Minus
`$2B` · 2 bytes · 4 cycles | **分岐条件:** `N == 1` | Flags: 影響なし

## BNE (REL) — Branch if Not Equal
`$26` · 2 bytes · 4 cycles | **分岐条件:** `Z == 0` | Flags: 影響なし

## BPL (REL) — Branch if Plus
`$2A` · 2 bytes · 4 cycles | **分岐条件:** `N == 0` | Flags: 影響なし

## BRA (REL) — Branch Always
`$20` · 2 bytes · 4 cycles | 無条件分岐 | Flags: 影響なし

## BSR (REL) — Branch to Subroutine

`$8D` · 2 bytes · 8 cycles

mem[SP] ← PC_lo, mem[SP−1] ← PC_hi, SP ← SP − 2, PC ← PC + 2 + sign_extend(offset8)

**Flags:** 影響なし  
**スタック変化:** SP は 2 減る。保存される PC は BSR の次の命令アドレス（オフセットバイトの次）。

## BVC (REL) — Branch if Overflow Clear
`$28` · 2 bytes · 4 cycles | **分岐条件:** `V == 0` | Flags: 影響なし

## BVS (REL) — Branch if Overflow Set
`$29` · 2 bytes · 4 cycles | **分岐条件:** `V == 1` | Flags: 影響なし

---

## CBA (INH) — Compare Accumulators

`$11` · 1 byte · 2 cycles

A − B — 結果はレジスタに書き込まない、フラグのみ変化

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: A < B (unsigned borrow)
- Z: A == B
- N: (A − B) bit7 == 1
- V: 符号付きオーバーフロー

---

## CLC (INH) — Clear Carry
`$0C` · 1 byte · 2 cycles | C ← 0 | **Flags:** C:`0` その他影響なし

## CLI (INH) — Clear Interrupt Mask
`$0E` · 1 byte · 2 cycles | I ← 0 (割り込み許可) | **Flags:** I:`0` その他影響なし

## CLR A (ACC) — Clear A

`$4F` · 1 byte · 2 cycles

A ← 0

**Flags:** C:`0` Z:`1` N:`0` V:`0` H:`−` I:`−`

## CLR B (ACC)
`$5F` · 1 byte · 2 cycles | B ← 0 | Flags: CLR A と同一

## CLR (IDX)
`$6F` · 2 bytes · 7 cycles | mem[X + offset8] ← 0 | Flags: CLR A と同一

## CLR (EXT)
`$7F` · 3 bytes · 6 cycles | mem[addr16] ← 0 | Flags: CLR A と同一

## CLV (INH) — Clear Overflow
`$0A` · 1 byte · 2 cycles | V ← 0 | **Flags:** V:`0` その他影響なし

---

## CMP A (IMM) — Compare A with Memory, Immediate

`$81` · 2 bytes · 2 cycles

A − imm8 — 結果はレジスタに書き込まない  
オペランド: 即値 1 バイト

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: A < imm8 (unsigned borrow)
- Z: A == imm8
- N: (A − imm8) bit7 == 1
- V: 符号付きオーバーフロー

## CMP A (DIR)
`$91` · 2 bytes · 3 cycles | A − mem[addr8] | Flags: CMP A (IMM) と同一

## CMP A (IDX)
`$A1` · 2 bytes · 5 cycles | A − mem[X + offset8] | Flags: CMP A (IMM) と同一

## CMP A (EXT)
`$B1` · 3 bytes · 4 cycles | A − mem[addr16] | Flags: CMP A (IMM) と同一

## CMP B (IMM)
`$C1` · 2 bytes · 2 cycles | B − imm8 | Flags: CMP A (IMM) と同一

## CMP B (DIR)
`$D1` · 2 bytes · 3 cycles | B − mem[addr8] | Flags: CMP A (IMM) と同一

## CMP B (IDX)
`$E1` · 2 bytes · 5 cycles | B − mem[X + offset8] | Flags: CMP A (IMM) と同一

## CMP B (EXT)
`$F1` · 3 bytes · 4 cycles | B − mem[addr16] | Flags: CMP A (IMM) と同一

---

## COM A (ACC) — Complement A (1's complement)

`$43` · 1 byte · 2 cycles

A ← $FF − A  (全ビット反転)

**Flags:** C:`1` Z:`*` N:`*` V:`0` H:`−` I:`−`

- C: 常にセット
- Z: 結果 == 0 ($FF の場合のみ、つまり元が $FF)
- N: 結果 bit7 == 1
- V: 常にクリア

## COM B (ACC)
`$53` · 1 byte · 2 cycles | B ← $FF − B | Flags: COM A と同一

## COM (IDX)
`$63` · 2 bytes · 7 cycles | mem[X + offset8] ← $FF − mem[X + offset8] | Flags: COM A と同一

## COM (EXT)
`$73` · 3 bytes · 6 cycles | mem[addr16] ← $FF − mem[addr16] | Flags: COM A と同一

---

## CPX (IMM) — Compare Index Register, Immediate

`$8C` · 3 bytes · 3 cycles

X − imm16 — フラグのみ変化 (16ビット比較)  
オペランド: 16 ビット即値 (big-endian, 2 バイト)

**Flags:** C:`−` Z:`*` N:`*` V:`*` H:`−` I:`−`

- Z: X == imm16
- N: (X − imm16) bit15 == 1
- V: 16 ビット符号付きオーバーフロー

## CPX (DIR)
`$9C` · 2 bytes · 4 cycles | X − {mem[addr8], mem[addr8+1]} | Flags: CPX (IMM) と同一

## CPX (IDX)
`$AC` · 2 bytes · 6 cycles | X − {mem[X+offset8], mem[X+offset8+1]} | Flags: CPX (IMM) と同一

## CPX (EXT)
`$BC` · 3 bytes · 5 cycles | X − {mem[addr16], mem[addr16+1]} | Flags: CPX (IMM) と同一

---

## DAA (INH) — Decimal Adjust A

`$19` · 1 byte · 2 cycles

BCD 補正: ADD / ADC 後に Accumulator A の内容を BCD 表現に修正する。  
H フラグ (bit3→bit4 のキャリー) および C フラグを参照して補正値を決定する。

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

**注意:** 現行 Lua 実装は未実装 (TODO)。

---

## DEC A (ACC) — Decrement A

`$4A` · 1 byte · 2 cycles

A ← A − 1

**Flags:** C:`−` Z:`*` N:`*` V:`*` H:`−` I:`−`

- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: 元の値が $80 の場合セット ($80 − 1 = $7F、負→正のオーバーフロー)

## DEC B (ACC)
`$5A` · 1 byte · 2 cycles | B ← B − 1 | Flags: DEC A と同一

## DEC (IDX)
`$6A` · 2 bytes · 7 cycles | mem[X + offset8] ← mem[X + offset8] − 1 | Flags: DEC A と同一

## DEC (EXT)
`$7A` · 3 bytes · 6 cycles | mem[addr16] ← mem[addr16] − 1 | Flags: DEC A と同一

---

## DES (INH) — Decrement Stack Pointer
`$34` · 1 byte · 4 cycles | SP ← SP − 1 | **Flags:** 影響なし

## DEX (INH) — Decrement Index Register

`$09` · 1 byte · 4 cycles

X ← X − 1

**Flags:** C:`−` Z:`*` N:`−` V:`−` H:`−` I:`−`

- Z: X − 1 == 0 (16 ビット)

---

## EOR A (IMM) — Exclusive OR with A, Immediate

`$88` · 2 bytes · 2 cycles

A ← A XOR imm8  
オペランド: 即値 1 バイト

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: 常にクリア

## EOR A (DIR)
`$98` · 2 bytes · 3 cycles | A ← A XOR mem[addr8] | Flags: EOR A (IMM) と同一

## EOR A (IDX)
`$A8` · 2 bytes · 5 cycles | A ← A XOR mem[X + offset8] | Flags: EOR A (IMM) と同一

## EOR A (EXT)
`$B8` · 3 bytes · 4 cycles | A ← A XOR mem[addr16] | Flags: EOR A (IMM) と同一

## EOR B (IMM)
`$C8` · 2 bytes · 2 cycles | B ← B XOR imm8 | Flags: EOR A (IMM) と同一

## EOR B (DIR)
`$D8` · 2 bytes · 3 cycles | B ← B XOR mem[addr8] | Flags: EOR A (IMM) と同一

## EOR B (IDX)
`$E8` · 2 bytes · 5 cycles | B ← B XOR mem[X + offset8] | Flags: EOR A (IMM) と同一

## EOR B (EXT)
`$F8` · 3 bytes · 4 cycles | B ← B XOR mem[addr16] | Flags: EOR A (IMM) と同一

---

## INC A (ACC) — Increment A

`$4C` · 1 byte · 2 cycles

A ← A + 1

**Flags:** C:`−` Z:`*` N:`*` V:`*` H:`−` I:`−`

- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: 元の値が $7F の場合セット ($7F + 1 = $80、正→負のオーバーフロー)
- **C は影響を受けない** (仕様。現行 Lua 実装は Z と同値にしており要修正)

## INC B (ACC)
`$5C` · 1 byte · 2 cycles | B ← B + 1 | Flags: INC A と同一

## INC (IDX)
`$6C` · 2 bytes · 7 cycles | mem[X + offset8] ← mem[X + offset8] + 1 | Flags: INC A と同一

## INC (EXT)
`$7C` · 3 bytes · 6 cycles | mem[addr16] ← mem[addr16] + 1 | Flags: INC A と同一

---

## INS (INH) — Increment Stack Pointer
`$31` · 1 byte · 4 cycles | SP ← SP + 1 | **Flags:** 影響なし

## INX (INH) — Increment Index Register

`$08` · 1 byte · 4 cycles

X ← X + 1

**Flags:** C:`−` Z:`*` N:`−` V:`−` H:`−` I:`−`

- Z: X + 1 == 0 (16 ビット、$FFFF + 1 = 0 の場合)

---

## JMP (IDX) — Jump, Indexed

`$6E` · 2 bytes · 4 cycles

PC ← X + offset8  
オペランド: 8 ビットオフセット

**Flags:** 影響なし

## JMP (EXT) — Jump, Extended
`$7E` · 3 bytes · 3 cycles | PC ← addr16 | **Flags:** 影響なし

---

## JSR (IDX) — Jump to Subroutine, Indexed

`$AD` · 2 bytes · 8 cycles

mem[SP] ← PC_lo, mem[SP−1] ← PC_hi, SP ← SP − 2, PC ← X + offset8  
オペランド: 8 ビットオフセット

**Flags:** 影響なし  
**スタック変化:** SP は 2 減る。保存される戻りアドレスは JSR 次命令のアドレス。

## JSR (EXT) — Jump to Subroutine, Extended
`$BD` · 3 bytes · 9 cycles | PC ← addr16, 戻りアドレスをスタックに保存 | Flags: 影響なし

---

## LDA A (IMM) — Load A, Immediate

`$86` · 2 bytes · 2 cycles

A ← imm8  
オペランド: 即値 1 バイト

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: imm8 == 0
- N: imm8 bit7 == 1
- V: 常にクリア

## LDA A (DIR)
`$96` · 2 bytes · 3 cycles | A ← mem[addr8] | Flags: LDA A (IMM) と同一

## LDA A (IDX)
`$A6` · 2 bytes · 5 cycles | A ← mem[X + offset8] | Flags: LDA A (IMM) と同一

## LDA A (EXT)
`$B6` · 3 bytes · 4 cycles | A ← mem[addr16] | Flags: LDA A (IMM) と同一

## LDA B (IMM)
`$C6` · 2 bytes · 2 cycles | B ← imm8 | Flags: LDA A (IMM) と同一

## LDA B (DIR)
`$D6` · 2 bytes · 3 cycles | B ← mem[addr8] | Flags: LDA A (IMM) と同一

## LDA B (IDX)
`$E6` · 2 bytes · 5 cycles | B ← mem[X + offset8] | Flags: LDA A (IMM) と同一

## LDA B (EXT)
`$F6` · 3 bytes · 4 cycles | B ← mem[addr16] | Flags: LDA A (IMM) と同一

---

## LDS (IMM) — Load Stack Pointer, Immediate

`$8E` · 3 bytes · 3 cycles

SP ← imm16  
オペランド: 16 ビット即値 (big-endian, 2 バイト)

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: imm16 == 0
- N: imm16 bit15 == 1
- V: 常にクリア

## LDS (DIR)
`$9E` · 2 bytes · 4 cycles | SP ← {mem[addr8], mem[addr8+1]} | Flags: LDS (IMM) と同一

## LDS (IDX)
`$AE` · 2 bytes · 6 cycles | SP ← {mem[X+offset8], mem[X+offset8+1]} | Flags: LDS (IMM) と同一

## LDS (EXT)
`$BE` · 3 bytes · 5 cycles | SP ← {mem[addr16], mem[addr16+1]} | Flags: LDS (IMM) と同一

---

## LDX (IMM) — Load Index Register, Immediate

`$CE` · 3 bytes · 3 cycles

X ← imm16  
オペランド: 16 ビット即値 (big-endian, 2 バイト)

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: imm16 == 0
- N: imm16 bit15 == 1
- V: 常にクリア

## LDX (DIR)
`$DE` · 2 bytes · 4 cycles | X ← {mem[addr8], mem[addr8+1]} | Flags: LDX (IMM) と同一

## LDX (IDX)
`$EE` · 2 bytes · 6 cycles | X ← {mem[X+offset8], mem[X+offset8+1]} | Flags: LDX (IMM) と同一

## LDX (EXT)
`$FE` · 3 bytes · 5 cycles | X ← {mem[addr16], mem[addr16+1]} | Flags: LDX (IMM) と同一

---

## LSR A (ACC) — Logical Shift Right, A

`$44` · 1 byte · 2 cycles

0 → [7→6→5→4→3→2→1→0] → C  (bit7 ← 0)

**Flags:** C:`*` Z:`*` N:`0` V:`*` H:`−` I:`−`

- C: シフト前の bit0
- Z: 結果 & 0xFF == 0
- N: 常に 0 (bit7 に 0 が入る)
- V: N XOR C = C (N は常に 0 なので V はシフト後の C と同値)

## LSR B (ACC)
`$54` · 1 byte · 2 cycles | B を論理右シフト | Flags: LSR A と同一

## LSR (IDX)
`$64` · 2 bytes · 7 cycles | mem[X + offset8] を論理右シフト | Flags: LSR A と同一

## LSR (EXT)
`$74` · 3 bytes · 6 cycles | mem[addr16] を論理右シフト | Flags: LSR A と同一

---

## NEG A (ACC) — Negate A (2's complement)

`$40` · 1 byte · 2 cycles

A ← 0 − A

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: A != 0 の場合セット (0 − 0 = 0 のみキャリーなし)
- Z: 結果 & 0xFF == 0 (A == 0 の場合のみ)
- N: 結果 bit7 == 1
- V: 元の値が $80 の場合セット (0 − $80 = $80、符号付きオーバーフロー)

## NEG B (ACC)
`$50` · 1 byte · 2 cycles | B ← 0 − B | Flags: NEG A と同一

## NEG (IDX)
`$60` · 2 bytes · 7 cycles | mem[X + offset8] ← 0 − mem[X + offset8] | Flags: NEG A と同一

## NEG (EXT)
`$70` · 3 bytes · 6 cycles | mem[addr16] ← 0 − mem[addr16] | Flags: NEG A と同一

---

## NOP (INH) — No Operation
`$01` · 1 byte · 2 cycles | 何もしない | **Flags:** 影響なし

---

## ORA A (IMM) — Logical OR with A, Immediate

`$8A` · 2 bytes · 2 cycles

A ← A | imm8  
オペランド: 即値 1 バイト

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: 常にクリア

## ORA A (DIR)
`$9A` · 2 bytes · 3 cycles | A ← A | mem[addr8] | Flags: ORA A (IMM) と同一

## ORA A (IDX)
`$AA` · 2 bytes · 5 cycles | A ← A | mem[X + offset8] | Flags: ORA A (IMM) と同一

## ORA A (EXT)
`$BA` · 3 bytes · 4 cycles | A ← A | mem[addr16] | Flags: ORA A (IMM) と同一

## ORA B (IMM)
`$CA` · 2 bytes · 2 cycles | B ← B | imm8 | Flags: ORA A (IMM) と同一

## ORA B (DIR)
`$DA` · 2 bytes · 3 cycles | B ← B | mem[addr8] | Flags: ORA A (IMM) と同一

## ORA B (IDX)
`$EA` · 2 bytes · 5 cycles | B ← B | mem[X + offset8] | Flags: ORA A (IMM) と同一

## ORA B (EXT)
`$FA` · 3 bytes · 4 cycles | B ← B | mem[addr16] | Flags: ORA A (IMM) と同一

---

## PSH A (ACC) — Push A to Stack

`$36` · 1 byte · 4 cycles

mem[SP] ← A, SP ← SP − 1

**Flags:** 影響なし

## PSH B (ACC) — Push B to Stack
`$37` · 1 byte · 4 cycles | mem[SP] ← B, SP ← SP − 1 | **Flags:** 影響なし

## PUL A (ACC) — Pull A from Stack

`$32` · 1 byte · 4 cycles

SP ← SP + 1, A ← mem[SP]

**Flags:** 影響なし

## PUL B (ACC) — Pull B from Stack
`$33` · 1 byte · 4 cycles | SP ← SP + 1, B ← mem[SP] | **Flags:** 影響なし

---

## ROL A (ACC) — Rotate Left through Carry, A

`$49` · 1 byte · 2 cycles

C ← [7←6←5←4←3←2←1←0←C]  (旧 C が bit0 へ、旧 bit7 が C へ)

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: シフト前の bit7
- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: N XOR C (シフト後)

## ROL B (ACC)
`$59` · 1 byte · 2 cycles | B を左ローテート | Flags: ROL A と同一

## ROL (IDX)
`$69` · 2 bytes · 7 cycles | mem[X + offset8] を左ローテート | Flags: ROL A と同一

## ROL (EXT)
`$79` · 3 bytes · 6 cycles | mem[addr16] を左ローテート | Flags: ROL A と同一

---

## ROR A (ACC) — Rotate Right through Carry, A

`$46` · 1 byte · 2 cycles

[C→7→6→5→4→3→2→1→0→C]  (旧 C が bit7 へ、旧 bit0 が C へ)

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: シフト前の bit0
- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1 (旧 C の値)
- V: N XOR C (シフト後)

## ROR B (ACC)
`$56` · 1 byte · 2 cycles | B を右ローテート | Flags: ROR A と同一

## ROR (IDX)
`$66` · 2 bytes · 7 cycles | mem[X + offset8] を右ローテート | Flags: ROR A と同一

## ROR (EXT)
`$76` · 3 bytes · 6 cycles | mem[addr16] を右ローテート | Flags: ROR A と同一

---

## RTI (INH) — Return from Interrupt

`$3B` · 1 byte · 10 cycles

スタックから全レジスタを復元:  
SR ← mem[SP+1], B ← mem[SP+2], A ← mem[SP+3],  
X ← {mem[SP+4], mem[SP+5]}, PC ← {mem[SP+6], mem[SP+7]},  
SP ← SP + 7

**Flags:** スタックから復元されるため C:`*` Z:`*` N:`*` V:`*` H:`*` I:`*`

---

## RTS (INH) — Return from Subroutine

`$39` · 1 byte · 5 cycles

PC ← {mem[SP+1], mem[SP+2]}, SP ← SP + 2

**Flags:** 影響なし

---

## SBA (INH) — Subtract B from A

`$10` · 1 byte · 2 cycles

A ← A − B

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: A < B (unsigned borrow)
- Z: A == B
- N: (A − B) bit7 == 1
- V: 符号付きオーバーフロー

---

## SBC A (IMM) — Subtract with Carry from A, Immediate

`$82` · 2 bytes · 2 cycles

A ← A − imm8 − C  
オペランド: 即値 1 バイト

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: ボロー発生 (A < imm8 + C)
- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: 符号付きオーバーフロー

## SBC A (DIR)
`$92` · 2 bytes · 3 cycles | A ← A − mem[addr8] − C | Flags: SBC A (IMM) と同一

## SBC A (IDX)
`$A2` · 2 bytes · 5 cycles | A ← A − mem[X + offset8] − C | Flags: SBC A (IMM) と同一

## SBC A (EXT)
`$B2` · 3 bytes · 4 cycles | A ← A − mem[addr16] − C | Flags: SBC A (IMM) と同一

## SBC B (IMM)
`$C2` · 2 bytes · 2 cycles | B ← B − imm8 − C | Flags: SBC A (IMM) と同一

## SBC B (DIR)
`$D2` · 2 bytes · 3 cycles | B ← B − mem[addr8] − C | Flags: SBC A (IMM) と同一

## SBC B (IDX)
`$E2` · 2 bytes · 5 cycles | B ← B − mem[X + offset8] − C | Flags: SBC A (IMM) と同一

## SBC B (EXT)
`$F2` · 3 bytes · 4 cycles | B ← B − mem[addr16] − C | Flags: SBC A (IMM) と同一

---

## SEC (INH) — Set Carry
`$0D` · 1 byte · 2 cycles | C ← 1 | **Flags:** C:`1` その他影響なし

## SEI (INH) — Set Interrupt Mask
`$0F` · 1 byte · 2 cycles | I ← 1 (割り込み禁止) | **Flags:** I:`1` その他影響なし

## SEV (INH) — Set Overflow
`$0B` · 1 byte · 2 cycles | V ← 1 | **Flags:** V:`1` その他影響なし

---

## STA A (DIR) — Store A, Direct

`$97` · 2 bytes · 4 cycles

mem[addr8] ← A  
オペランド: 8 ビットアドレス

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: A == 0
- N: A bit7 == 1
- V: 常にクリア

## STA A (IDX)
`$A7` · 2 bytes · 6 cycles | mem[X + offset8] ← A | Flags: STA A (DIR) と同一

## STA A (EXT)
`$B7` · 3 bytes · 5 cycles | mem[addr16] ← A | Flags: STA A (DIR) と同一

## STA B (DIR)
`$D7` · 2 bytes · 4 cycles | mem[addr8] ← B | Flags: STA A (DIR) と同一

## STA B (IDX)
`$E7` · 2 bytes · 6 cycles | mem[X + offset8] ← B | Flags: STA A (DIR) と同一

## STA B (EXT)
`$F7` · 3 bytes · 5 cycles | mem[addr16] ← B | Flags: STA A (DIR) と同一

---

## STS (DIR) — Store Stack Pointer, Direct

`$9F` · 2 bytes · 5 cycles

mem[addr8] ← SP_hi, mem[addr8+1] ← SP_lo

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: SP == 0
- N: SP bit15 == 1
- V: 常にクリア

## STS (IDX)
`$AF` · 2 bytes · 7 cycles | {mem[X+offset8], mem[X+offset8+1]} ← SP | Flags: STS (DIR) と同一

## STS (EXT)
`$BF` · 3 bytes · 6 cycles | {mem[addr16], mem[addr16+1]} ← SP | Flags: STS (DIR) と同一

---

## STX (DIR) — Store Index Register, Direct

`$DF` · 2 bytes · 5 cycles

mem[addr8] ← X_hi, mem[addr8+1] ← X_lo

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: X == 0
- N: X bit15 == 1
- V: 常にクリア

## STX (IDX)
`$EF` · 2 bytes · 7 cycles | {mem[X+offset8], mem[X+offset8+1]} ← X | Flags: STX (DIR) と同一

## STX (EXT)
`$FF` · 3 bytes · 6 cycles | {mem[addr16], mem[addr16+1]} ← X | Flags: STX (DIR) と同一

---

## SUB A (IMM) — Subtract from A, Immediate

`$80` · 2 bytes · 2 cycles

A ← A − imm8  
オペランド: 即値 1 バイト

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`−` I:`−`

- C: A < imm8 (unsigned borrow)
- Z: 結果 & 0xFF == 0
- N: 結果 bit7 == 1
- V: 符号付きオーバーフロー

## SUB A (DIR)
`$90` · 2 bytes · 3 cycles | A ← A − mem[addr8] | Flags: SUB A (IMM) と同一

## SUB A (IDX)
`$A0` · 2 bytes · 5 cycles | A ← A − mem[X + offset8] | Flags: SUB A (IMM) と同一

## SUB A (EXT)
`$B0` · 3 bytes · 4 cycles | A ← A − mem[addr16] | Flags: SUB A (IMM) と同一

## SUB B (IMM)
`$C0` · 2 bytes · 2 cycles | B ← B − imm8 | Flags: SUB A (IMM) と同一

## SUB B (DIR)
`$D0` · 2 bytes · 3 cycles | B ← B − mem[addr8] | Flags: SUB A (IMM) と同一

## SUB B (IDX)
`$E0` · 2 bytes · 5 cycles | B ← B − mem[X + offset8] | Flags: SUB A (IMM) と同一

## SUB B (EXT)
`$F0` · 3 bytes · 4 cycles | B ← B − mem[addr16] | Flags: SUB A (IMM) と同一

---

## SWI (INH) — Software Interrupt

`$3F` · 1 byte · 12 cycles

全レジスタをスタックに保存後、SWI ベクタへジャンプ:  
mem[SP]←PC_lo, mem[SP−1]←PC_hi, mem[SP−2]←X_lo, mem[SP−3]←X_hi,  
mem[SP−4]←A, mem[SP−5]←B, mem[SP−6]←SR, SP ← SP − 7,  
I ← 1, PC ← {mem[$FFFA], mem[$FFFB]}

**Flags:** I:`1` その他影響なし  
**スタック変化:** SP は 7 減る

---

## TAB (INH) — Transfer A to B

`$16` · 1 byte · 2 cycles

B ← A

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: A == 0
- N: A bit7 == 1
- V: 常にクリア

## TAP (INH) — Transfer A to Status Register

`$06` · 1 byte · 2 cycles

SR ← A  (全フラグを A の内容で一括設定)

**Flags:** C:`*` Z:`*` N:`*` V:`*` H:`*` I:`*`

**注意:** 8bit-era.cz では I:− と記載されているが、6800 ハードウェア仕様では I も含む全ビットが転送される。  
Lua 実装の `status()` の読み書きビット順: bit0=C, bit1=V, bit2=Z, bit3=N, bit4=I, bit5=H。

## TBA (INH) — Transfer B to A

`$17` · 1 byte · 2 cycles

A ← B

**Flags:** C:`−` Z:`*` N:`*` V:`0` H:`−` I:`−`

- Z: B == 0
- N: B bit7 == 1
- V: 常にクリア

## TPA (INH) — Transfer Status Register to A
`$07` · 1 byte · 2 cycles | A ← SR | **Flags:** 影響なし

---

## TST A (ACC) — Test A

`$4D` · 1 byte · 2 cycles

A − 0  (減算結果はレジスタに書かない、フラグのみ変化)

**Flags:** C:`0` Z:`*` N:`*` V:`0` H:`−` I:`−`

- C: 常にクリア
- Z: A == 0
- N: A bit7 == 1
- V: 常にクリア

## TST B (ACC)
`$5D` · 1 byte · 2 cycles | B をテスト | Flags: TST A と同一

## TST (IDX)
`$6D` · 2 bytes · 7 cycles | mem[X + offset8] − 0 | Flags: TST A と同一

## TST (EXT)
`$7D` · 3 bytes · 6 cycles | mem[addr16] − 0 | Flags: TST A と同一

---

## TSX (INH) — Transfer Stack Pointer to X
`$30` · 1 byte · 4 cycles | X ← SP + 1 | **Flags:** 影響なし

## TXS (INH) — Transfer X to Stack Pointer
`$35` · 1 byte · 4 cycles | SP ← X − 1 | **Flags:** 影響なし

---

## WAI (INH) — Wait for Interrupt

`$3E` · 1 byte · 9 cycles

全レジスタをスタックに保存後、割り込み待ち状態へ (SWI と同じスタック操作):  
mem[SP]←PC_lo, mem[SP−1]←PC_hi, mem[SP−2]←X_lo, mem[SP−3]←X_hi,  
mem[SP−4]←A, mem[SP−5]←B, mem[SP−6]←SR, SP ← SP − 7

**Flags:** I:`1` その他影響なし  
**注意:** 実行時点で I == 1 だった場合はノンマスカブル割り込みのみで復帰可能。Lua 実装では `cpu.halt = true` で停止する。

---

## 実装上の注意事項

### INC の C フラグ

仕様では C は影響なし (`−`) だが、現行 Lua 実装 (`instructions.lua`) は `c = z` としている。**要修正。**

### NEG / LSR / DEC の addr_mode() 二重呼び出し

`dec`、`neg` 等で `addr_mode()` が 2 回呼ばれる箇所がある。  
ACC モードでは書き込み前に読み出しているため問題ないが、メモリモードでも同一アドレスを 2 回読むため副作用はない。正確さの確認が必要。

### DAA

未実装。H フラグ (half-carry) の正確なテストが前提となる。

### TAP の I フラグ

8bit-era.cz では I:`−` と記載されているが、6800 ハードウェア仕様および Lua 実装はいずれも I を含む全ビットを転送する。
