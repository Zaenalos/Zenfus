local FORLOOP = {};
FORLOOP.__index = FORLOOP;

function FORLOOP:default(instruction)
	instruction.statement = "A=args.A;limit=stack[A+1]step=stack[A+2]index=stack[A]index=index+step;stack[A]=index;if step>0 and index<=limit or step<=0 and index>=limit then stack[A+3]=index;PC=PC-args.Bx end;";
end

return FORLOOP;