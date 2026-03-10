local insert = table.insert
local concat = table.concat
local random = math.random
local rep    = string.rep

-- Indentation used in the generated VM dispatch tree.
-- "\t" = tab, "  " = 2 spaces, "" = no indent (compact output)
local INDENT = "\t"

local util       = require("util")
local MainVM     = require("Lua54.VM.MAINVM")
local Serializer = require("Lua54.BYTECODE.TOOLS.Serializer")

return (function(chunk)

	local instructions = {}

	-- Collect all non-skipped instructions from the chunk tree
	local function getStatements(proto)
		for _, instruction in pairs(proto.code) do
			if not instruction.skip then
				insert(instructions, instruction)
			end
		end
		for _, child in pairs(proto.proto) do
			getStatements(child)
		end
	end

	getStatements(chunk)

	-- Assign a unique random 26-bit hex ID to each instruction
	local usedIds = {}
	local function generateId()
		local id
		repeat id = random(0, 0xFFFFFF) until not usedIds[id]
		usedIds[id] = true
		return id
	end

	local function toHex26Bit(n)
		return string.format("0x%07X", n & 0x3FFFFFF)
	end

	for _, instruction in ipairs(instructions) do
		instruction.OP = toHex26Bit(generateId())
	end

	util.shuffle(instructions)

	-- Build a binary-search if/else dispatch tree.
	-- `depth` controls indentation level (driven by INDENT).
	local function generateIfsV2(instrs, depth)
		depth = depth or 0
		local ind  = rep(INDENT, depth)
		local ind1 = rep(INDENT, depth + 1)
		local buf  = {}

		if #instrs == 1 then
			insert(buf, ind .. instrs[1].statement)

		elseif #instrs == 2 then
			if random(2) == 2 then
				insert(buf, ind  .. "if OP > " .. instrs[1].OP .. " then")
				insert(buf, ind1 .. instrs[2].statement)
				insert(buf, ind  .. "else")
				insert(buf, ind1 .. instrs[1].statement)
			else
				insert(buf, ind  .. "if OP == " .. instrs[1].OP .. " then")
				insert(buf, ind1 .. instrs[1].statement)
				insert(buf, ind  .. "else")
				insert(buf, ind1 .. instrs[2].statement)
			end
			insert(buf, ind .. "end")

		else
			table.sort(instrs, function(a, b) return a.OP < b.OP end)
			local mid = #instrs // 2
			local left, right = {}, {}
			for i = 1, mid          do insert(left,  instrs[i]) end
			for i = mid + 1, #instrs do insert(right, instrs[i]) end

			insert(buf, ind  .. "if OP <= " .. left[#left].OP .. " then")
			insert(buf, generateIfsV2(left,  depth + 1))
			insert(buf, ind  .. "else")
			insert(buf, generateIfsV2(right, depth + 1))
			insert(buf, ind  .. "end")
		end

		return concat(buf, "\n")
	end

	-- Encode a binary string as uppercase hex
	local function stringToHex(str)
		local buf = {}
		for i = 1, #str do
			buf[i] = string.format("%02X", str:byte(i))
		end
		return concat(buf)
	end

	local newChunk = Serializer:serialize(chunk)

	local f = io.open("Output/Result.luac", "wb")
	if f then
		f:write(newChunk)
		f:close()
	end

	-- Assemble the VM dispatch loop with consistent indentation
    local startIndent = 5
    local endIndent = startIndent - 1
	local ind = rep(INDENT, startIndent)
    local endInd = rep(INDENT, endIndent)
	local generated =
		"repeat\n" ..
		ind .. "OP, args = instructions[PC].OP, regs[PC]\n" ..
		generateIfsV2(instructions, startIndent) .. "\n" ..
		ind .. "PC = PC + 1\n" ..
		endInd .. "until PC >= instSize"

	local VM = MainVM(stringToHex(newChunk), generated)

	-- Rename VM register fields to random numeric table keys
	local function randomReg()
		return "[" .. random(1, 0xFFFFFF) .. "]"
	end

	local rndRegs = {
		OP  = randomReg(),
		A   = randomReg(),
		B   = randomReg(),
		C   = randomReg(),
		Bx  = randomReg(),
		sBx = randomReg(),
		Ax  = randomReg(),
		sJ  = randomReg(),
	}

	-- Order matters: longer names (sBx, Bx) must be replaced before shorter ones (B)
	local patterns = {
		{ "|OP|",  rndRegs.OP  }, { "%.OP",  rndRegs.OP  },
		{ "|sBx|", rndRegs.sBx }, { "%.sBx", rndRegs.sBx },
		{ "|Bx|",  rndRegs.Bx  }, { "%.Bx",  rndRegs.Bx  },
		{ "|Ax|",  rndRegs.Ax  }, { "%.Ax",  rndRegs.Ax  },
		{ "|sJ|",  rndRegs.sJ  }, { "%.sJ",  rndRegs.sJ  },
		{ "|A|",   rndRegs.A   }, { "%.A",   rndRegs.A   },
		{ "|B|",   rndRegs.B   }, { "%.B",   rndRegs.B   },
		{ "|C|",   rndRegs.C   }, { "%.C",   rndRegs.C   },
	}

	for _, p in ipairs(patterns) do
		VM = VM:gsub(p[1], p[2])
	end

	return newChunk, VM
end)
