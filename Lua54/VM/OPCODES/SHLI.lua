local SHLI = {};
SHLI.__index = SHLI;

function SHLI:default(instruction)
	instruction.statement = "stack[args.A] = (args.C - 127) << stack[args.B];";
end

function SHLI:optimize(instruction)
	local C = instruction.C
	local B = instruction.B

	instruction.FORMAT = "ABIC"
	instruction.B = C
	instruction.C = B

	instruction.statement = "stack[args.A] = args.B << stack[args.C];";
end

return SHLI;