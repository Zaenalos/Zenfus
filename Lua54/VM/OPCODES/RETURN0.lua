local RETURN0 = {};
RETURN0.__index = RETURN0;

function RETURN0:default(instruction)
	instruction.statement = "do return end;";
end

return RETURN0;