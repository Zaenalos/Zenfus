local GETFIELD = {};
GETFIELD.__index = GETFIELD;

function GETFIELD:default(instruction)
	instruction.statement = "stack[args.A] = stack[args.B][constants[args.C]];";
end

return GETFIELD;