function HELP()
	return "HELP ME"
end

local function Log(msg, level)
	return msg, level
end

print("TEST: ", Log("Hello ", "World"), HELP())