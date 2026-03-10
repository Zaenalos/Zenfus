local ADDI = {};
ADDI.__index = ADDI;

function ADDI:default(instruction)
	instruction.statement = "stack[args.A] = stack[args.B] + (args.C - 127);";
end

function ADDI:optimize(instruction)
	-- instruction.C = (instruction.C - 127);
	instruction.FORMAT = "ABCI"
	instruction.statement = "stack[args.A] = stack[args.B] + args.C;";
end

return ADDI;