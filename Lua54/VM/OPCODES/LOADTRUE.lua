local LOADTRUE = {};
LOADTRUE.__index = LOADTRUE;

function LOADTRUE:default(instruction)
	instruction.statement = "stack[args.A] = true;";
end

return LOADTRUE;