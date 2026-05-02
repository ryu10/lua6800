-- Minimal runner for moon6800 with a simple ACIA (6850-like) emulation.

package.path = package.path .. ";./moon6800/?.lua"

local CPU = require("cpu")
local StdioAdapter = require("io_stdio")

-- This project exposes CPU as a prototype table, so use it directly.
local cpu = CPU

-- Backing store for 64KB address space.
local raw_memory = {}
for i = 0, 0xFFFF do
    raw_memory[i] = 0x00
end

-- Memory proxy: emulate ACIA registers at 0x8018/0x8019.
local ACIA_STATUS = 0x8018
local ACIA_DATA = 0x8019

local rx_byte = 0x00
local rx_ready = false
local rx_dead_until = 0.0
local rx_dead_interval = tonumber(os.getenv("ACIA_RX_DEADTIME")) or 0.0

local io_mode = os.getenv("M6800_IO") or "stdio"
local rom_arg = nil

if arg then
    for i = 1, #arg do
        local a = arg[i]
        if a == "--pty" then
            io_mode = "pty"
        elseif a:match("^%-%-io=") then
            io_mode = a:sub(6)
        elseif not rom_arg then
            rom_arg = a
        end
    end
end

local host_io
if io_mode == "pty" then
    local PtyAdapter = require("io_pty")
    local adapter, pty_err = PtyAdapter.new()
    if not adapter then
        io.stderr:write("failed to initialize PTY I/O: " .. tostring(pty_err) .. "\n")
        os.exit(1)
    end
    host_io = adapter
    if host_io.pty_path and #host_io.pty_path > 0 then
        io.stderr:write("PTY ready: " .. host_io.pty_path .. "\n")
        io.stderr:write("Connect with: screen " .. host_io.pty_path .. " 9600\n")
    end
else
    host_io = StdioAdapter.new()
end

local poll_input = function()
    if os.clock() < rx_dead_until then
        return
    end
    if rx_ready then
        return
    end
    local b = host_io.try_read_byte()
    if b then
        rx_byte = b
        rx_ready = true
        -- Match mame-sbc uart_tty: brief dead-time after receiving a character.
        rx_dead_until = os.clock() + rx_dead_interval
    end
end

local memory = setmetatable({}, {
    __index = function(_, addr)
        if addr == ACIA_STATUS then
            -- MAME-like minimal status: bit0=RXRDY, bit1=TXRDY.
            local status = 0x02
            if rx_ready then
                status = bit.bor(status, 0x01)
            end
            return status
        elseif addr == ACIA_DATA then
            local b = rx_byte
            rx_ready = false
            return b
        end
        return raw_memory[addr] or 0x00
    end,
    __newindex = function(_, addr, val)
        val = val % 0x100
        if addr == ACIA_DATA then
            host_io.write_byte(val)
        elseif addr == ACIA_STATUS then
            -- ACIA control writes are accepted but ignored.
        else
            raw_memory[addr] = val
        end
    end
})

-- Load ROM image.
-- Priority: first non-option CLI arg > M6800_ROM env var > bundled sample ROM.
local rom_path = rom_arg or os.getenv("M6800_ROM") or "mikbug/mikbug.bin"
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

local ok, err = xpcall(
    function()
        while true do
            poll_input()
            cpu:cycle()
        end
    end,
    debug.traceback
)

if host_io and host_io.close then
    host_io.close()
end

if not ok then
    io.stderr:write(err .. "\n")
    os.exit(1)
end
