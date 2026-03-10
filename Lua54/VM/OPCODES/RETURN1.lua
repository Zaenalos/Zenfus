local RETURN1 = {};
RETURN1.__index = RETURN1;

function RETURN1:default(instruction)
	instruction.statement = "do return stack[args.A]; end;";
end

return RETURN1;