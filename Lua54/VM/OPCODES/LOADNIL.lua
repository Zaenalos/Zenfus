local LOADNIL = {};
LOADNIL.__index = LOADNIL;

function LOADNIL:default(instruction)
	instruction.statement = "for i = args.B, 0, -1 do stack[i + args.A] = nil; end;";
end

return LOADNIL;