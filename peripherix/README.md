# peripherix — CC:T Peripheral Interface Generator

Scans connected CC:T peripherals and generates a typed wrapper module.

## Usage

1. Copy `peripherix.lua` to a CC:T computer
2. Run it (optionally with an alias file path):
   ```
   perepherials.lua               # basic mode
   perepherials.lua /path/to/aliases.json  # with aliases
   ```
3. Generated file `peripheral_interfaces.lua` is placed in the current directory
   - If an alias file is provided, `p.<alias> = p.<side>` entries are added
4. Move it to your project (e.g. `cc-aero-control/`)

## Output

Generates a Lua module with:
- A class per peripheral type with all methods typed via LuaDoc
- Instances for every connected peripheral
- Uses `cc-stdlib.proxy` for safe `pcall` wrapping
