local MMBINI = {};
MMBINI.__index = MMBINI;

function MMBINI:default(instruction)
	instruction.statement = "";
end

return MMBINI;