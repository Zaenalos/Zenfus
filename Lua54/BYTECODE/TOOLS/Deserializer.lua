
--[==[
=============================================================
So this deserializer or undumper is based on Lua 5.4's source.
Checkout https://lua.org/source/5.4/lundump.c.html.

    -Zaenalos
=============================================================
]==]

local Oplist = require("Lua54.VM.OPCODES.oplist")

local Deserializer = {}
Deserializer.__index = Deserializer

local strUnpack = string.unpack

function Deserializer:deserialize(code)
    -- FUCK THIS HEADER
	code = code:sub(33) -- SKIP 33 BYTES HEADER

    local loadFunction
    local pos, UNPACK, getByte, get32Bits, get64Bits, get64Float, loadUnsigned, loadSize, loadInt, loadString = 1

    local pow2 = {}

    for i = 0, 2047 do
        pow2[i] = 2 ^ (i - 1023)
    end

    function UNPACK(fmt, posi)
        local res, newPos = strUnpack(fmt, code, posi)
        pos = newPos
        return res
    end

    function getByte()
        local S = pos
        pos = pos + 1
        return code:byte(S, S)
    end

    function get32Bits()
        return UNPACK("<I4", pos)
    end

    function get64Bits()
        return UNPACK("<I8", pos)
    end

    function get64Float()
        local bytes = {code:byte(pos, pos + 7)}
        local sign = (bytes[8] & 128) > 0 and -1 or 1
        local expo = (bytes[8] & 127) * 16 + (bytes[7] >> 4)
        if expo == 0 then
            return 0
        end
        local frac = (((bytes[7] & 15) * 256 + bytes[6]) * 256 + bytes[5]) << 32
        frac = frac + (bytes[4] * 16777216) + (bytes[3] * 65536) + (bytes[2] * 256) + bytes[1]
        pos = pos + 8
        return sign * (1 + frac / 2 ^ 52) * pow2[expo]
    end

    function loadUnsigned(limit)
        local size, b = 0, getByte()
        limit = limit >> 7
        size = (size << 7) | (b & 0x7f)
        while (b & 0x80) == 0 do
            b = getByte()
            if size >= limit then
                error("integer overflow")
                break
            end
            size = (size << 7) | (b & 0x7f)
        end
        return size
    end

    function loadSize()
    	return loadUnsigned(4294967295);
	end

    function loadInt()
        return math.floor(loadUnsigned(math.maxinteger))
    end

    function loadString()
        local size = loadSize()
        if size == 0 then
            return
        else
            local str = UNPACK("c" .. size - 1, pos)
            return str
        end
    end

    local function extractBits(num, start, length)
        local mask = ((1 << length) - 1) << start
        return (num & mask) >> start
    end

    local function decodeInsts(instruction)
        local opcode = extractBits(instruction, 0, 7)
		if opcode > 82 then
			error("Invalid opcode! " .. opcode)
		end
        local format = Oplist[opcode].FORMAT

        --print("OPCODE USED:", Oplist[opcode][1])

        local tab = {}

        if format == "ABC" then
            local A = extractBits(instruction, 7, 8)
            local k = extractBits(instruction, 15, 1) ~= 0
            local B = extractBits(instruction, 16, 8)
            local C = extractBits(instruction, 24, 8)
            tab.OP = opcode
            tab.FORMAT = format
            tab.A = A
            tab.k = k
            tab.B = B
            tab.C = C
            return tab
        elseif format == "ABx" then
            local A = extractBits(instruction, 7, 8)
            local Bx = extractBits(instruction, 15, 17)
            tab.OP = opcode
            tab.FORMAT = format
            tab.A = A
            tab.Bx = Bx
            return tab
        elseif format == "AsBx" then
            local A = extractBits(instruction, 7, 8)
            local sBx = extractBits(instruction, 15, 17) - 65535
            tab.OP = opcode
            tab.FORMAT = format
            tab.A = A
            tab.sBx = sBx
            return tab
        elseif format == "Ax" then
            local Ax = extractBits(instruction, 7, 25)
            tab.OP = opcode
            tab.FORMAT = format
            tab.Ax = Ax
            return tab
        elseif format == "sJ" then
            local sJ = extractBits(instruction, 7, 25) - 16777215
            tab.OP = opcode
            tab.FORMAT = format
            tab.sJ = sJ
            return tab
        end
    end

    local function luaF_newproto()
        local f = {
        	numparams = 0,
        	isvararg = 0,
        	maxstacksize = 0,
        	codeSize = 0,
        	code = {},
        	constSize = 0,
            constants = {},
            protoSize = 0,
            proto = {},
            upvalueSize = 0,
            upvalues = {},
        }
        return f
    end

    local function loadCode(f)
        local n = loadInt()
        f.codeSize = n
        for i = 1, n do
            f.code[i - 1] = decodeInsts(get32Bits())
        end
    end

    local function loadConstants(f)
        local n = loadInt()
        local data, type;
        f.constSize = n
        for i = 1, n do
            type = getByte()
            if type == 0 then --NIL
                data = nil
            elseif type == 1 then -- FALSE
                data = false
            elseif type == 17 then -- TRUE
                data = true
            elseif type == 19 then -- FLOAT
                data = UNPACK("n", pos)
            elseif type == 3 then -- INTEGER
                data = UNPACK("j", pos)
            elseif type == 4 or type == 20 then -- STRING
                data = loadString()
            else
                error("Invalid constant type: ", type)
            end
            --print("Constants: ", o)
            f.constants[i - 1] = {type = type, data = data}
        end
    end


    local function loadUpvalues(f)
        local n = loadInt()
        f.upvalueSize = n
        for i = 1, n do
            f.upvalues[i - 1] = {
                instack = getByte() ~= 0,
                idx = getByte(),
                kind = getByte()
            }
        end
    end

    local function loadProtos(f)
        local n = loadInt()
        f.protoSize = n
        for i = 1, n do
            f.proto[i - 1] = luaF_newproto()
            loadFunction(f.proto[i - 1])
        end
    end

    local function loadLines(f)
        local n = loadInt()
        f.lineinfo = {}
        f.sizelineinfo = n
        for i = 1, n do
            f.lineinfo[i - 1] = UNPACK("b", pos)
        end
        n = loadInt()
        f.abslineinfo = {}
        f.sizeabslineinfo = n
        for i = 1, n do
            f.abslineinfo[i - 1] = {
                pc = loadInt(),
                line = loadInt()
            }
        end
    end

    local function loadLocals(f)
        local n = loadInt()
        f.locals = {}
        f.localsSize = n
        for i = 1, n do
            f.locals[i - 1] = {
                varname = nil
            }
        end
        for i = 1, n do
            f.locals[i - 1] = {
                varname = loadStringN(),
                startpc = loadInt() + 1, -- Add 1 if bug
                endpc = loadInt() + 1 -- Add 1 if bug
            }
        end
    end

    local function upvalNames(f)
        local n = loadInt()
        if n ~= 0 then
            n = f.sizeupvalues
        end
        for i = 1, n do
            f.upvalues[i - 1].name = loadStringN()
        end
    end

    function loadFunction(p)
        loadString() -- source
        loadInt() -- line defined
        loadInt() -- last line defined
        p.numparams = getByte()
        p.isvararg = getByte()
        p.maxstacksize = getByte()
        loadCode(p)
        loadConstants(p)
        loadUpvalues(p)
        loadProtos(p)
        loadLines(p) -- Lines Debug
        loadLocals(p) -- Locals Debug
        upvalNames(p) -- Upvalues Debug
    end


    local chunk = luaF_newproto()
    loadFunction(chunk)
    return chunk
end

return Deserializer;
