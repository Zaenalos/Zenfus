local MMBIN = {};
MMBIN.__index = MMBIN;

function MMBIN:default(instruction)
	instruction.statement = "";
end

return MMBIN;