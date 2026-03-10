local EQ = {};
EQ.__index = EQ;

function EQ:default(instruction)
	instruction.statement = "if ((stack[args.A] == stack[args.B]) ~= args.k) then PC = PC + 1 end;";
end

function EQ:optimize(instruction)

	if instruction.k then
		instruction.k = 0;
		instruction.statement = "if ((stack[args.A] == stack[args.B]) ~= true) then PC = PC + 1 end;";
	else
		instruction.k = 1;
		instruction.statement = "if ((stack[args.A] == stack[args.B]) ~= false) then PC = PC + 1 end;";
	end

end

return EQ;