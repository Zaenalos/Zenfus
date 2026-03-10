local EXTRAARG = {};
EXTRAARG.__index = EXTRAARG;

function EXTRAARG:default(instruction)
	instruction.statement = "";
end

return EXTRAARG;