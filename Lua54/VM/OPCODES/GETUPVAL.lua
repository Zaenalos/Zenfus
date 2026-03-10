local GETUPVAL = {};
GETUPVAL.__index = GETUPVAL;

function GETUPVAL:default(instruction)
	instruction.statement = "uv = upvalues[args.B]; stack[args.A] = uv.store[uv.index];";
end

return GETUPVAL;