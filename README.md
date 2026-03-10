# Zenfus
```ascii
                        ███████╗███████╗███╗░░██╗███████╗██╗░░░██╗░██████╗
                        ╚════██║██╔════╝████╗░██║██╔════╝██║░░░██║██╔════╝
                        ░░███╔═╝█████╗░░██╔██╗██║█████╗░░██║░░░██║╚█████╗░
                        ██╔══╝░░██╔══╝░░██║╚████║██╔══╝░░██║░░░██║░╚═══██╗
                        ███████╗███████╗██║░╚███║██║░░░░░╚██████╔╝██████╔╝
                        ╚══════╝╚══════╝╚═╝░░╚══╝╚═╝░░░░░░╚═════╝░╚═════╝░
```

**Zenfus** is just a Lua obfuscator I made 3 years ago which is based on IB2.

Support for Lua 5.1, 5.2, and 5.3 is planned.

---

## How it works

```
Lua source  →  luac5.4  →  Deserializer  →  Obfuscator  →  Generator  →  Obfuscated script
```

1. **Compile** — the input script is compiled to standard Lua 5.4 bytecode using `luac5.4`
2. **Deserialize** — bytecode is parsed into an instruction tree
3. **Obfuscate** — multiple passes run over the tree (constant encryption, dead instruction injection, super-operator fusion, etc.)
4. **Generate** — a custom VM and randomised dispatch loop are constructed around the obfuscated bytecode, then written to the output file

---

## Requirements

| Requirement | Notes |
|---|---|
| **Lua 5.4** | Used to run Zenfus itself |
| **`luac5.4`** | Must be in `PATH`; used to compile input scripts |

> If your `luac` binary has a different name, edit the `LUAC_BINARIES` table at the top of `cli.lua`.

---

## Installation

```bash
git clone https://github.com/Zaenalos/Zenfus.git
cd Zenfus
```

No build step or package manager needed. Zenfus is a pure Lua project with no external dependencies.

Make sure the required directories exist (they are included in the repo):

```
Inputs/    ← put your source files here
Output/    ← obfuscated output is written here
Temp/      ← intermediate build artifacts
```

---

## Usage

```
lua cli.lua [OPTIONS] <lua-version> <input-file>
lua cli.lua [OPTIONS] -V <lua-version> -i <input-file>
```

### Arguments

| Argument | Description |
|---|---|
| `<lua-version>` | Lua version to target: `54`, `5.4`, `Lua54` (and equivalents) |
| `<input-file>` | Lua source file to obfuscate. Bare filenames are resolved from `Inputs/` |

### Options

| Flag | Description |
|---|---|
| `-h`, `--help` | Show help and exit |
| `--version` | Print Zenfus version and exit |
| `-V`, `--lua-version <v>` | Lua version to target |
| `-i`, `--input <file>` | Input Lua source file |
| `-o`, `--output <file>` | Output file path &nbsp;*(default: `Output/finalRes.lua`)* |
| `--debug` | Enable verbose logging |
| `--no-color` | Disable coloured output |

---

## Examples

```bash
# Quickest form — positional arguments
lua cli.lua 54 BasicTest.lua

# Named flags
lua cli.lua -V 5.4 -i BasicTest.lua

# Custom output path
lua cli.lua 54 BasicTest.lua -o Output/obfuscated.lua

# Full path input (skip Inputs/ resolution)
lua cli.lua 54 /path/to/myscript.lua -o /path/to/out.lua

# Debug mode
lua cli.lua 54 BasicTest.lua --debug

# No colour (useful for piping output)
lua cli.lua 54 BasicTest.lua --no-color
```

---

## Configuration

Open `settings.lua` to toggle obfuscation passes:

```lua
local Settings = {
    ControlFlow      = true,   -- Control flow obfuscation
    DeadInstructions = true,   -- Inject dead/junk instructions
    ByteCompress     = true,   -- Compress bytecode
    EncryptConstants = true,   -- XOR-encrypt string constants
    SuperOP          = true,   -- Fuse instruction sequences into super-operators
}
```

To control the indentation style of the generated VM dispatch loop, edit the `INDENT` constant at the top of `Lua54/VM/Generator.lua`:

```lua
local INDENT = "\t"    -- tab (default)
-- local INDENT = "  "  -- 2 spaces
-- local INDENT = ""    -- no indent (compact output)
```

---

## Supported Lua versions

| Version | Status |
|---|---|
| Lua 5.4 | Fully supported |
| Lua 5.3 | Planned |
| Lua 5.2 | Planned |
| Lua 5.1 | Planned |

---

## Reminders

- You must run this program with **Lua 5.3** or **above**.
- The input file must be **valid Lua 5.4** source. Syntax errors will be caught by `luac5.4` and reported before obfuscation begins.
- The `Temp/` directory is used for intermediate files (`luac.out`, `listing.txt`). Do not delete it while the tool is running.
- Obfuscated output is non-deterministic — running the tool twice on the same input produces different output each time due to random ID assignment and instruction shuffling.
- The obfuscated script embeds a full custom VM. It will be significantly larger than the original.
- `luac5.4` must match the Lua **version used to run the script** — the deserializer targets the exact Lua 5.4 bytecode format.

---

## Project structure

```
Zenfus/
├── cli.lua                         Entry point / CLI
├── config.lua                      Project metadata (name, version, author)
├── settings.lua                    Obfuscation feature toggles
├── colors.lua                      ANSI colour utility
├── logger.lua                      Structured logger
├── util.lua                        Bit-packing and shuffle utilities
│
├── Inputs/                         Place input .lua files here
├── Output/                         Obfuscated output is written here
├── Temp/                           Intermediate build artifacts
│
└── Lua54/
    ├── BYTECODE/TOOLS/
    │   ├── Deserializer.lua        Parses Lua 5.4 .luac bytecode
    │   └── Serializer.lua          Serializes to custom binary format
    ├── OBFUSCATOR/
    │   ├── Obfuscator.lua          Orchestrates obfuscation passes
    │   └── Optimizer.lua           Per-opcode optimization dispatch
    └── VM/
        ├── Generator.lua           Generates the final obfuscated output
        ├── MAINVM.lua              Embedded custom VM template
        └── OPCODES/                Per-opcode code generation (85+ files)
```

---

## Contributing

Pull requests and issues are welcome.

- **Bug reports / feature requests** — open an issue at [github.com/Zaenalos/Zenfus/issues](https://github.com/Zaenalos/Zenfus/issues)
- **Pull requests** — fork the repo, make your changes on a new branch, and open a PR against `main`

Please keep pull requests focused — one fix or feature per PR makes review faster.

---

> **PS —** I wrote this project about 3 years ago and it is not a reference for how you should actually build a Lua obfuscator. The architecture has a number of rough edges and design decisions I would not make today. That said, if you are trying to understand how Lua 5.4 bytecode deserialization works, how a custom serialization format can be built on top of it, or how a register-based VM dispatch loop is structured, this codebase should give you a solid starting point for that kind of exploration.
