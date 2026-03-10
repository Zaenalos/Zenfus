
return(function()
local u,v = nil, 99; 
local function p() 
	u = 1;
	print("U value: ", u)
	local function q() 
		print("V value: ", v)
		return v 
	end 
	return q()
end

local function noNups()
	print("\nNo nups execution\n")
	local SH = function(...)
		return "HEHE\n"
	end
	return SH
end

local function returnTable()
	local MJ27 = function(A, ...)
		return (A(...))
	end
	print("TESTING RETURN", MJ27)
	return MJ27
end

print("\nClosure test: ", p())
print("\nFunction Literal test\n");

local res, status = pcall(function()
	return returnTable()(table.unpack, {"Hello ", "World "})
end)

assert(res)
print("\nTEST PASSED!", status, "\n")
print(noNups()())
end)()