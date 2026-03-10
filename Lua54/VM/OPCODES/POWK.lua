local POWK = {};
POWK.__index = POWK;

function POWK:default(instruction)
	instruction.statement = "stack[args.A] = stack[args.B] ^ constants[args.C];";
end

function POWK:optimize(instruction)
	local B = instruction.B;
	local C = instruction.C;

	instruction.B = C;
	instruction.C = B;

	instruction.statement = "stack[args.A] = stack[args.C] ^ constants[args.B];";
end

return POWK;