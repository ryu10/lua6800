local bit = require("bit")
local ffi = require("ffi")

ffi.cdef[[
    int fcntl(int fd, int cmd, int arg);
    int read(int fd, void *buf, size_t count);
    int write(int fd, const void *buf, size_t count);
]]

local F_GETFL = 3
local F_SETFL = 4
local O_NONBLOCK = (jit and (jit.os == "OSX" or jit.os == "BSD")) and 0x0004 or 0x0800

local EAGAIN = 11
local EWOULDBLOCK = (jit and jit.os == "OSX") and 35 or 11
local EINTR = 4

local ACIA = {}
ACIA.__index = ACIA

local function open_key_trace_from_env()
    local trace_path = os.getenv("M6800_KEY_TRACE_FILE")
    if not trace_path or trace_path == "" then
        return nil
    end
    return io.open(trace_path, "ab")
end

function ACIA.new(opts)
    opts = opts or {}

    local self = setmetatable({}, ACIA)
    self.stdin_fd = opts.stdin_fd or 0
    self.stdout_fd = opts.stdout_fd or 1

    self.rx_byte = 0x00
    self.rx_ready = false
    self.rx_overrun = false
    self.last_rx_was_cr = false

    self.input_buf = ffi.new("char[1]")

    self.key_trace = open_key_trace_from_env()
    self.key_trace_seq = 0

    local flags = ffi.C.fcntl(self.stdin_fd, F_GETFL, 0)
    if flags >= 0 then
        ffi.C.fcntl(self.stdin_fd, F_SETFL, bit.bor(flags, O_NONBLOCK))
    else
        ffi.C.fcntl(self.stdin_fd, F_SETFL, O_NONBLOCK)
    end

    return self
end

function ACIA:trace_key_event(raw_byte, normalized_byte, note)
    if not self.key_trace then
        return
    end
    self.key_trace_seq = self.key_trace_seq + 1
    local raw_s = raw_byte and string.format("%02X", raw_byte) or "--"
    local norm_s = normalized_byte and string.format("%02X", normalized_byte) or "--"
    self.key_trace:write(string.format("%08d raw=%s norm=%s %s\n", self.key_trace_seq, raw_s, norm_s, note or ""))
    self.key_trace:flush()
end

function ACIA:poll_input()
    while true do
        local n = ffi.C.read(self.stdin_fd, self.input_buf, 1)
        if n > 0 then
            local raw = bit.band(self.input_buf[0], 0xFF)
            local b = raw

            if b == 0x00 then
                self:trace_key_event(raw, nil, "drop-nul")
            elseif b == 0x0A and self.last_rx_was_cr then
                self:trace_key_event(raw, nil, "drop-lf-after-cr")
            else
                if b == 0x0A then
                    b = 0x0D
                    self:trace_key_event(raw, b, "lf-to-cr")
                else
                    self:trace_key_event(raw, b, "accept")
                end

                if self.rx_ready then
                    self.rx_overrun = true
                    self:trace_key_event(raw, nil, "drop-overrun")
                else
                    self.rx_byte = b
                    self.rx_ready = true
                    self.last_rx_was_cr = (b == 0x0D)
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

function ACIA:status()
    local status = 0x02
    if self.rx_ready then
        status = bit.bor(status, 0x01)
    end
    if self.rx_overrun then
        status = bit.bor(status, 0x20)
    end
    return status
end

function ACIA:read_data()
    if not self.rx_ready then
        return 0x00
    end

    local v = self.rx_byte
    self.rx_ready = false
    return v
end

function ACIA:write_data(value)
    local out = ffi.new("char[1]", value % 0x100)
    ffi.C.write(self.stdout_fd, out, 1)
end

function ACIA:write_control(_value)
    self.rx_overrun = false
end

function ACIA:close()
    if self.key_trace then
        self.key_trace:close()
        self.key_trace = nil
    end
end

return ACIA
