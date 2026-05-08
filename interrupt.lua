-- NMI コードモック
--  もう、main.lua に組み込んだので、このファイルは不要になりました。

local cpu = require("moon6800")
local memory = {}

-- 設定：アドレスは自作モニタの設計に合わせて変更してください
local TIMER_START_ADDR = 0x8000 -- ここに書くとタイマー開始 (J-BUGのTrace)
local TIMER_RESET_ADDR = 0x8001 -- ここに書くとNMIフラグを即座に下ろす

local total_cycles = 0
local trace_timer_active = false
local trace_target_cycle = 0

-- メモリ読み書きの定義
local function mem_read(addr) return memory[addr] or 0 end
local function mem_write(addr, val)
    memory[addr] = val
    
    -- 1. タイマー開始トラップ
    if addr == TIMER_START_ADDR then
        trace_timer_active = true
        trace_target_cycle = total_cycles + 13 -- RTI(10) + 余裕(3)
    end
    
    -- 2. NMIクリアトラップ (NMIハンドラ内で実行する)
    if addr == TIMER_RESET_ADDR then
        cpu.nmi = false
        trace_timer_active = false
    end
end

cpu:init(mem_read, mem_write)

-- 実行メインループ
while true do
    -- 1命令実行
    local cycles_taken = cpu:step()
    total_cycles = total_cycles + cycles_taken

    -- 3. NMI発火ロジック
    if trace_timer_active and total_cycles >= trace_target_cycle then
        cpu.nmi = true
        trace_timer_active = false -- 二重発火防止
    end
end
