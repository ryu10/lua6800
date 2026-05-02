-- acia_emu.lua

io.stdout:setvbuf("no") -- 標準出力をバッファリングなしに設定
print("ACIA Emulator Started. Type any key...")
io.stdout:flush()

local ffi = require("ffi")
ffi.cdef[[
    int fcntl(int fd, int cmd, int arg);
    int read(int fd, void *buf, size_t count);
    int write(int fd, const void *buf, size_t count);
]]

local F_SETFL = 4
local O_NONBLOCK = 0x0004 -- OSにより異なる場合があるが一般的数値

-- 標準入力(fd=0)をノンブロッキングに設定
ffi.C.fcntl(0, F_SETFL, O_NONBLOCK)

local buf = ffi.new("char[1]")

print("ACIA Emulator Started. (Echo Mode)")
while true do
    -- ACIAの受信レジスタ確認に相当
    local n = ffi.C.read(0, buf, 1)
    
    if n > 0 then
        local char = buf[0]
        -- エコーバック (受信した文字を加工して送信)
        -- 例: 小文字を大文字にして返す
        if char >= 97 and char <= 122 then char = char - 32 end
        
        ffi.C.write(1, ffi.new("char[1]", char), 1)
    elseif n == 0 then
        break -- EOF
    end

    -- CPU負荷を抑えるための僅かなスリープ (実機クロックに合わせるなら調整)
    os.execute("sleep 0.001") 
end
