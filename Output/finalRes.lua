return (function(pack, move, unpack, env, pCall, Err)
    local function hexToString(hex)
        local str = ""
        for i = 1, #hex, 2 do
            local byte = tonumber(hex:sub(i, i + 1), 16)
            str = str .. string.char(byte)
        end
        return str
    end

    local insert = table.insert
    local concat = table.concat
    local byte = string.byte
    local char = string.char

    local lua_wrap_state, run_vm
    function lua_wrap_state(cache, env, upvalues)
        if env and (cache.upvalueSize == 1) and not upvalues[0] then
            local eup = {index = "value", value = env}
            eup.store = eup
            upvalues[0] = eup
        end
        return (function(...)
            local passed = pack(...)
            local passn = passed.n
            local numparams = cache.numparams
            local stack, vararg = {}, {len = 0, list = {}}
            if numparams < passn then
                local start = numparams + 1
                local len = passn - numparams
                vararg.len = len
                move(passed, start, start + len - 1, 1, vararg.list)
            end
            move(passed, 1, numparams, 0, stack)
            local res = pack(pCall(run_vm, ({vararg = vararg, stack = stack, cache = cache}), env, upvalues))
            if res[1] then
                return unpack(res, 2, res.n)
            else
                Err(res[2], 0)
            end
        end)
    end

    local loadFunction
    local code = "00000F092187011300008130520000061200008180200B000089804012000081A0200B000089806012000081B0200B00008980800112000081C020047A500C9C8F4511EE1846898020AF2D848980204BD2BB89802005000000040A1315001C0018061C3412130000000080842E4104052A130C00150402351204082E0E161A130501140100000001000100000000006872A71E01090000010E000009030000941044000089A0200300008C200E0000110300009C30000000A110350000992044000091B0200E0000110300009C4044000091B0200E00009180A0010E000091A0C00144000091904000000099204F000024E2A4BEAD10C6971BB1109EAB61BD10804E4AAC20902FE5C9403C0C74C9902073C163AC30A0B819293746FEB4700E0000B980A0010E0000B9F0C001440000B99040230000B9A0E0012E0000B9A0E001030000C48001350000B920440000A9F0200E000029030000B49001440000A9E02013000029520000060E0000B180C002030000BCB001000000C1600E0000C9808003440000C190410E0000C980A0010E0000C990C101440000C99040000000919001010000CD10000000D110010000DD104A0000CC404E0F54E970D1A94FF18001A99ED7E920CE4A85A980A1031FF07ECC504DEBF049FB447FD4700E0000D980A0010E0000D9B0C101440000D99040230000D9A0E0022E0000D9A0E001030000E48001350000D920440000C9B0210E000049030000D4D001440000C9A0210E0000C980A0010E0000C990C101440000C99040000000919001010000CD10000000D110010000DD104A0000CC20C34AA0E9D08003464A90A990A003A5F3D1CC301D7E1449C4B114D4700E0000D980A0010E0000D9B0C101440000D99040230000D9A0E0022E0000D9A0E001030000E48001350000D920440000C9B0210E000049030000D4E0010E0000D980A0010E0000D9B0C101440000D99040230000D9B0E0022E0000D9B0E001030000E48001350000D920440000C9B021460000C980210F00000004052A130C001504150A0417080E1E02123402004E23090110320C041C0A0340420F0000000000040C1315001C0018061C34125F4E040D192D2A3D343E2A530E24363A4F040235120405390D0A0D0A04050E08080B5B040129040E0924313A202E23367A35203D354204082E0E161A1305011404060915041C154C040313051D040E1D24313A202E23367A35203D3542040B0E0E110F0D4C3B1A37045F0100000001000100000000000702EC5F019AD5FB0162382027E8CCB1019CEEF78C10D2E7A5819020CFC33981100200000004052A130C001504050915041C1501000000010000000000"
    code = hexToString(code)
    local strUnpack = string.unpack
    local pos, UNPACK, getByte, get12Bits, get16Bits, get24Bits, get27Bits, get32Bits, get64Bits, loadUnsigned, loadInt, loadSize, loadString = 1

    function UNPACK(fmt, posi)
        local res, newPos = strUnpack(fmt, code, posi)
        pos = newPos
        return res
    end

    function getByte()
        local S = pos
        pos = pos + 1
        return code:byte(S, S)
    end

    function get12Bits()
        -- Extract the high and low bytes
        local highByte = getByte()
        local lowByte = getByte()

        -- Reconstruct the 12-bit number
        local num = highByte * 256 + lowByte

        -- Convert back from two's complement if necessary
        if num >= 2048 then
            num = num - 4096
        end

        return num
    end

    function get16Bits()
        return UNPACK("<I2", pos)
    end

    function get24Bits()
        return UNPACK("<I3", pos)
    end

    function loadUnsigned(limit)
        local size = 0
        local b = getByte()
        local shift = 0

        while (b & 0x80) ~= 0 do -- While the MSB is set, continue reading
            size = size | ((b & 0x7F) << shift) -- Combine the 7 bits
            shift = shift + 7
            b = getByte()
        end
        size = size | (b << shift) -- Combine the final byte
        return size
    end

    function loadSize()
        return loadUnsigned(4294967295)
    end

    function loadInt()
        return loadUnsigned(math.maxinteger)
    end

    function get32Bits()
        return UNPACK("<I4", pos)
    end

    function get64Bits()
        return UNPACK("<I8", pos)
    end

    function loadString()
        return UNPACK("c" .. loadSize(), pos)
    end

    local sizeType = 3
    local sizeB = 8
    local sizeA = 8
    local sizeC = 8
    local sizeBx = 16
    local sizeSbx = sizeBx
    -- Shifting positions
    local typeShift = 0
    local Ashift = (typeShift + sizeType)
    local Bshift = (Ashift + sizeA)
    local Cshift = (Bshift + sizeB)
    local Bxshift = Bshift
    local sBxshift = Bxshift
    local max = 2 ^ (16 - 1)

    local function convertValue(value, bits)
        local max_unsigned = 2 ^ bits - 1
        local max_signed = 2 ^ (bits - 1) - 1
        local min_signed = -2 ^ (bits - 1)

        if value < 0 then
            -- Convert signed to unsigned
            return value + 2 ^ bits
        elseif value > max_signed then
            -- Convert unsigned to signed
            return value - 2 ^ bits
        else
            -- Value is already within signed range
            return value
        end
    end

    local function decodeInsts()
        --local opcode = (instruction >> OPshift) & ((1 << 6) - 1)
        local opcode, instruction, A, B, C, Bx, sBx, Ax, sJ = get24Bits(), loadInt()

        local format = (instruction >> 0) & 0x7
        if format == 1 then
            A = (instruction >> Ashift) & 0xFF
            --assert(A == (instruction // 64) % 256)
            B = (instruction >> Bshift) & 0xFF
            --assert(B == (instruction // 2 ^ 23))
            C = (instruction >> Cshift) & 0xFF

            return {[9140442] = opcode, [16236138] = A, [16424342] = B, [6238881] = C}
        elseif format == 2 then
            A = (instruction >> Ashift) & 0xFF
            --assert(A == (instruction // 64) % 256)
            B = ((instruction >> Bshift) & 0xFF) - 127
            --assert(B == (instruction // 2 ^ 23))
            C = (instruction >> Cshift) & 0xFF

            return {[9140442] = opcode, [16236138] = A, [16424342] = B, [6238881] = C}
        elseif format == 3 then
            A = (instruction >> Ashift) & 0xFF
            --assert(A == (instruction // 64) % 256)
            B = (instruction >> Bshift) & 0xFF
            --assert(B == (instruction // 2 ^ 23))
            C = ((instruction >> Cshift) & 0xFF) - 127

            return {[9140442] = opcode, [16236138] = A, [16424342] = B, [6238881] = C}
        elseif format == 4 then
            A = (instruction >> Ashift) & 0xFF
            Bx = (instruction >> Bxshift) & 0xFFFF

            return {[9140442] = opcode, [16236138] = A, [8670154] = Bx}
        elseif format == 5 then
            A = (instruction >> Ashift) & 0xFF
            sBx = convertValue((instruction >> sBxshift) & 0xFFFF, 16)

            return {[9140442] = opcode, [16236138] = A, [2403693] = sBx}
        elseif format == 6 then
            Ax = instruction >> Ashift & 0x1FFFFFF

            return {[9140442] = opcode, [7216519] = Ax,}
        elseif format == 7 then
            sJ = convertValue(instruction >> Ashift & 0x1FFFFFF, 24)

            return {[9140442] = opcode, [6974634] = sJ,}
        end
    end

    local function luaF_newproto()
        local f = {
            numparams = 0,
            isvararg = 0,
            maxstacksize = 0,
            codeSize = 0,
            code = {},
            constSize = 0,
            constants = {},
            protoSize = 0,
            proto = {},
            upvalueSize = 0,
            upvalues = {}
        }
        return f
    end

    local function loadCode(f)
        local n = get12Bits()
        --print("INSTRUCTION SIZE:", n)
        f.sizeCode = n
        for i = 1, n do
            f.code[i - 1] = decodeInsts()
        end
    end

    local function loadConstants(f)
        local n = get32Bits()
        local o, type
        f.conSize = n
        for i = 1, n do
            type = getByte()
            if type == 0 then
                o = nil
            elseif type == 1 then
                o = false
            elseif type == 17 then
                o = true
            elseif type == 19 then
                o = UNPACK("n", pos)
            elseif type == 3 then
                o = UNPACK("j", pos)
            elseif type == 4 or type == 20 then
                o = (function(input, key)
                    local output, key_byte, input_byte, encrypted_byte = {}
                    for i = 1, #input do
                        key_byte = byte(key, (i - 1) % #key + 1)
                        input_byte = byte(input, i)
                        encrypted_byte = (input_byte ~ key_byte)
                        output[i] = char(encrypted_byte)
                    end
                    return concat(output)
                end)(loadString(), "Zaenalos")
            end
            f.constants[i - 1] = o
        end
    end

    local function loadProtos(f)
        local n = get32Bits()
        f.protoSize = n
        for i = 1, n do
            f.proto[i - 1] = luaF_newproto()
            loadFunction(f.proto[i - 1])
        end
    end

    local function loadUpvalues(f)
        local n = get32Bits()
        f.upvalueSize = n
        for i = 1, n do
            f.upvalues[i - 1] = {instack = getByte() ~= 0, idx = getByte()}
        end
    end

    function loadFunction(p)
        p.numparams = getByte()
        loadCode(p)
        loadConstants(p)
        loadUpvalues(p)
        loadProtos(p)
    end

    local chunk = luaF_newproto()
    loadFunction(chunk)

    local function close_lua_upvalues(list, index)
        for i, uv in pairs(list) do
            if uv.index >= index then
                uv.value = uv.store[uv.index]
                uv.store = uv
                uv.index = "value"
                list[i] = nil
            end
        end
    end

    return (function()
        do
            run_vm = function(state, env, upvalues)
                local cache = state.cache
                local constants = cache.constants
                local instructions, regs = cache.code, cache.code
                local instSize = cache.sizeCode
                local protos = cache.proto
                local stack = state.stack
                local PC = 0
                local vararg = state.vararg
                local openlist = {}
                local ENV = env
                local top = -1
                local A, B, C, SBX, step, init, index, limit, loops, OP, args, proto, nups, uvlist, fun, uv, result, offset, tab, retnum, retlist, IP, index, prev, idx
                ::RESET::
                repeat
					OP, args = instructions[PC][9140442], regs[PC]
					if OP <= 0x0740C3C then
						if OP <= 0x0458F9C then
							if OP <= 0x01B97C6 then
								if OP <= 0x014B1C4 then
									if OP == 0x0147E1D then
										stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];
									else
										stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 1];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 2];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 3];A = args[16236138];retlist = {stack[A]()}; stack[A] = retlist[1];args = regs[PC + 4];stack[args[6238881]] = stack[args[16236138]] - stack[args[16424342]];args = regs[PC + 5];args = regs[PC + 6];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 7];A=args[16236138];result={}for a=A,A+args[16424342]-1 do insert(result,stack[a])end;stack[args[16236138]]=concat(result);args = regs[PC + 8];A = args[16236138];retlist = {stack[A](unpack(stack, A + 1, args[16424342]))}; args = regs[PC + 9];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 10];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 11];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 12];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 13];A = args[16236138];retlist = {stack[A]()}; stack[A] = retlist[1];args = regs[PC + 14];stack[args[6238881]] = stack[args[16236138]] - stack[args[16424342]];args = regs[PC + 15];args = regs[PC + 16];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 17];A=args[16236138];result={}for a=A,A+args[16424342]-1 do insert(result,stack[a])end;stack[args[16236138]]=concat(result);args = regs[PC + 18];A = args[16236138];retlist = {stack[A](unpack(stack, A + 1, args[16424342]))}; args = regs[PC + 19];A = args[16236138];close_lua_upvalues(openlist, 0);do return unpack(stack, A, args[16424342]); end;args = regs[PC + 20];PC = PC + 20;goto RESET;
									end
								else
									if OP == 0x019B8A0 then
										stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];
									else
										stack[args[16236138]] = stack[args[16424342]];
									end
								end
							else
								if OP <= 0x0203862 then
									if OP > 0x01EA772 then
										PC = PC + args[6974634]; goto RESET;
									else
										stack[args[16236138]] = nil;args = regs[PC + 1];uv = upvalues[args[16424342]]; stack[args[16236138]] = uv.store[uv.index];args = regs[PC + 2];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 3];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 4];A = args[16236138];retlist = {stack[A](stack[A + 1])}; args = regs[PC + 5];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 6];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 7];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 8];stack[args[16236138]] = stack[args[16424342]];args = regs[PC + 9];A=args[16236138];result={}for a=A,A+args[16424342]-1 do insert(result,stack[a])end;stack[args[16236138]]=concat(result);args = regs[PC + 10];A = args[16236138];retlist = {stack[A](stack[A + 1])}; args = regs[PC + 11];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 12];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 13];A = args[16236138];retlist = {stack[A](stack[A + 1])}; args = regs[PC + 14];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 15];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 16];A = args[16236138];retlist = {stack[A]()}; stack[A] = retlist[1];args = regs[PC + 17];stack[args[16236138]] = stack[args[16424342]];args = regs[PC + 18];proto = protos[args[8670154]];nups=proto.upvalueSize;uvlist={}for a=1,nups do if proto.upvalues[a-1].instack then index=proto.upvalues[a-1].idx;prev=openlist[index]if not prev then prev={index=index,store=stack}openlist[index]=prev end;uvlist[a-1]=prev else uvlist[a-1]=upvalues[proto.upvalues[a-1].idx]end end;stack[args[16236138]]=lua_wrap_state(proto,ENV,uvlist);args = regs[PC + 19];PC = PC + 19;goto RESET;
									end
								else
									if OP > 0x039C3CF then
										A = args[16236138]; C = args[6238881];C = vararg.len; top = A + C - 1; move(vararg.list, 1, C, A, stack);
									else
										do return end;
									end
								end
							end
						else
							if OP <= 0x0507A04 then
								if OP <= 0x04A4E80 then
									if OP == 0x04618EE then
										A = args[16236138];close_lua_upvalues(openlist, 0);do return stack[A](unpack(stack, A + 1, A + (top - A))); end;
									else
										A=args[16236138];init=stack[A]limit=stack[A+1]step=stack[A+2]stack[A]=init-step;stack[A+1]=limit;stack[A+2]=step;stack[A+3]=init;PC=PC+args[8670154];
									end
								else
									if OP == 0x04FA9D1 then
										stack[args[16236138]] = stack[args[16424342]];
									else
										proto = protos[args[8670154]];nups=proto.upvalueSize;uvlist={}for a=1,nups do if proto.upvalues[a-1].instack then index=proto.upvalues[a-1].idx;prev=openlist[index]if not prev then prev={index=index,store=stack}openlist[index]=prev end;uvlist[a-1]=prev else uvlist[a-1]=upvalues[proto.upvalues[a-1].idx]end end;stack[args[16236138]]=lua_wrap_state(proto,ENV,uvlist);
									end
								end
							else
								if OP <= 0x05FEC02 then
									if OP > 0x0540F4E then
										stack[args[16236138]] = false;
									else
										stack[args[16236138]] = stack[args[16424342]];
									end
								else
									if OP <= 0x061AB9E then
										stack[args[16236138]] = args[2403693];
									else
										if OP == 0x063C173 then
											A=args[16236138];limit=stack[A+1]step=stack[A+2]index=stack[A]index=index+step;stack[A]=index;if step>0 and index<=limit or step<=0 and index>=limit then stack[A+3]=index;PC=PC-args[8670154] end;
										else
											A = args[16236138];retlist = {stack[A]()}; 
										end
									end
								end
							end
						end
					else
						if OP <= 0x0B1CCE8 then
							if OP <= 0x0854ACE then
								if OP <= 0x07F44FB then
									if OP > 0x07EF01F then
										stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 1];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 2];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 3];A = args[16236138];retlist = {stack[A]()}; stack[A] = retlist[1];args = regs[PC + 4];stack[args[6238881]] = stack[args[16236138]] - stack[args[16424342]];args = regs[PC + 5];args = regs[PC + 6];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 7];A=args[16236138];result={}for a=A,A+args[16424342]-1 do insert(result,stack[a])end;stack[args[16236138]]=concat(result);args = regs[PC + 8];A = args[16236138];retlist = {stack[A](unpack(stack, A + 1, args[16424342]))}; args = regs[PC + 9];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 10];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 11];A = args[16236138];retlist = {stack[A](stack[A + 1])}; args = regs[PC + 12];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 13];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 14];A = args[16236138];retlist = {stack[A]()}; stack[A] = retlist[1];args = regs[PC + 15];stack[args[16236138]] = stack[args[16424342]];args = regs[PC + 16];stack[args[16236138]] = args[2403693];args = regs[PC + 17];stack[args[16236138]] = stack[args[16424342]];args = regs[PC + 18];stack[args[16236138]] = args[2403693];args = regs[PC + 19];A=args[16236138];init=stack[A]limit=stack[A+1]step=stack[A+2]stack[A]=init-step;stack[A+1]=limit;stack[A+2]=step;stack[A+3]=init;PC=PC+args[8670154];args = regs[PC + 20];PC = PC + 20;goto RESET;
									else
										A=args[16236138];limit=stack[A+1]step=stack[A+2]index=stack[A]index=index+step;stack[A]=index;if step>0 and index<=limit or step<=0 and index>=limit then stack[A+3]=index;PC=PC-args[8670154] end;
									end
								else
									if OP == 0x0842DAF then
										A = args[16236138];close_lua_upvalues(openlist, 0);B = top; do return unpack(stack, A, B); end;
									else
										stack[args[16236138]][stack[args[16424342]]] = stack[args[6238881]];
									end
								end
							else
								if OP <= 0x0904A46 then
									if OP > 0x0872109 then
										stack[args[16236138]][args[16424342]] = stack[args[6238881]];
									else
										stack[args[16236138]] = nil;args = regs[PC + 1];stack[args[16236138]] = ({});args = regs[PC + 2];args = regs[PC + 3];stack[args[16236138]][constants[args[16424342]]] = constants[args[6238881]];args = regs[PC + 4];stack[args[16236138]] = ENV[constants[args[6238881]]];args = regs[PC + 5];stack[args[16236138]][constants[args[16424342]]] = stack[args[6238881]];args = regs[PC + 6];stack[args[16236138]] = ENV[constants[args[6238881]]];args = regs[PC + 7];stack[args[16236138]][constants[args[16424342]]] = stack[args[6238881]];args = regs[PC + 8];stack[args[16236138]] = ENV[constants[args[6238881]]];args = regs[PC + 9];stack[args[16236138]][constants[args[16424342]]] = stack[args[6238881]];args = regs[PC + 10];PC = PC + 10;goto RESET;
									end
								else
									if OP <= 0x0A04AC3 then
										stack[args[16236138]] = stack[args[16424342]][stack[args[6238881]]];
									else
										if OP > 0x0A5E7D2 then
											stack[args[16236138]] = ENV[constants[args[6238881]]];
										else
											A = args[16236138];retlist = {stack[A](stack[A + 1])}; 
										end
									end
								end
							end
						else
							if OP <= 0x0D79EA9 then
								if OP <= 0x0BEA4E2 then
									if OP == 0x0BBD24B then
										A = args[16236138];close_lua_upvalues(openlist, 0);do return unpack(stack, A, args[16424342]); end;
									else
										stack[args[16236138]] = args[2403693];
									end
								else
									if OP > 0x0D1F3A5 then
										A=args[16236138];result={}for a=A,A+args[16424342]-1 do insert(result,stack[a])end;stack[args[16236138]]=concat(result);
									else
										A=args[16236138];limit=stack[A+1]step=stack[A+2]index=stack[A]index=index+step;stack[A]=index;if step>0 and index<=limit or step<=0 and index>=limit then stack[A+3]=index;PC=PC-args[8670154] end;
									end
								end
							else
								if OP <= 0x0F0EB4D then
									if OP > 0x0E52F90 then
										stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];
									else
										stack[args[16236138]] = stack[args[16424342]];
									end
								else
									if OP <= 0x0F7EE9C then
										stack[args[16236138]] = constants[args[8670154]];
									else
										if OP == 0x0FBD59A then
											if (not stack[args[16236138]] == false) then PC = PC + 1; end;
										else
											stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 1];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 2];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 3];A = args[16236138];retlist = {stack[A]()}; stack[A] = retlist[1];args = regs[PC + 4];stack[args[6238881]] = stack[args[16236138]] - stack[args[16424342]];args = regs[PC + 5];args = regs[PC + 6];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 7];A=args[16236138];result={}for a=A,A+args[16424342]-1 do insert(result,stack[a])end;stack[args[16236138]]=concat(result);args = regs[PC + 8];A = args[16236138];retlist = {stack[A](unpack(stack, A + 1, args[16424342]))}; args = regs[PC + 9];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 10];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 11];A = args[16236138];retlist = {stack[A](stack[A + 1])}; args = regs[PC + 12];stack[args[16236138]] = ({});args = regs[PC + 13];args = regs[PC + 14];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 15];stack[args[16236138]] = constants[args[8670154]];args = regs[PC + 16];stack[args[16236138]] = stack[args[16424342]];args = regs[PC + 17];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 18];A = args[16236138];retlist = {stack[A](stack[A + 1])}; stack[A] = retlist[1];args = regs[PC + 19];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 20];stack[args[16236138]] = stack[args[16424342]][constants[args[6238881]]];args = regs[PC + 21];A = args[16236138];retlist = {stack[A]()}; stack[A] = retlist[1];args = regs[PC + 22];stack[args[16236138]] = stack[args[16424342]];args = regs[PC + 23];stack[args[16236138]] = args[2403693];args = regs[PC + 24];stack[args[16236138]] = stack[args[16424342]];args = regs[PC + 25];stack[args[16236138]] = args[2403693];args = regs[PC + 26];A=args[16236138];init=stack[A]limit=stack[A+1]step=stack[A+2]stack[A]=init-step;stack[A+1]=limit;stack[A+2]=step;stack[A+3]=init;PC=PC+args[8670154];args = regs[PC + 27];PC = PC + 27;goto RESET;
										end
									end
								end
							end
						end
					end
					PC = PC + 1
				until PC >= instSize
            end
            return lua_wrap_state(chunk, env, {})()
        end
    end)()
end)(table.pack, table.move, table.unpack, _ENV, pcall, error)
