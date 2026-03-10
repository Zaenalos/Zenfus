local TBC = {};
TBC.__index = TBC;

function TBC:default(instruction)
	instruction.statement = "";
end

return TBC;