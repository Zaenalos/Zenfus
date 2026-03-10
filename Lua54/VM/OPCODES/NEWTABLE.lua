local NEWTABLE = {};
NEWTABLE.__index = NEWTABLE;

function NEWTABLE:default(instruction)
	instruction.statement = "stack[args.A] = ({});";
end

return NEWTABLE;