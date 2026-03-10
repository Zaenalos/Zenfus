local SELF = {};
SELF.__index = SELF;

function SELF:default(instruction)
	instruction.statement = "A=args.A;B=args.B;if args.k then C=constants[args.C]else C=stack[args.C]end;stack[A+1]=stack[B]stack[A]=stack[B][C];";
end

function SELF:optimize(instruction)
	local statement = "A = args.A; B = args.B; "
	if instruction.k then -- C IS CONSTANT
		statement = statement .. "stack[A+1] = stack[B]; stack[A] = stack[B][constants[args.C]];";
	else
		statement = statement .. "stack[A+1] = stack[B]; stack[A] = stack[B][stack[args.C]];";
	end

	instruction.statement = statement
end

return SELF;