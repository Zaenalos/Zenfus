local GETI = {};
GETI.__index = GETI;

function GETI:default(instruction)
	instruction.statement = "stack[args.A] = stack[args.B][args.C];";
end

return GETI;