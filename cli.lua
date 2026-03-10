-- Zenfus CLI - Lua Obfuscator
local Config   = require("config")
local Colors   = require("colors")
local Logger   = require("logger")

-- ─── Argument Parser ─────────────────────────────────────────────────────────

local function parseArgs(args)
	local opts = {
		input       = nil,
		output      = "Output/finalRes.lua",
		luaVersion  = nil,
		help        = false,
		showVersion = false,
		debug       = false,
		noColor     = false,
	}

	local i = 1
	while i <= #args do
		local a = args[i]

		if a == "-h" or a == "--help" then
			opts.help = true

		elseif a == "--version" then
			opts.showVersion = true

		elseif a == "--debug" then
			opts.debug = true

		elseif a == "--no-color" then
			opts.noColor = true

		elseif a == "-i" or a == "--input" then
			i = i + 1
			if not args[i] then
				io.stderr:write("Error: " .. a .. " requires a value\n")
				os.exit(1)
			end
			opts.input = args[i]

		elseif a == "-o" or a == "--output" then
			i = i + 1
			if not args[i] then
				io.stderr:write("Error: " .. a .. " requires a value\n")
				os.exit(1)
			end
			opts.output = args[i]

		elseif a == "-V" or a == "--lua-version" then
			i = i + 1
			if not args[i] then
				io.stderr:write("Error: " .. a .. " requires a value\n")
				os.exit(1)
			end
			opts.luaVersion = args[i]

		elseif a:sub(1, 1) ~= "-" then
			-- Legacy positional: first = version, second = input file
			if not opts.luaVersion then
				opts.luaVersion = a
			elseif not opts.input then
				opts.input = a
			else
				io.stderr:write("Unexpected argument: " .. a .. "\n")
				io.stderr:write("Run with --help for usage.\n")
				os.exit(1)
			end

		else
			io.stderr:write("Unknown option: " .. a .. "\n")
			io.stderr:write("Run with --help for usage.\n")
			os.exit(1)
		end

		i = i + 1
	end

	return opts
end

-- ─── Version Aliases ─────────────────────────────────────────────────────────

local VERSION_ALIASES = {
	["54"]    = "Lua54", ["5.4"]  = "Lua54",
	["Lua54"] = "Lua54", ["lua54"] = "Lua54",
	["53"]    = "Lua53", ["5.3"]  = "Lua53",
	["Lua53"] = "Lua53", ["lua53"] = "Lua53",
	["52"]    = "Lua52", ["5.2"]  = "Lua52",
	["Lua52"] = "Lua52", ["lua52"] = "Lua52",
	["51"]    = "Lua51", ["5.1"]  = "Lua51",
	["Lua51"] = "Lua51", ["lua51"] = "Lua51",
}

local LUAC_BINARIES = {
	Lua54 = "luac5.4",
	Lua53 = "luac5.3",
	Lua52 = "luac5.2",
	Lua51 = "luac5.1",
}

-- ─── Help Text ───────────────────────────────────────────────────────────────

local function showHelp()
	local c = Colors

	print(c(Config.NameAndVersion, "cyan", "bright") .. " - Lua Obfuscator by " .. c(Config.Author, "magenta"))
	print("")

	print(c("USAGE", "yellow", "bright"))
	print("  lua cli.lua [OPTIONS] <lua-version> <input-file>")
	print("  lua cli.lua [OPTIONS] -V <lua-version> -i <input-file>")
	print("")

	print(c("ARGUMENTS", "yellow", "bright"))
	print("  <lua-version>   Lua version to target  (54, 5.4, Lua54 ...)")
	print("  <input-file>    Lua source file to obfuscate")
	print("                  Bare filenames are resolved from Inputs/")
	print("")

	print(c("OPTIONS", "yellow", "bright"))
	print("  -h, --help              Show this help message and exit")
	print("      --version           Print " .. Config.Name .. " version and exit")
	print("  -V, --lua-version <v>   Lua version to target")
	print("  -i, --input <file>      Input Lua source file")
	print("  -o, --output <file>     Output file  [default: Output/finalRes.lua]")
	print("      --debug             Enable verbose/debug logging")
	print("      --no-color          Disable colored output")
	print("")

	print(c("EXAMPLES", "yellow", "bright"))
	print("  lua cli.lua 54 BasicTest.lua")
	print("  lua cli.lua 54 BasicTest.lua -o Output/result.lua")
	print("  lua cli.lua -V 5.4 -i Inputs/script.lua -o out.lua")
	print("  lua cli.lua 54 myscript.lua --debug")
	print("")

	print(c("SUPPORTED LUA VERSIONS", "yellow", "bright"))
	print("  " .. c("54  5.4  Lua54", "green")  .. "    fully supported")
	print("  " .. c("53  5.3  Lua53", "grey")   .. "    planned")
	print("  " .. c("52  5.2  Lua52", "grey")   .. "    planned")
	print("  " .. c("51  5.1  Lua51", "grey")   .. "    planned")
	print("")
end

