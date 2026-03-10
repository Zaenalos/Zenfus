local TAILCALL = {};
TAILCALL.__index = TAILCALL;

function TAILCALL:default(instruction)
end

function TAILCALL:optimize(instruction)
	local A = instruction.A;
	local B = instruction.B;
	local statement = "A = args.A;";

	if instruction.k then
		statement = statement .. "close_lua_upvalues(openlist, 0);";
	end

	if B == 0 then
		statement = statement .. "do return stack[A](unpack(stack, A + 1, A + (top - A))); end;";
	elseif B == 1 then
		statement = statement .. "do return stack[A](); end;";
	else
		instruction.B = A + (B - 1);
		statement = statement .. "do return stack[A](unpack(stack, A + 1, args.B)); end;";
	end

	instruction.statement = statement;
end

return TAILCALL;