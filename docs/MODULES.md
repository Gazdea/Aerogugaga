# Modules API

## lib/proxy.lua (standalone)

Safe `pcall`-wrapped wrappers for CC:T peripheral API.

```lua
local proxy = require("lib.proxy")
```

### proxy.call(side, method, ...)

Calls `peripheral.call` with `pcall` protection.

- **side**: string — peripheral side name
- **method**: string — method name
- **...**: any — arguments passed to the method
- **returns**: up to 8 values on success, nil on failure

```lua
local ok = proxy.call("top", "getAngles")
```

### proxy.wrap(side)

Safe `peripheral.wrap` with `pcall`.

- **side**: string — peripheral side name
- **returns**: table|nil — wrapped peripheral or nil

```lua
local mon = proxy.wrap("left")
if mon then mon.write("Hello") end
```

---

## lib/i18n.lua (standalone)

Dot-path translation engine. Reads Lua table files from a base directory.

```lua
local lang = require("lib.i18n")
```

### lang.init(locale, basePath?)

Load translations for the given locale.

- **locale**: string — locale name (default `"en"`)
- **basePath**: string? — directory containing `<locale>.lua` files (default `"i18n"`)
- Falls back to `<basePath>/en.lua` if requested locale not found.

```lua
lang.init("ru")          -- load i18n/ru.lua
lang.init("de", "loc")   -- load loc/de.lua, fallback loc/en.lua
```

### lang.t(key, ...)

Look up a dot-separated translation key with optional format args.

- **key**: string — dot-separated path (e.g. `"dashboard.title"`)
- **...**: any — `string.format` arguments
- **returns**: string — translated text, or `key` if not found

```lua
lang.t("dashboard.title")          -- "=== DASHBOARD ==="
lang.t("dashboard.units.meters")   -- "m"
```

---

## lib/font.lua (standalone)

Encodes Cyrillic UTF-8 strings to CC:T texture pack codepoints.

```lua
local font = require("lib.font")
```

### font.encode(text)

- **text**: string — UTF-8 input with Cyrillic characters
- **returns**: string — encoded bytes for CC:T display

```lua
font.encode("Привет")  -- encoded for textpack
```

---

## src/config.lua

JSON config loader with built-in defaults. Reads `config/<section>.json`.

```lua
local config = require("src.config")
```

### config.get(section, key?)

- **section**: string — config name (maps to `config/<section>.json`)
- **key**: string? — specific key within section
- **returns**: any — full section table or specific value

```lua
config.get("settings")                    -- { update_interval=0.05, ... }
config.get("settings", "update_interval") -- 0.05
config.get("bindings")                    -- { front={...}, ... }
```

### config.reload()

Clear cache so next `get()` re-reads from disk.

---

## src/state.lua

Central mutable state shared across all modules.

```lua
local state = require("src.state")
```

### state.updateReadings(readings)

Replace current sensor readings.

### state.getReadings()

Returns current readings table.

### state.getControls()

Returns current controls table.

### State shape

```lua
state = {
  readings = {
    angles = { pitch = 0, yaw = 0, roll = 0 },
    altitude = { height = 0, pressure = 0 },
    velocity = { x = 0, y = 0, z = 0 },
    velocity_magnitude = 0,
    rel_angle = 0,
    raw = {},
  },
  controls = {
    throttle = { x = 0, y = 0, z = 0 },
    altitude_hold = false,
    yaw_target = nil,
  },
  triggers = {
    ["trigger_id"] = {
      active = false,
      value = 0,
      threshold = 10,
      operator = ">",
      source = "angles.pitch",
    },
  },
}
```

---

## src/scanner.lua

Reads all connected peripherals and returns structured data.

```lua
local scanner = require("src.scanner")
```

### scanner.scan()

- **returns**: table — readings with `angles`, `altitude`, `velocity`, `velocity_magnitude`, `rel_angle`, `raw`

Uses `config/sensors.json` to map velocity sensors to axes.

---

## src/control.lua

Reads redstone inputs and updates `state.controls`.

```lua
local control = require("src.control")
```

### control.tick(state)

Reads `redstone.getInput()` for each side in `config/bindings.json`.

**Action types**:

| action | effect |
|---|---|
| `throttle` | Sets `state.controls.throttle[axis]` to 0 or 1 |
| `yaw` | Sets `state.controls.yaw_target` to `speed` or nil |
| `altitude_hold` | Toggles or sets `state.controls.altitude_hold` |
| `stop` | Zeroes all throttle axes and clears yaw_target |

**Binding fields**:

| field | type | description |
|---|---|---|
| `action` | string | Action type |
| `axis` | string | `"x"`, `"y"`, `"z"` (for throttle) |
| `invert` | boolean | Invert redstone signal |
| `speed` | number | Yaw rate (for yaw action) |
| `edge` | string | `"rising"` for edge-triggered toggle |

---

## src/trigger.lua

Evaluates condition rules with hysteresis support.

```lua
local trigger = require("src.trigger")
```

### trigger.tick(readings, state)

Evaluates all rules from `config/triggers.json`. Updates `state.triggers`.

### resolveSource(readings, source)

Resolves a dot-separated source path from readings table.

- `"angles.pitch"` → `readings.angles.pitch`
- `"altitude.height"` → `readings.altitude.height`

### evalCondition(value, condition)

Compares `value` against `condition.threshold` using `condition.operator`.

Operators: `>`, `<`, `>=`, `<=`, `==`

---

## src/output.lua

Applies trigger results to redstone outputs or peripherals.

```lua
local output = require("src.output")
```

### output.tick(state)

For each active trigger in `state.triggers`, executes the corresponding action.

**Action types**:

| type | effect |
|---|---|
| `redstone` | `redstone.setOutput(side, active)` |
| `peripheral` | `peripheral.call(side, method, active)` |

---

## src/display.lua

Renders dashboard to terminal or monitor with i18n and font encoding.

```lua
local display = require("src.display")
```

### display.init(monitor_side, locale?)

- **monitor_side**: string|nil — side name or nil for term
- **locale**: string? — `"ru"` loads font encoding, others pass through

### display.render(readings, state)

Clears output and draws formatted dashboard with sensor data, controls, and trigger states.
