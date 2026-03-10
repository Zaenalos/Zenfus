local LFALSESKIP = {};
LFALSESKIP.__index = LFALSESKIP;

function LFALSESKIP:default(instruction)
	instruction.statement = "stack[args.A] = false; PC = PC + 1;";
end

return LFALSESKIP;