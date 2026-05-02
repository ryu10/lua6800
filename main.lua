package.path = package.path .. ";./moon6800/?.lua"

local bit = require("bit")
local ffi = require("ffi")
local CPU = require("cpu")

ffi.cdef[[
    int fcntl(int fd, int cmd, int arg);
    int read(int fd, void *buf, size_t count);
    int write(int fd, const void *buf, size_t count);
]]

local F_SETFL = 4
local O_NONBLOCK = 0x0004

io.stdout:setvbuf("no")
ffi.C.fcntl(0, F_SETFL, O_NONBLOCK)

local cpu = CPU
local input_buf = ffi.new("char[1]")

local raw_memory = {}
for i = 0, 0xFFFF do
    raw_memory[i] = 0x00
end

local ACIA_STATUS = 0x8018
local ACIA_DATA = 0x8019

local rx_byte = 0x00
local rx_ready = false

local function poll_input()
    if rx_ready then
        return
    end

    local n = ffi.C.read(0, input_buf, 1)
    if n > 0 then
        rx_byte = input_buf[0]
        rx_ready = true
    end
end

local function write_byte(value)
    local out = ffi.new("char[1]", value)
    ffi.C.write(1, out, 1)
end

local memory = setmetatable({}, {
    __index = function(_, addr)
        if addr == ACIA_STATUS then
            local status = 0x02
            if rx_ready then
                status = bit.bor(status, 0x01)
            end
            return status
        elseif addr == ACIA_DATA then
            local value = rx_byte
            rx_ready = false
            return value
        end
        return raw_memory[addr] or 0x00
    end,
    __newindex = function(_, addr, value)
        value = value % 0x100
        if addr == ACIA_DATA then
            write_byte(value)
        elseif addr == ACIA_STATUS then
            -- Accept ACIA control writes and ignore for now.
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
        poll_input()
        cpu:cycle()
    end
end, debug.traceback)

if not ok then
    io.stderr:write(err .. "\n")
    os.exit(1)
end
