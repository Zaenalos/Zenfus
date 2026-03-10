local SETFIELD = {};
SETFIELD.__index = SETFIELD;

function SETFIELD:default(instruction)

end

function SETFIELD:optimize(instruction)
	if instruction.k then
		instruction.statement = "stack[args.A][constants[args.B]] = constants[args.C];";
	else
		instruction.statement = "stack[args.A][constants[args.B]] = stack[args.C];";
	end
end

return SETFIELD;