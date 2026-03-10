local SETLIST = {};
SETLIST.__index = SETLIST;

function SETLIST:default(instruction)
	instruction.statement = "A = args.A; C = args.C; for i = 1, args.B do stack[A][C + i] = stack[A + i]; end;";
end

return SETLIST;