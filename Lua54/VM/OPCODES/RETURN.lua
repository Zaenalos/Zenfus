local RETURN = {};
RETURN.__index = RETURN;

function RETURN:default(instruction)

end

function RETURN:optimize(instruction)
	local B = instruction.B;
	local A = instruction.A;
	local statement = "A = args.A;";

	if instruction.k then
		statement = statement .. "close_lua_upvalues(openlist, 0);";
	end

	if B == 0 then
		statement = statement .. "B = top; do return unpack(stack, A, B); end;";
	else
		instruction.B = A + (B - 1) - 1;
		statement = statement .. "do return unpack(stack, A, args.B); end;";
	end

	instruction.statement = statement;
end

return RETURN;