-- ─── Banner ──────────────────────────────────────────────────────────────────

local function showBanner()
	local c = Colors
	print(c([==[
███████╗███████╗███╗░░██╗███████╗██╗░░░██╗░██████╗
╚════██║██╔════╝████╗░██║██╔════╝██║░░░██║██╔════╝
░░███╔═╝█████╗░░██╔██╗██║█████╗░░██║░░░██║╚█████╗░
██╔══╝░░██╔══╝░░██║╚████║██╔══╝░░██║░░░██║░╚═══██╗
███████╗███████╗██║░╚███║██║░░░░░╚██████╔╝██████╔╝
╚══════╝╚══════╝╚═╝░░╚══╝╚═╝░░░░░░╚═════╝░╚═════╝░]==], "cyan"))
	print("  " .. c(Config.NameAndVersion, "white", "bright") ..
	      "  " .. c("by " .. Config.Author, "magenta") ..
	      "  " .. c("Lua Obfuscator", "grey"))
	print("")
end

-- ─── Utilities ───────────────────────────────────────────────────────────────

local function fileExists(path)
	local f = io.open(path, "r")
	if f then f:close(); return true end
	return false
end

local function fail(msg)
	io.stderr:write(Colors(Config.Name .. ": ", "red") .. msg .. "\n")
	os.exit(1)
end

-- ─── Entry Point ─────────────────────────────────────────────────────────────

local opts = parseArgs(arg)

-- Apply --no-color first so all subsequent output respects it
if opts.noColor then
	Colors.enabled = false
end

if opts.showVersion then
	print(Config.NameAndVersion)
	os.exit(0)
end

if opts.help then
	showHelp()
	os.exit(0)
end

-- Clear and show banner only for normal runs
os.execute("chcp 65001 > NUL 2>&1")  -- UTF-8 code page (fixes Unicode on Windows)
os.execute("clear 2>/dev/null || cls 2>NUL")
showBanner()

-- Debug mode
if opts.debug then
	Logger.logLevel = Logger.LogLevel.Debug
	Logger:debug("Debug logging enabled")
end

-- Validate: Lua version
if not opts.luaVersion then
	fail("No Lua version specified. Run with --help for usage.")
end

local versionKey = VERSION_ALIASES[opts.luaVersion]
if not versionKey then
	fail(string.format(
		"Unknown Lua version: '%s'\n  Valid values: 54, 5.4, 53, 5.3, 52, 5.2, 51, 5.1",
		opts.luaVersion
	))
end

-- Validate: input file
if not opts.input then
	fail("No input file specified. Run with --help for usage.")
end

-- Resolve input path: bare filenames default to Inputs/
local inputPath = opts.input
if not inputPath:match("[/\\]") then
	inputPath = "Inputs/" .. inputPath
end

if not fileExists(inputPath) then
	fail(string.format("Input file not found: '%s'", inputPath))
end

-- Seed RNG from /dev/urandom (strong entropy); fallback to time+clock
local function seedRNG()
	local f = io.open("/dev/urandom", "rb")
	if f then
		local bytes = f:read(16)
		f:close()
		if bytes and #bytes == 16 then
			local a = string.unpack("<I8", bytes, 1)
			local b = string.unpack("<I8", bytes, 9)
			math.randomseed(a, b)
			return
		end
	end
	math.randomseed(os.time(), math.floor(os.clock() * 1e9))
end
seedRNG()

-- Load pipeline modules
local Deserializer = require(versionKey .. ".BYTECODE.TOOLS.Deserializer")
local Obfuscator   = require(versionKey .. ".OBFUSCATOR.Obfuscator")
local Generator    = require(versionKey .. ".VM.Generator")

local luacBin = LUAC_BINARIES[versionKey]

-- Step 1: Compile with luac
Logger:log(string.format("Compiling '%s' with %s ...", inputPath, luacBin))

local compileCmd = string.format(
	'%s -l -l -s -o Temp/luac.out "%s" > Temp/listing.txt 2>&1',
	luacBin, inputPath
)
if not os.execute(compileCmd) then
	fail(string.format(
		"Compilation failed.\n  Command: %s\n  Is '%s' installed and in PATH?",
		compileCmd, luacBin
	))
end

-- Step 2: Read bytecode
local bcFile = io.open("Temp/luac.out", "rb")
if not bcFile then
	fail("Could not open Temp/luac.out after compilation.")
end
local contents = bcFile:read("all")
bcFile:close()

-- Step 3: Deserialize
Logger:log("Parsing bytecode ...")
local chunk = Deserializer:deserialize(contents)

-- Step 4: Obfuscate
Logger:log("Obfuscating ...")
Obfuscator(chunk)

-- Step 5: Generate VM
Logger:log("Generating VM ...")
local _, VM = Generator(chunk)

-- Step 6: Write output
local outFile = io.open(opts.output, "wb")
if not outFile then
	fail(string.format("Cannot write output file: '%s'", opts.output))
end
outFile:write(VM)
outFile:close()

Logger:log(string.format("Done. Output: %s", opts.output))
