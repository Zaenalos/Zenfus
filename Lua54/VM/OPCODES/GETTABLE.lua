local GETTABLE = {};
GETTABLE.__index = GETTABLE;

function GETTABLE:default(instruction)
	instruction.statement = "stack[args.A] = stack[args.B][stack[args.C]];";
end

return GETTABLE;