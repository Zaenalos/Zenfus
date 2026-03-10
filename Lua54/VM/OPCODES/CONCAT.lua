local CONCAT = {};
CONCAT.__index = CONCAT;

function CONCAT:default(instruction)
	instruction.statement = "A=args.A;result={}for a=A,A+args.B-1 do insert(result,stack[a])end;stack[args.A]=concat(result);";
end

return CONCAT;