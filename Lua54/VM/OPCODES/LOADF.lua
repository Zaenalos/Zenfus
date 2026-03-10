local LOADF = {};
LOADF.__index = LOADF;

function LOADF:default(instruction)
	instruction.statement = "stack[args.A] = args.sBx;"
end

return LOADF;