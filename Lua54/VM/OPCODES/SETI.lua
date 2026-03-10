local SETI = {};
SETI.__index = SETI;

function SETI:default(instruction)

end

function SETI:optimize(instruction)
	if instruction.k then
		instruction.statement = "stack[args.A][args.B] = constants[args.C];";
	else
		instruction.statement = "stack[args.A][args.B] = stack[args.C];";
	end
end

return SETI;