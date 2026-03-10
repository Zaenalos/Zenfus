local CLOSE = {};
CLOSE.__index = CLOSE;

function CLOSE:default(instruction)
	instruction.statement = "close_lua_upvalues(openlist, args.A);";
end

return CLOSE;