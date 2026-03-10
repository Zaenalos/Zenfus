local UNM = {};
UNM.__index = UNM;

function UNM:default(instruction)
	instruction.statement = "stack[args.A] = -(stack[args.B]);";
end

return UNM;