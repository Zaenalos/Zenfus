local BNOT = {};
BNOT.__index = BNOT;

function BNOT:default(instruction)
	instruction.statement = "stack[args.A] = ~(stack[args.B]);";
end

return BNOT;