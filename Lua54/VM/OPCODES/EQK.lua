local EQK = {};
EQK.__index = EQK;

function EQK:default(instruction)
	instruction.statement = "if ((stack[args.A] == constants[args.B]) ~= args.k) then PC = PC + 1 end;";
end

function EQK:optimize(instruction)

	if instruction.k then
		instruction.k = 0;
		instruction.statement = "if ((stack[args.A] == constants[args.B]) ~= true) then PC = PC + 1 end;";
	else
		instruction.k = 1;
		instruction.statement = "if ((stack[args.A] == constants[args.B]) ~= false) then PC = PC + 1 end;";
	end

end

return EQK;