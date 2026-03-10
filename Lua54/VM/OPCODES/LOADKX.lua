local LOADKX = {};
LOADKX.__index = LOADKX;

function LOADKX:default(instruction)
	instruction.statement = "stack[args.A] = constants[regs[PC+1].Ax]; PC = PC + 1;";
end

return LOADKX;