local NOT = {};
NOT.__index = NOT;

function NOT:default(instruction)
	instruction.statement = "stack[args.A] = not (stack[args.B]);";
end

return NOT;