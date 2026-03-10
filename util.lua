-- Bit packing here, nothing special.

local strChar = string.char;
local random = math.random;
local insert = table.insert;
local concat = table.concat;

local function pack12Bits(num)
    -- Ensure the number is within the range of 12-bit signed integers
    if num < -2048 or num > 2047 then
        error("Number out of 12-bit range")
    end

    -- Convert the number to a 12-bit value (2 bytes, but we only use 12 bits)
    if num < 0 then
        num = num + 4096 -- Apply two's complement for negative numbers
    end

    -- Extract the bytes
    local highByte = (num // 256)
    local lowByte = num % 256

    -- Pack into a 2-byte string
    local packed = strChar(highByte, lowByte)

    -- Return the packed string
    return packed
end


local function pack26Bits(value)
    assert(value >= 0 and value < 2^26, "Value out of range for 26 bits")
    local packed = strChar(
        (value >> 18) & 0xFF,  -- 8 bits
        (value >> 10) & 0xFF,  -- 8 bits
        (value >> 2) & 0xFF,   -- 8 bits
        (value & 0x03) << 6    -- 2 bits packed in the last byte
    )
    return packed
end

local function pack27Bits(value)
    if value < 0 or value >= (1 << 27) then
        error("Value out of range")
    end

    local bytes = {}
    for i = 1, 4 do
        insert(bytes, 1, strChar(value & 0xFF))
        value = value >> 8
    end

    return concat(bytes)
end

-- Just a reversal of this deserialization: https://lua.org/source/5.4/lundump.c.html#loadUnsigned
local function MSBserialize(size)
    local bytes = {}
    repeat
        local byte = size & 0x7F  -- Extract the lower 7 bits
        size = size >> 7          -- Shift the size to process the next 7 bits
        if size > 0 then
            byte = byte | 0x80    -- Set the MSB if more bytes follow
        end
        table.insert(bytes, strChar(byte))  -- Insert byte at the end
        -- print(string.format("Serialized byte: %02X, size: %d", byte, size))
    until size == 0
    return concat(bytes)
end

local function shuffle(tb)
	local j;
	for i = #tb, 2, -1 do
		j = random(i)
		tb[i], tb[j] = tb[j], tb[i]
	end
	return tb
end


return {
	shuffle = shuffle,
	pack12Bits = pack12Bits,
	pack26Bits = pack26Bits,
	pack27Bits = pack27Bits,
	MSBserialize = MSBserialize,
};