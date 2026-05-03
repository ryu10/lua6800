package.path = package.path .. ";./moon6800/?.lua"

local CPU = require("cpu")
local ACIA = require("acia")

io.stdout:setvbuf("no")

local cpu = CPU
local acia = ACIA.new()

local raw_memory = {}
for i = 0, 0xFFFF do
    raw_memory[i] = 0x00
end

local ACIA_STATUS = 0x8018
local ACIA_DATA = 0x8019

local memory = setmetatable({}, {
    __index = function(_, addr)
        if addr == ACIA_STATUS then
            return acia:status()
        elseif addr == ACIA_DATA then
            return acia:read_data()
        end
        return raw_memory[addr] or 0x00
    end,
    __newindex = function(_, addr, value)
        value = value % 0x100
        if addr == ACIA_DATA then
            acia:write_data(value)
        elseif addr == ACIA_STATUS then
            acia:write_control(value)
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
        acia:poll_input()
        cpu:cycle()
    end
end, debug.traceback)

acia:close()

if not ok then
    io.stderr:write(err .. "\n")
    os.exit(1)
end
