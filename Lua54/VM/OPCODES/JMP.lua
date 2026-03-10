local JMP = {};
JMP.__index = JMP;

function JMP:default(instruction)
	local sJ = instruction.sJ
	if sJ < 0 then
		instruction.statement = "PC = PC + args.sJ;" -- SHIT IS A BACKWARD JUMP
	else
		instruction.sJ = instruction.sJ + 1; -- We add 1 for goto optimization in VM LOOP
		instruction.statement = "PC = PC + args.sJ; goto RESET;";
	end
end

return JMP;