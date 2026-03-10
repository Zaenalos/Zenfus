local TESTSET = {};
TESTSET.__index = TESTSET;

function TESTSET:default(instruction)
	instruction.statement = "if (not stack[args.B] == args.k) then PC = PC + 1; else stack[args.A] = stack[args.B]; end;";
end

function TESTSET:optimize(instruction)

	if instruction.k then
		instruction.statement = "if (not stack[args.B] == true) then PC = PC + 1; else stack[args.A] = stack[args.B]; end;";
	else
		instruction.statement = "if (not stack[args.B] == false) then PC = PC + 1; else stack[args.A] = stack[args.B]; end;";
	end

end

return TESTSET;