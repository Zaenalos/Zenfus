local LOADI = {};
LOADI.__index = LOADI;

function LOADI:default(instruction)
	instruction.statement = "stack[args.A] = args.sBx;"
end

return LOADI;