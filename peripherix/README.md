# peripherix — CC:T Peripheral Interface Generator

Scans connected CC:T peripherals and generates a typed wrapper module.

## Usage

1. Copy `peripherix.lua` to a CC:T computer
2. Run it:
   ```
   perepherials.lua
   ```
3. Generated file `peripheral_interfaces.lua` is placed in the current directory
4. Move it to your project (e.g. `cc-aero-control/`)

## Output

Generates a Lua module with:
- A class per peripheral type with all methods typed via LuaDoc
- Instances for every connected peripheral
- Uses `cc-stdlib.proxy` for safe `pcall` wrapping
