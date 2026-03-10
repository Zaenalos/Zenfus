local logger = {}
local config = require("config")
local colors = require("colors")

logger.LogLevel = {
	Error = 0,
	Warn  = 1,
	Log   = 2,
	Info  = 2,
	Debug = 3,
}

logger.logLevel = logger.LogLevel.Log

-- ─── Level callbacks ─────────────────────────────────────────────────────────

function logger:debug(msg)
	if self.logLevel >= self.LogLevel.Debug then
		print(colors(config.NameUpper .. " [DBG] ", "magenta") .. tostring(msg))
	end
end

function logger:log(msg)
	if self.logLevel >= self.LogLevel.Log then
		print(colors(config.NameUpper .. ": ", "cyan") .. colors(tostring(msg), "green"))
	end
end

function logger:info(msg)
	self:log(msg)
end

function logger:warn(msg)
	if self.logLevel >= self.LogLevel.Warn then
		print(colors(config.NameUpper .. " [WARN] " .. tostring(msg), "yellow"))
	end
end

-- Prints a red error and raises a Lua error (includes traceback for debugging).
-- Use logger:fatal() for clean user-facing exits instead.
function logger:error(msg)
	print(colors(config.NameUpper .. " [ERR] " .. tostring(msg), "red"))
	error(tostring(msg), 0)
end

-- Prints a red error and exits cleanly (no Lua traceback).
-- Use this for expected failure conditions rather than internal bugs.
function logger:fatal(msg)
	io.stderr:write(colors(config.NameUpper .. ": ", "red") .. tostring(msg) .. "\n")
	os.exit(1)
end

return logger
