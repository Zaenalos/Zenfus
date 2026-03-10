local MMBINK = {};
MMBINK.__index = MMBINK;

function MMBINK:default(instruction)
	instruction.statement = "";
end

return MMBINK;