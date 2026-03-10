local GETTABUP = {};
GETTABUP.__index = GETTABUP;

function GETTABUP:default(instruction)
	instruction.statement = "stack[args.A] = ENV[constants[args.C]];";
end

return GETTABUP;