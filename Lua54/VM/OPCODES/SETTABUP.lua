local SETTABUP = {};
SETTABUP.__index = SETTABUP;

function SETTABUP:default(instruction)
	instruction.statement = "if args.k then C=constants[args.C]else C=stack[args.C]end;ENV[constants[args.B]]=C;";
end

function SETTABUP:optimize(instruction)
	if instruction.k then
		instruction.statement = "ENV[constants[args.B]] = constants[args.C];";
	else
		instruction.statement = "ENV[constants[args.B]] = stack[args.C];";
	end
end

return SETTABUP;