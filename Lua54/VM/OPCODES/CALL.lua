local CALL = {};
CALL.__index = CALL;

function CALL:default(instruction)
	instruction.statement = "";
end

function CALL:optimize(instruction)
	local A = instruction.A;
	local B = instruction.B;
	local C = instruction.C;
	local statement = "A = args.A;";

	if B == 0 then
		statement = statement .. "retlist = {stack[A](unpack(stack, A + 1, top))};"; -- (top - A + A)
	elseif B == 1 then
		statement = statement .. "retlist = {stack[A]()};";
	elseif B == 2 then
		instruction.B = A + B - 1; -- idunno if this is necessary
		statement = statement .. "retlist = {stack[A](stack[A + 1])};";
	elseif B > 2 then
		instruction.B = A + B - 1;
		statement = statement .. "retlist = {stack[A](unpack(stack, A + 1, args.B))};";
	end

	if C == 0 then
		statement = statement .. " retnum = #retlist; top = A + retnum - 1; move(retlist, 1, retnum, A, stack);";
	elseif C == 1 then
		statement = statement .. " "; -- NO RETURN
	elseif C == 2 then
		statement = statement .. " stack[A] = retlist[1];";
	elseif C > 2 then
		instruction.C = C - 1;
		statement = statement .. " retnum = args.C; move(retlist, 1, retnum, A, stack);";
	end

	instruction.statement = statement;
end

return CALL;