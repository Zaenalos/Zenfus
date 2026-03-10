local SETTABLE = {};
SETTABLE.__index = SETTABLE;

function SETTABLE:default(instruction)
	instruction.statement = "if args.k then C=constants[args.C]else C=stack[args.C]end;stack[args.A][stack[args.B]]=C;";
end

function SETTABLE:optimize(instruction)

	if instruction.k then
		instruction.statement = "stack[args.A][stack[args.B]] = constants[args.C];";
	else
		instruction.statement = "stack[args.A][stack[args.B]] = stack[args.C];";
	end

end

return SETTABLE;