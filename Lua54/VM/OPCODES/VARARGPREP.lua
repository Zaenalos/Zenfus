local VARARGPREP = {};
VARARGPREP.__index = VARARGPREP;

function VARARGPREP:default(instruction)
	instruction.statement = "stack[args.A] = nil;";
end

return VARARGPREP;