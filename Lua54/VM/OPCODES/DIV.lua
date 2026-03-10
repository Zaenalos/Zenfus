local DIV = {};
DIV.__index = DIV;

function DIV:default(instruction)
	instruction.statement = "stack[args.A] = stack[args.B] / stack[args.C];";
end

function DIV:optimize(instruction)
	local A = instruction.A;
	local B = instruction.B;
	local C = instruction.C;

	instruction.A = B;
	instruction.C = A;
	instruction.B = C;

	instruction.statement = "stack[args.C] = stack[args.A] / stack[args.B];";
end

return DIV;