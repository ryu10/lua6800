-- Temporary stdio behavior check.
-- Usage:
--   lua tmp_stdio_check.lua read
--   lua tmp_stdio_check.lua write

local mode = arg and arg[1]

if mode == "read" then
    local i = 0
    while true do
        local ch = io.read(1)
        if ch == nil then
            break
        end
        i = i + 1
        io.write(string.format("%d:%02X\n", i, string.byte(ch)))
    end
elseif mode == "write" then
    io.write("Z")
    io.flush()
elseif mode == "print" then
    print("Z")
else
    io.stderr:write("usage: lua tmp_stdio_check.lua [read|write|print]\n")
    os.exit(2)
end
