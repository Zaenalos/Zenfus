local TFORLOOP = {};
TFORLOOP.__index = TFORLOOP;

function TFORLOOP:default(instruction)
	instruction.statement = "A=args.A;if stack[A+4]~=nil then stack[A+2]=stack[A+4]PC=PC-args.Bx end;";
end
return TFORLOOP;