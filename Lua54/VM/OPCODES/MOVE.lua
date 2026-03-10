local MOVE = {};
MOVE.__index = {};

function MOVE:default(instruction)
	instruction.statement = "stack[args.A] = stack[args.B];";
end

return MOVE;