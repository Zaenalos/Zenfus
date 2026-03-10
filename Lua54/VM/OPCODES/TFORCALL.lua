local TFORCALL = {};
TFORCALL.__index = TFORCALL;

function TFORCALL:default(instruction)
	instruction.statement = "A=args.A;stack[A+4],stack[A+5],stack[A+3+args.C]=stack[A](stack[A+1],stack[A+2]);";
end

return TFORCALL;