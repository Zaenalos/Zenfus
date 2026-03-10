local DIVK = {};
DIVK.__index = DIVK;

function DIVK:default(instruction)
	instruction.statement = "stack[args.A] = stack[args.B] / constants[args.C];";
end

function DIVK:optimize(instruction)
	local B = instruction.B;
	local C = instruction.C;

	instruction.B = C;
	instruction.C = B;

	instruction.statement = "stack[args.A] = stack[args.C] / constants[args.B];";
end

return DIVK;