local LOADK = {};
LOADK.__index = LOADK;

function LOADK:default(instruction)
	instruction.statement = "stack[args.A] = constants[args.Bx];";
end

return LOADK;