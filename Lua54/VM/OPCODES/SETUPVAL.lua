local SETUPVAL = {};
SETUPVAL.__index = SETUPVAL;

function SETUPVAL:default(instruction)
	instruction.statement = "uv = upvalues[args.B]; uv.store[uv.index] = stack[args.A];";
end

return SETUPVAL;