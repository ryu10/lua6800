package.path = package.path .. ";./moon6800/?.lua"

local CPU = require("cpu")
local io_pty = require("io_pty")

io.stdout:setvbuf("no")

local cpu = CPU

local adapter, pty_err = io_pty.new()
if not adapter then
    io.stderr:write("PTY 初期化失敗: " .. tostring(pty_err) .. "\n")
    os.exit(1)
end
io.stderr:write("PTY slave: " .. tostring(adapter.pty_path) .. "\n")

local rx_data = 0x00
local rx_ready = false

local function acia_poll_input()
    if rx_ready then return end
    local b = adapter.try_read_byte()
    if b then
        rx_data = b
        rx_ready = true
    end
end

local function acia_status()
    return 0x02 + (rx_ready and 0x01 or 0)
end

local function acia_read_data()
    rx_ready = false
    return rx_data
end

local function acia_write_data(value)
    adapter.write_byte(value)
end

local function acia_write_control(_value) end

local acia_trace_path = os.getenv("M6800_ACIA_TRACE_FILE")
local acia_trace = nil
local acia_trace_seq = 0
if acia_trace_path and acia_trace_path ~= "" then
    acia_trace = io.open(acia_trace_path, "wb")
end

local raw_memory

local cpu_trace_path = os.getenv("M6800_CPU_TRACE_FILE")
local cpu_trace = nil
local cpu_trace_seq = 0
local cpu_trace_limit = tonumber(os.getenv("M6800_CPU_TRACE_LIMIT") or "0") or 0
if cpu_trace_path and cpu_trace_path ~= "" then
    cpu_trace = io.open(cpu_trace_path, "wb")
end

local function trace_cpu_step()
    if not cpu_trace then
        return
    end
    if cpu_trace_limit > 0 and cpu_trace_seq >= cpu_trace_limit then
        return
    end

    local pc = cpu.registers and cpu.registers.pc and cpu.registers.pc() or 0
    local op = raw_memory[pc] or 0
    local a = cpu.registers and cpu.registers.a and cpu.registers.a() or 0
    local b = cpu.registers and cpu.registers.b and cpu.registers.b() or 0
    local ix = cpu.registers and cpu.registers.ix and cpu.registers.ix() or 0
    local sp = cpu.registers and cpu.registers.sp and cpu.registers.sp() or 0

    cpu_trace_seq = cpu_trace_seq + 1
    cpu_trace:write(string.format(
        "%08d pc=%04X op=%02X a=%02X b=%02X ix=%04X sp=%04X\n",
        cpu_trace_seq,
        pc % 0x10000,
        op % 0x100,
        a % 0x100,
        b % 0x100,
        ix % 0x10000,
        sp % 0x10000
    ))
    cpu_trace:flush()
end

local function trace_acia(op, addr, value)
    if not acia_trace then
        return
    end
    acia_trace_seq = acia_trace_seq + 1
    local pc = cpu.registers and cpu.registers.pc and cpu.registers.pc() or 0
    acia_trace:write(string.format("%08d pc=%04X %s %04X=%02X\n", acia_trace_seq, pc, op, addr, value % 0x100))
    acia_trace:flush()
end

raw_memory = {}
for i = 0, 0xFFFF do
    raw_memory[i] = 0x00
end

local ACIA_STATUS = 0x8018
local ACIA_DATA = 0x8019

local memory = setmetatable({}, {
    __index = function(_, addr)
        if addr == ACIA_STATUS then
            local v = acia_status()
            trace_acia("RD", addr, v)
            return v
        elseif addr == ACIA_DATA then
            local v = acia_read_data()
            trace_acia("RD", addr, v)
            return v
        end
        return raw_memory[addr] or 0x00
    end,
    __newindex = function(_, addr, value)
        value = value % 0x100
        if addr == ACIA_DATA then
            trace_acia("WR", addr, value)
            acia_write_data(value)
        elseif addr == ACIA_STATUS then
            trace_acia("WR", addr, value)
            acia_write_control(value)
        else
            raw_memory[addr] = value
        end
    end
})

local rom_path = (arg and arg[1]) or os.getenv("M6800_ROM") or "mikbug/mikbug.bin"
local f = io.open(rom_path, "rb")
if f then
    local data = f:read("*all")
    f:close()
    for i = 1, #data do
        local addr = i - 1
        if addr > 0xFFFF then
            break
        end
        memory[addr] = data:byte(i)
    end
end

cpu:init(memory)
cpu:go()

local ok, err = xpcall(function()
    while true do
        acia_poll_input()
        trace_cpu_step()
        cpu:cycle()
    end
end, debug.traceback)

adapter.close()
if acia_trace then
    acia_trace:close()
end
if cpu_trace then
    cpu_trace:close()
end

if not ok then
    io.stderr:write(err .. "\n")
    os.exit(1)
end
