local SHRI = {};
SHRI.__index = SHRI;

function SHRI:default(instruction)
	instruction.statement = "stack[args.A] = stack[args.B] >> (args.C - 127);";
end

function SHRI:optimize(instruction)
	local C = instruction.C
	local B = instruction.B

	instruction.FORMAT = "ABIC"
	instruction.B = C
	instruction.C = B

	instruction.statement = "stack[args.A] = stack[args.C] >> args.B;";
end

return SHRI;