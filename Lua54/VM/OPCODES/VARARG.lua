local VARARG = {};
VARARG.__index = VARARG;

function VARARG:default(instruction)
	instruction.statement = "A=args.A;C=args.C;if C==0 then C=vararg.len;top=A+C-1 end;move(vararg.list,1,C,A,stack);";
end

function VARARG:optimize(instruction)
	local C = instruction.C;
	local statement = "A = args.A; C = args.C;";

	if C == 0 then
		statement = statement .. "C = vararg.len; top = A + C - 1; move(vararg.list, 1, C, A, stack);";
	else
		statement = "move(vararg.list, 1, args.C, args.A, stack);";
	end

	instruction.statement = statement;
end

return VARARG;