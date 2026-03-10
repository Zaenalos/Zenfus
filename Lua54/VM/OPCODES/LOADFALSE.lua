local LOADFALSE = {};
LOADFALSE.__index = LOADFALSE;

function LOADFALSE:default(instruction)
	instruction.statement = "stack[args.A] = false;";
end

return LOADFALSE;