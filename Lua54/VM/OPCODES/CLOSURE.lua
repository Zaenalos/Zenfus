local CLOSURE = {};
CLOSURE.__index = CLOSURE;

function CLOSURE:default(instruction)
	instruction.statement = "proto=protos[args.Bx]nups=proto.nups;if nups~=0 then uvlist={}for a=1,nups do IP=PC+a;if instructions[IP].OP==0 then index=regs[IP].B;prev=openlist[index]if not prev then prev={index=index,store=stack}openlist[index]=prev end;uvlist[a-1]=prev elseif instructions[IP].OP==4 then uvlist[a-1]=upvalues[regs[IP].B]end end;PC=PC+nups;stack[args.A]=lua_wrap_state(proto,ENV,uvlist)else stack[args.A]=lua_wrap_state(proto,ENV,uvlist)end;";
end

function CLOSURE:optimize(instruction, chunk)
	local statement = "proto = protos[args.Bx];";
	local Bx = instruction.Bx;

	if chunk.proto[Bx].sizeupvalues ~= 0 then
		statement = statement .. "nups=proto.upvalueSize;uvlist={}for a=1,nups do if proto.upvalues[a-1].instack then index=proto.upvalues[a-1].idx;prev=openlist[index]if not prev then prev={index=index,store=stack}openlist[index]=prev end;uvlist[a-1]=prev else uvlist[a-1]=upvalues[proto.upvalues[a-1].idx]end end;stack[args.A]=lua_wrap_state(proto,ENV,uvlist);";
	else
		statement = statement .. "stack[args.A] = lua_wrap_state(proto, ENV, uvlist)";
	end

	instruction.statement = statement;
end

return CLOSURE;