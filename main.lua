package.path = package.path .. ";./moon6800/?.lua"

local CPU          = require("cpu")
local ACIA         = require("acia")
local ram_factory  = require("ram")
local eprom_factory = require("eprom")
local bus          = require("memory")

io.stdout:setvbuf("no")

local cpu = CPU
local acia = ACIA.new()

local acia_trace_path = os.getenv("M6800_ACIA_TRACE_FILE")
local acia_trace = nil
local acia_trace_seq = 0
if acia_trace_path and acia_trace_path ~= "" then
    acia_trace = io.open(acia_trace_path, "wb")
end

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
    local op = bus[pc] or 0
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

local ACIA_STATUS = 0x8018
local ACIA_DATA   = 0x8019

-- RAM: 0x0000-0x7FFF (32KB)
local ram = ram_factory(0x8000, 0x00)

-- RAM2: 0x9000-0xF3FF (25KB))
local ram2 = ram_factory(0x6400, 0x00)


-- ACIA I/O module: 2 bytes at ACIA_STATUS
local acia_module = { size = 2 }
setmetatable(acia_module, {
    __index = function(_, offset)
        if offset == 0 then
            local v = acia:status()
            trace_acia("RD", ACIA_STATUS, v)
            return v
        elseif offset == 1 then
            local v = acia:read_data()
            trace_acia("RD", ACIA_DATA, v)
            return v
        end
        return 0
    end,
    __newindex = function(_, offset, value)
        value = value % 0x100
        if offset == 0 then
            trace_acia("WR", ACIA_STATUS, value)
            acia:write_control(value)
        elseif offset == 1 then
            trace_acia("WR", ACIA_DATA, value)
            acia:write_data(value)
        end
    end
})

-- EPROM: 0xE000-0xFFFF (8KB, covers ROM + vectors)
local ROM_START = 0xF800
local ROM_SIZE  = 0x0800
local rom_data  = { size = ROM_SIZE }
local rom_path  = (arg and arg[1]) or os.getenv("M6800_ROM") or "mikbug/mikbug.bin"
local f = io.open(rom_path, "rb")
if f then
    local image = f:read("*all")
    f:close()
    for i = 0, ROM_SIZE - 1 do
        rom_data[i] = image:byte(ROM_START + i + 1) or 0xFF
    end
end
local eprom = eprom_factory(rom_data)

bus:connect(0x0000,     ram)
bus:connect(0x9000,     ram2)
bus:connect(ACIA_STATUS, acia_module)
bus:connect(ROM_START,  eprom)
bus.cpu = cpu

cpu:init(bus)
cpu:go()

local ok, err = xpcall(function()
    while true do
        acia:poll_input()
        trace_cpu_step()
        cpu:cycle()
    end
end, debug.traceback)

acia:close()
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
