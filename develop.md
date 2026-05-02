# Development Log (as of 2026-05-01)

## Goal
- Run the Lua 6800 emulator reliably with correct ACIA-style interactive I/O.
- Keep CPU/device emulation correctness separate from host terminal behavior.

## Implemented Changes

### 1) ROM/Image Work
- Extracted MIKBUG image into standalone header and built 64KB padded image.
- Built binary image `mikbug/mikbug.bin` (65536 bytes).
- Added C utility to build binary from header.

### 2) Runtime Entrypoint
- `main.lua` now runs monitor from `mikbug/mikbug.bin`.
- ACIA memory mapping uses:
  - status/control: `0x8018`
  - data: `0x8019`
- TX path writes single bytes to stdout.
- RX path reads single bytes through a host I/O adapter.

### 3) I/O Boundary Refactor
- Introduced `moon6800/io_stdio.lua`:
  - Nonblocking stdin byte reads via LuaJIT FFI (`fcntl` + `read`).
  - Byte-oriented stdout writes.
  - Optional TX/RX trace outputs:
    - `ACIA_TX_TRACE_FILE`
    - `ACIA_RX_TRACE_FILE`
- `main.lua` switched to adapter usage (reduced direct terminal-specific logic in core loop).

### 4) Wrapper Script
- Added launcher script for emulator startup.
- Script manages terminal mode and restore-on-exit behavior.
- Current status: wrapper still not stable for all interactive cases (see Open Issues).

### 5) CPU Emulation Fixes Applied
- `moon6800/instructions.lua`
  - Fixed `ext16` addressing mode bug:
    - Was incorrectly dereferencing operand bytes as addresses.
    - Now correctly builds a 16-bit effective address and accesses `[addr]` / `[addr+1]`.
  - Fixed `asr` implementation:
    - Preserves sign bit from source operand.
    - Uses source bit0 for carry.
    - Avoids repeated side-effecting reads.
  - Fixed branch/bit logic during investigation:
    - `bgt` condition corrected to `(!Z) && (N == V)`.
    - `bhi` condition corrected to `(!C) && (!Z)`.
    - `bit` N flag corrected to reflect bit7.

## What Was Verified
- `mikbug/mikbug.bin` vector bytes are correct:
  - `FFFE = E0`, `FFFF = D0`.
- After `ext16` fix, monitor memory display at `MFFFE` can show correct vector bytes.
- Syntax checks pass (`luajit -bl main.lua`).

## Open Issues (Current Blockers)
- Interactive input still shows occasional stale/garbage character effects.
- User reports inability to consistently enter a clean M command sequence.
- Launcher-assisted mode was considered unreliable during interactive tests.

## Current User Decision
- Investigation paused due to unstable interactive behavior.
- Working assumption at pause time:
  - Wrapper path is not yet behaving as intended for real keyboard interaction.

## Suggested Restart Plan
1. Start from minimum path:
- Temporarily bypass wrapper terminal mutations.
- Use direct launch with a minimal, known-good input strategy.

2. Reintroduce layers one by one:
- Re-enable wrapper terminal mode changes incrementally.
- Validate after each single change.

3. Keep diagnostic traces on while stabilizing:
- Enable `ACIA_TX_TRACE_FILE` and `ACIA_RX_TRACE_FILE`.
- Confirm byte-for-byte RX/TX sequence during each reproduction.

4. Lock a reproducible manual test protocol:
- Character-by-character interactive sequence (no bulk line injection).
- Record expected monitor response after each key.

## Files Touched In This Iteration
- `main.lua`
- `run-m6800.sh`
- `moon6800/io_stdio.lua`
- `moon6800/instructions.lua`
- `develop.md` (this file)

## Notes
- Several shell sessions exited with code 143 due to manual termination while testing interactive loops.
- This is expected during iterative monitor interaction tests.
