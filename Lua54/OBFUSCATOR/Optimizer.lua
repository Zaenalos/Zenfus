--[==[
===========================================================
If you are familiar with IB2's source code you will see the
optimizations in VM/OPCODES folder are very similar,
so yeah ...
===========================================================
]==]

local Path = "Lua54.VM.OPCODES"
local Oplist = require(Path .. ".oplist");

local Optimizer = {};

local Opname;
for i, v in pairs(Oplist) do
	Opname = Oplist[i][1];
	Optimizer[Opname] = require("Lua54.VM.OPCODES." .. Opname);
end

return Optimizer;