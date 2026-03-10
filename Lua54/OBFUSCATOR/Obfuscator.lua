local Logger = require("logger");
local Settings = require("settings")
local Oplist = require("Lua54.VM.OPCODES.oplist")
local Optimizer = require("Lua54.OBFUSCATOR.Optimizer")
local insert = table.insert

local function Encryptor(input, key)
	local output = {}
    for i = 1, #input do
        local key_byte = string.byte(key, (i - 1) % #key + 1)
        local input_byte = string.byte(input, i)
        local encrypted_byte = (input_byte ~ key_byte)
        output[i] = string.char(encrypted_byte)
    end
    return table.concat(output)
end

local function EncryptConstants(chunk)
	for _, const in pairs(chunk.constants) do
		if const.type == 4 or const.type == 20 then
			const.data = Encryptor(const.data, "Zaenalos") -- xD
		end
	end

	for _, proto in pairs(chunk.proto) do
		EncryptConstants(proto)
	end
end

local function optimizeInstructions(chunk)
    local OPname, optimizer, instruction
    local i = 0 -- Iterator

    for _, instruction in pairs(chunk.code) do
        OPname = Oplist[instruction.OP][1]
        optimizer = Optimizer[OPname]

        if optimizer.optimize then
            -- I forgot why I added the chunk argument here, it's up to you know, mate.
            optimizer:optimize(instruction, chunk)
        else
            optimizer:default(instruction)
        end
    end

    for _, proto in pairs(chunk.proto) do
        optimizeInstructions(proto)
    end
end

-- Function to generate super operators
-- So yeah, this is based on IB2 BTW.
local function generateSuperOP(chunk, maxSize, minSize)
    minSize = minSize or 5
    local toSkip = {}
    local superOperators = {}

    -- Mark instructions to skip
    for i, instruction in pairs(chunk.code) do
        local OPname = Oplist[instruction.OP][1]
        if instruction.skip then
            toSkip[i] = true
        elseif OPname == "CLOSURE" or
			   OPname == "EQ" or OPname == "LT" or OPname == "LE" or
           	OPname == "EQK" or OPname == "EQI" or OPname == "LTI" or
           	OPname == "LEI" or OPname == "GTI" or OPname == "GEI" or
               OPname == "TEST" or OPname == "TESTSET" or OPname == "TFORLOOP" or
               OPname == "LFALSESKIP" then
            toSkip[i + 1] = true
        elseif OPname == "FORLOOP" or OPname == "TFORLOOP" then
        	toSkip[i + 1] = true
            toSkip[i + 1 - instruction.Bx] = true
        elseif OPname == "FORPREP" or OPname == "TFORPREP" then
            toSkip[i + 1] = true
            toSkip[i + 1 + instruction.Bx] = true
        elseif OPname == "JMP" then
        	toSkip[i + 1] = true
            toSkip[i + 1 + instruction.sJ] = true
        elseif instruction.superOp then
            for j = 0, #instruction.subOP do
            	toSkip[i + j] = true
            end
        end
    end

    -- Create super operators
    local i, limit = 0, chunk.codeSize - 1
    while i <= limit do
        if toSkip[i + 1] then
            i = i + 1
            goto continue
        end

        local targetCount = maxSize
        local superOP = { OP = "SUPER", subOP = {}, superOp = true }
        local valid = true

        for j = 0, targetCount - 1 do
            if i + j > limit or toSkip[i + j] then
                targetCount = j
                valid = false
                break
            end
        end

        if targetCount < minSize then
            i = i + targetCount + 1
            goto continue
        end

        for j = 0, targetCount - 1 do
            chunk.code[i + j].skip = true
            chunk.code[i + j].subOP = true
            insert(superOP.subOP, chunk.code[i + j])
        end

        i = i + targetCount

        ::continue::
    end

    i = 0
    while i <= limit do
        local instruction = chunk.code[i]
        if instruction.subOP then
        	local backTrack = i;
            local superOP = { OP = "SUPER", subOP = {}, superOp = true }
            while instruction and instruction.subOP do
            	instruction.subOP = false -- Set to false so we can reset the state shit and cuz crazy errors.
                insert(superOP.subOP, instruction)
                i = i + 1
                instruction = chunk.code[i]
            end
            chunk.code[backTrack] = superOP
            insert(superOperators, superOP)
        else
            chunk.code[i] = instruction
            i = i + 1
        end
    end


    for _, instruction in pairs(chunk.code) do
        if instruction.OP == "SUPER" then
        	instruction.OP = 83 -- We set this to 83 since we get errors in line 33 :)
            Optimizer["SUPER"]:optimize(instruction)
        end
    end

    for _, proto in pairs(chunk.proto) do
        generateSuperOP(proto, maxSize, minSize)
    end

    return superOperators
end

-- Main function to optimize and create super operators
return function(chunk)
	if Settings.EncryptConstants then
		Logger:log("Encrypting constants ...")
		EncryptConstants(chunk)
	end

	optimizeInstructions(chunk)

	if Settings.SuperOP then
		Logger:log("Generating special OP ...")
    	local superOperators = generateSuperOP(chunk, 80, 60)
    	-- print(string.format("Created %d Super Operators!", #superOperators))
    	local miniOperators = generateSuperOP(chunk, 10)
    	-- print(string.format("Created %d Mini Operators!", #miniOperators))
    end
end