local FORPREP = {};
FORPREP.__index = FORPREP;

function FORPREP:default(instruction)
	instruction.statement = "A=args.A;init=stack[A]limit=stack[A+1]step=stack[A+2]stack[A]=init-step;stack[A+1]=limit;stack[A+2]=step;stack[A+3]=init;PC=PC+args.Bx;";
end

return FORPREP;