local LEN = {};
LEN.__index = LEN;

function LEN:default(instruction)
	instruction.statement = "stack[args.A] = #(stack[args.B]);";
end

return LEN;