local TEST = {};
TEST.__index = TEST;

function TEST:default(instruction)
	instruction.statement = "if (not stack[args.A] == args.k) then PC = PC + 1; end;";
end

function TEST:optimize(instruction)

	if instruction.k then
		instruction.statement = "if (not stack[args.A] == true) then PC = PC + 1; end;";
	else
		instruction.statement = "if (not stack[args.A] == false) then PC = PC + 1; end;";
	end

end

return TEST;