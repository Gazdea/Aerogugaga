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

### config.setNodeId(id)

Load a per-node config from `config/nodes/<id>.json`. Enables P2P mode.

- **id**: string — node identifier (e.g. `"airship-1"`)
- All values in the node config are available via `config.node()`

```lua
config.setNodeId("airship-1")
```

### config.node(key?)

Access currently loaded node config.

- **key**: string? — specific key within node config
- **returns**: any — the node config table, or a specific value

```lua
config.node()               -- full node config
config.node("network")      -- { modem_side="back", channel=42 }
config.node("triggers")     -- array of trigger rules
```

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

### state.mergeRemote(node_id, data)

Store readings/controls received from a remote P2P node.

- **node_id**: string — sender node identifier
- **data**: table — contains `readings` and/or `controls` fields

```lua
state.mergeRemote("airship-1", { readings = { altitude = { height = 50 } } })
```

### state.clearRemote()

Clear all stored remote data. Called on mode switch or re-init.

### state.updateNetwork(node_id, peripherals)

Store peripheral info received from a remote node.

- **node_id**: string — sender node identifier
- **peripherals**: table[] — array of `{ name, type, methods? }`

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
  remote = {
    ["airship-1"] = { readings = {...}, controls = {...} },
  },
  network = {
    ["airship-1"] = {
      peripherals = { { name = "top", type = "gyroscope", methods = {...} } },
      last_seen = os.clock(),
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

### trigger.tick(readings, state, rules_override?, api_helpers?)

Evaluates rules and updates `state.triggers`. In P2P mode, pass `rules_override`
from the node config instead of reading `config/triggers.json`.

- **rules_override**: table? — optional rules array (uses `config/triggers.json` if nil)
- **api_helpers**: table? — `{ network?, debug? }` for code trigger support (`config/triggers_custom.lua`)

```lua
-- Legacy mode (uses config/triggers.json)
trigger.tick(readings, state)

-- P2P mode (node-specific rules + code triggers)
trigger.tick(readings, state, nodeConfig.triggers, { network = net, debug = true })
```

### resolveSource(readings, source)

Resolves a dot-separated source path from readings table.

- `"angles.pitch"` → `readings.angles.pitch`
- `"altitude.height"` → `readings.altitude.height`

### evalCondition(value, condition)

Compares `value` against `condition.threshold` using `condition.operator`.

Operators: `>`, `<`, `>=`, `<=`, `==`

---

## src/discovery.lua

Scans all connected CC:T peripherals and returns structured information.

```lua
local discovery = require("src.discovery")
```

### discovery.scan()

Returns a sorted array of all connected peripherals with name, type, and methods.

```lua
local list = discovery.scan()
-- → { { name = "top", type = "gyroscope", methods = { "getAngles", ... } }, ... }
```

Broadcast periodically by P2P nodes via `network.broadcastPeripherals()`.
Incoming data is stored in `state.network[node_id].peripherals`.

---

## src/network.lua

P2P modem communication module. Uses raw modem API (`modem.transmit`,
`modem_message` events) for channel-based broadcasting.

```lua
local network = require("src.network")
```

### network.init(side, channel)

Open a modem and register the listening channel.

- **side**: string — peripheral side (e.g. `"back"`)
- **channel**: number — network channel (default 42)
- **returns**: boolean — whether the modem was opened successfully

Also opens `channel + 1` as a secondary channel for reply messages.

```lua
network.init("back", 42)
```

### network.announce(node_id, caps)

Broadcast node capabilities to the network.

- **node_id**: string — unique node identifier
- **caps**: table — `{ sensors?: bool, outputs?: bool, display?: bool }`

```lua
network.announce("airship-1", { sensors = true, outputs = true })
```

### network.broadcastState(data)

Broadcast sensor readings and/or control state.

- **data**: table — `{ readings?: table, controls?: table }`

```lua
network.broadcastState({ readings = local_readings, controls = state.controls })
```

### network.sendExec(target, action)

Request a remote node to execute an action.

- **target**: string — target `node_id`
- **action**: table — `{ type, side, method?, value? }`

```lua
network.sendExec("ground-station", { type = "redstone", side = "back", value = true })
```

### network.pollAll()

Non-blocking drain of all pending modem messages. Uses `os.pullEvent`
with 0 timeout so it returns immediately if the queue is empty.

- **returns**: table[] — array of decoded message tables (empty if none)

Only returns messages from the configured channel(s).

```lua
local msgs = network.pollAll()
for _, msg in ipairs(msgs) do
  if msg.type == "state" then
    print("Received from", msg.node_id)
  end
end
```

**Message types**:

| type | direction | fields |
|---|---|---|
| `state` | broadcast | `node_id`, `readings?`, `controls?` |
| `announce` | broadcast | `node_id`, `caps` |
| `exec` | targeted | `target`, `source`, `action` |
| `peripherals` | broadcast | `node_id`, `list` |

### network.broadcastPeripherals(peripherals)

Advertise local peripherals to the network.

- **peripherals**: table[] — output of `discovery.scan()`

```lua
local list = discovery.scan()
network.broadcastPeripherals(list)
```

Sent every 20 ticks automatically when `discovery` is loaded.

---

## src/output.lua

Applies trigger results to redstone outputs or peripherals.

```lua
local output = require("src.output")
```

### output.tick(state, node_id?)

For each active trigger in `state.triggers`, executes the corresponding action.
Skips actions whose `target_node` differs from `node_id` (they are routed
externally by `dashboard.lua`).

- **node_id**: string? — current node id for target_node matching

**Action types**:

| type | effect |
|---|---|
| `redstone` | `redstone.setOutput(side, active)` |
| `peripheral` | `peripheral.call(side, method, active)` |

### output.applyAction(action, active)

Execute a single action immediately. Public helper for P2P remote exec handling.

- **action**: table — `{ type, side, method?, value? }`
- **active**: boolean — whether the action should fire

```lua
-- Execute a redstone action directly
output.applyAction({ type = "redstone", side = "back", value = true }, true)
```

### output.shouldRoute(rule, node_id)

Check if a trigger rule's `target_node` is set and differs from current node.

- **rule**: table — trigger rule with optional `target_node`
- **node_id**: string? — current node id
- **returns**: boolean

```lua
-- When target_node == "ground-station" but node_id == "airship-1"
output.shouldRoute(rule, "airship-1")  -- true → route to ground-station
```

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

### display.getOutput()

Return current output target (term or monitor). Used by custom display functions.

### display.getEncode()

Return current font encoder function. Passes through by default, encodes
Cyrillic when locale is `"ru"`. Used by custom display functions.
