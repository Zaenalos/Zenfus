local EQI = {};
EQI.__index = EQI;

function EQI:default(instruction)
	instruction.statement = "if ((stack[args.A] == (args.B - 127)) ~= args.k) then PC = PC + 1 end;";
end

function EQI:optimize(instruction)

	if instruction.k then
		instruction.k = 0;
		-- instruction.B = instruction.B - 127
		instruction.FORMAT = "ABIC"
		instruction.statement = "if ((stack[args.A] == args.B) ~= true) then PC = PC + 1 end;";
	else
		instruction.k = 1;
		-- instruction.B = instruction.B - 127
		instruction.FORMAT = "ABIC"
		instruction.statement = "if ((stack[args.A] == args.B) ~= false) then PC = PC + 1 end;";
	end

end

return EQI;