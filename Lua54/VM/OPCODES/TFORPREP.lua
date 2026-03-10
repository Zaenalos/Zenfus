local TFORPREP = {};
TFORPREP.__index = TFORPREP;

function TFORPREP:default(instruction)
	instruction.statement = "stack[A + 3] = nil; PC = PC + args.Bx;";
end

return TFORPREP;