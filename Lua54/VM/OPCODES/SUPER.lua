local SUPER = {};
SUPER.__index = SUPER;

local insert = table.insert

function SUPER:default(instruction)
	error("SUPER OP error: This shouldn't not happen!")
end

function SUPER:optimize(instruction)
	local subOPs = {}
	local firstSub = instruction.subOP[1]
	local firstFormat = firstSub.FORMAT
	instruction.FORMAT = firstFormat
	if firstFormat == "ABC" or firstFormat == "ABIC" or firstFormat == "ABCI" then
		instruction.A = firstSub.A
		instruction.B = firstSub.B
		instruction.C = firstSub.C
	elseif firstFormat == "AsBx" then
		instruction.A = firstSub.A
		instruction.sBx = firstSub.sBx
	elseif firstFormat == "ABx" then
		instruction.A = firstSub.A
		instruction.Bx = firstSub.Bx
	elseif firstFormat == "Ax" then
		instruction.Ax = firstSub.Ax
	elseif firstFormat == "sJ" then
		instruction.sJ = firstSub.sJ
	end

	local count = 1
	for _, subs in ipairs(instruction.subOP) do
		insert(subOPs, subs.statement .. string.format("args = regs[PC + %d];", count))
		count = count + 1
	end

	insert(subOPs, "PC = PC + " ..(count-1)..";goto RESET;")
	instruction.statement = table.concat(subOPs)
	return
end

return SUPER;