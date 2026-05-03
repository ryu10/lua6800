package.path = package.path .. ";./moon6800/?.lua"

local bit = require("bit")
local ffi = require("ffi")
local CPU = require("cpu")

ffi.cdef[[
    int fcntl(int fd, int cmd, int arg);
    int read(int fd, void *buf, size_t count);
    int write(int fd, const void *buf, size_t count);
]]

local F_GETFL = 3
local F_SETFL = 4
local O_NONBLOCK = (jit and (jit.os == "OSX" or jit.os == "BSD")) and 0x0004 or 0x0800

io.stdout:setvbuf("no")
local flags = ffi.C.fcntl(0, F_GETFL, 0)
if flags >= 0 then
    ffi.C.fcntl(0, F_SETFL, bit.bor(flags, O_NONBLOCK))
else
    ffi.C.fcntl(0, F_SETFL, O_NONBLOCK)
end

local cpu = CPU
local input_buf = ffi.new("char[1]")

local raw_memory = {}
for i = 0, 0xFFFF do
    raw_memory[i] = 0x00
end

local ACIA_STATUS = 0x8018
local ACIA_DATA = 0x8019
local EAGAIN = 11
local EWOULDBLOCK = (jit and jit.os == "OSX") and 35 or 11
local EINTR = 4

local key_trace_path = os.getenv("M6800_KEY_TRACE_FILE")
local key_trace = nil
local key_trace_seq = 0
if key_trace_path and key_trace_path ~= "" then
    key_trace = io.open(key_trace_path, "ab")
end

local function trace_key_event(raw_byte, normalized_byte, note)
    if not key_trace then
        return
    end
    key_trace_seq = key_trace_seq + 1
    local raw_s = raw_byte and string.format("%02X", raw_byte) or "--"
    local norm_s = normalized_byte and string.format("%02X", normalized_byte) or "--"
    key_trace:write(string.format("%08d raw=%s norm=%s %s\n", key_trace_seq, raw_s, norm_s, note or ""))
    key_trace:flush()
end

local rx_byte = 0x00
local rx_ready = false
local rx_overrun = false
local last_rx_was_cr = false

local function rx_take()
    if not rx_ready then
        return nil
    end
    local v = rx_byte
    rx_ready = false
    return v
end

local function poll_input()
    while true do
        local n = ffi.C.read(0, input_buf, 1)
        if n > 0 then
            local raw = bit.band(input_buf[0], 0xFF)
            local b = raw

            -- Normalize terminal line-endings and ignore PTY noise.
            if b == 0x00 then
                trace_key_event(raw, nil, "drop-nul")
            elseif b == 0x0A and last_rx_was_cr then
                -- Collapse CRLF into a single CR event.
                trace_key_event(raw, nil, "drop-lf-after-cr")
            else
                if b == 0x0A then
                    b = 0x0D
                    trace_key_event(raw, b, "lf-to-cr")
                else
                    trace_key_event(raw, b, "accept")
                end
                if rx_ready then
                    -- ACIA RX register is single-byte; drop extra bytes until host reads DATA.
                    rx_overrun = true
                    trace_key_event(raw, nil, "drop-overrun")
                else
                    rx_byte = b
                    rx_ready = true
                    last_rx_was_cr = (b == 0x0D)
                end
            end
        elseif n < 0 then
            local err = ffi.errno()
            if err ~= EAGAIN and err ~= EWOULDBLOCK and err ~= EINTR then
                io.stderr:write(string.format("read(stdin) failed: errno=%d\n", err))
            end
            return
        else
            return
        end
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
            if rx_overrun then
                status = bit.bor(status, 0x20)
            end
            return status
        elseif addr == ACIA_DATA then
            return rx_take() or 0x00
        end
        return raw_memory[addr] or 0x00
    end,
    __newindex = function(_, addr, value)
        value = value % 0x100
        if addr == ACIA_DATA then
            write_byte(value)
        elseif addr == ACIA_STATUS then
            -- Accept ACIA control writes and ignore for now.
            -- Clear overrun on any control write to reduce sticky fault behavior.
            rx_overrun = false
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
    if key_trace then
        key_trace:close()
    end
    os.exit(1)
end
