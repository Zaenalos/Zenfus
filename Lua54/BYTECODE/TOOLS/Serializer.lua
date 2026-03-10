local Oplist = require("Lua54.VM.OPCODES.oplist")
local util = require("util")
local pack12Bits = util.pack12Bits
local pack27Bits = util.pack27Bits
local MSBserialize = util.MSBserialize

local Serializer = {}

Serializer.__index = Serializer
setmetatable(Serializer, self)

local insert = table.insert
local pack = string.pack

local Maxbits = 27
local Mask = (1 << Maxbits) - 1

-- Sizes
local sizeType = 3
local sizeOp = 24
local sizeB = 8
local sizeA = 8
local sizeC = 8
local sizeBx = 16
local sizeSbx = sizeBx

-- Shifting positions
local typeShift = 0
local OPshift = nil
local Ashift = typeShift + sizeType
local Bshift = Ashift + sizeA
local Cshift = Bshift + sizeB
local Bxshift = Bshift
local sBxshift = Bxshift

local function isWithin26Bits(num)
    -- An unsigned 26-bit integer ranges from 0 to 2^26 - 1
    local minUnsigned32Bit = 0
    local maxUnsigned32Bit = 2^26 - 1
    
    return num >= minUnsigned32Bit and num <= maxUnsigned32Bit
end

local function convertValue(value, bits)
    local max_unsigned = 2^bits - 1
    local max_signed = 2^(bits - 1) - 1
    local min_signed = -2^(bits - 1)

    if value < 0 then
        -- Convert signed to unsigned
        return value + 2^bits
    elseif value > max_signed then
        -- Convert unsigned to signed
        return value - 2^bits
    else
        -- Value is already within signed range
        return value
    end
end

function Serializer:serializeInst(instructions, size)
    if size == 0 then
        return pack12Bits(size)
    end
    
    local srlInsts = {}
    local shiftedOP
    local OP
    local FORMAT
    local A, B, C, Bx, sBx, Ax, sJ, fType
    local newIns
    
    for i = 0, size - 1, 1 do
        OP = instructions[i].OP
        FORMAT = instructions[i].FORMAT
        shiftedOP = pack("<I3", OP)
        if FORMAT == "ABC" or FORMAT == "ABIC" or FORMAT == "ABCI" then
        	fType = (FORMAT == "ABC" and 1 or
        	FORMAT == "ABIC" and 2 or
        	FORMAT == "ABCI" and 3)
            fType = (fType << typeShift) & Mask
            A = (instructions[i].A << Ashift) & Mask
            B = (instructions[i].B << Bshift) & Mask
            C = (instructions[i].C << Cshift) & Mask
            newIns = MSBserialize(fType | A | B | C)
        elseif FORMAT == "ABx" then
            fType = (4 << typeShift) & Mask
            A = (instructions[i].A << Ashift) & Mask
            Bx = (instructions[i].Bx << Bxshift) & Mask
            newIns = MSBserialize(fType | A | Bx)
        elseif FORMAT == "AsBx" then
            fType = (5 << typeShift) & Mask
            A = (instructions[i].A << Ashift) & Mask
            sBx = (convertValue(instructions[i].sBx, sizeSbx) << sBxshift) & Mask
            newIns = MSBserialize(fType | A | sBx)
        elseif FORMAT == "Ax" then
        	fType = (6 << typeShift) & Mask
        	Ax = (instructions[i].Ax << Ashift) & Mask
        	newIns = MSBserialize(fType | Ax)
        elseif FORMAT == "sJ" then
        	fType = (7 << typeShift) & Mask
        	sJ = (convertValue(instructions[i].sJ, 24) << Ashift) & Mask
        	newIns = MSBserialize(fType | sJ)
        else
        	error("Invalid format")
        end
        insert(srlInsts, shiftedOP .. newIns)
    end
    -- local format = ("<I4"):rep(size)
    assert(size == #srlInsts, "Error serializing Instructions")
    local codeSize = pack12Bits(size)
    -- local newInsts = codeSize .. pack(format, table.unpack(srlInsts))
    local newInsts = codeSize .. table.concat(srlInsts)
    return newInsts
end

function Serializer:serializeConst(constants, size)
    if size == 0 then
        return pack("<I4", size)
    end
    
    local srlConsts = {}
    local dataType
    local data
    for i = 0, size - 1, 1 do
        dataType = constants[i].type
        data = constants[i].data
        if dataType == 0 then
            insert(srlConsts, pack("<b", 0)) -- NIL
        elseif dataType == 1 then
            insert(srlConsts, pack("<b", 1)) -- FALSE
        elseif dataType == 17 then
        	insert(srlConsts, pack("<b", 17)) -- TRUE
        elseif dataType == 19 then
        	insert(srlConsts, pack("<b", 19) .. pack("n", data)) -- FLOAT
        elseif dataType == 3 then
        	insert(srlConsts, pack("<b", 3) .. pack("j", data)) -- INTEGER
        elseif dataType == 4 or dataType == 20 then
        	insert(srlConsts, (pack("<b", dataType) .. MSBserialize(#data) .. pack("c" .. #data, data)))
        end
    end
    assert(size == #srlConsts, "Error serializing constants")
    local newConst = pack("<I4", size) .. table.concat(srlConsts)
    return newConst
end

function Serializer:serializeUpvalue(upvalues, size)
	if size == 0 then
        return pack("<I4", size)
    end
    local srlUpvalues = {}
    
    local instack, idx;
    for i = 0, size - 1, 1 do
    	instack = upvalues[i].instack and 1 or 0
    	idx = upvalues[i].idx
    	--print("Instack: ", instack ~= 0, "Idx: ", idx)
    	insert(srlUpvalues, pack("<b", instack))
    	insert(srlUpvalues, pack("<b", idx))
    end
    assert(size*2 == #srlUpvalues, "Error serializing upvalues")
    local newUpvalues = pack("<I4", size) .. table.concat(srlUpvalues)
    return newUpvalues
end

function Serializer:serializeProto(protos, size)
    local srlProto = {}
    for i = 0, size - 1, 1 do
        insert(srlProto, self:serialize(protos[i]))
    end
    local newSize = pack("<I4", size) .. table.concat(srlProto)
    return newSize
end

function Serializer:serialize(chunk)
    local serialized = {}
    insert(serialized, pack("<b", chunk.numparams))
    local instructions = self:serializeInst(chunk.code, chunk.codeSize)
    insert(serialized, instructions)
    local constants = self:serializeConst(chunk.constants, chunk.constSize)
    insert(serialized, constants)
    local upvalues = self:serializeUpvalue(chunk.upvalues, chunk.upvalueSize)
    insert(serialized, upvalues)
    local protos = self:serializeProto(chunk.proto, chunk.protoSize)
    insert(serialized, protos)
    return table.concat(serialized)
end

return Serializer