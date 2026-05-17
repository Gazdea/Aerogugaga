# Configuration

Configuration comes in two layers:

1. **Global config** — JSON files in `config/` (`settings.json`, `bindings.json`, ...)
2. **Node config** — JSON files in `config/nodes/<id>.json` (for P2P mode)
3. **Lua scripts** — `config/display_custom.lua`, `config/triggers_custom.lua` (optional, code-based)

Missing files fall back to sensible defaults — no config is required to start.

---

## `settings.json` — Global settings

```json
{
  "update_interval": 0.05,
  "monitor_side": null,
  "locale": "en",
  "debug": false,
  "node_id": null,
  "network": {
    "default_modem_side": null,
    "default_channel": 42
  }
}
```

### Core

| Field | Type | Default | Description |
|---|---|---|---|
| `update_interval` | number | 0.05 | Seconds between main loop ticks |
| `monitor_side` | string\|null | null | Monitor peripheral side (`"left"`, `"right"`, `"top"`) or null for terminal |
| `locale` | string | "en" | Language code (`"en"`, `"ru"`) |
| `debug` | boolean | false | Print startup diagnostics to terminal |

### Network (legacy mode only; P2P uses node config)

| Field | Type | Default | Description |
|---|---|---|---|
| `node_id` | string\|null | null | Node identifier (used when running `dashboard` without CLI arg) |
| `network.default_modem_side` | string\|null | null | Default modem side for P2P networking |
| `network.default_channel` | number | 42 | Default network channel |

---

## `bindings.json` — Control bindings

Maps CC:T redstone input sides to control actions.

```json
{
  "front": { "action": "throttle", "axis": "z" },
  "left":  { "action": "throttle", "axis": "x" },
  "top":   { "action": "altitude_hold" },
  "back":  { "action": "yaw", "speed": 5 },
  "bottom": { "action": "stop" }
}
```

### Action types

| Action | Effect | Extra fields |
|---|---|---|
| `throttle` | Set thrust along axis | `axis`: `"x"`\|`"y"`\|`"z"` |
| `yaw` | Set yaw rotation | `speed`: number |
| `altitude_hold` | Toggle/hold altitude lock | `edge`: `"rising"` for toggle mode |
| `stop` | Emergency stop (zeros all) | none |

### Common fields

| Field | Type | Description |
|---|---|---|
| `invert` | boolean | Invert redstone signal (ON→OFF, OFF→ON) |
| `edge` | string | `"rising"` for edge-triggered toggle |

---

## `aliases.json` — Peripheral aliases

Maps custom names to actual CC:T peripheral side names. Lets you refer to devices
by role instead of physical side.

```json
{
  "aliases": {
    "gyro": "top",
    "baro": "altitude_sensor_0",
    "nav": "navigation_table_1",
    "vel_x": "velocity_sensor_1",
    "vel_y": "velocity_sensor_2",
    "vel_z": "velocity_sensor_3"
  }
}
```

### How it works

- **`proxy.call()` / `proxy.wrap()`** — alias is resolved automatically (set up in `dashboard.lua`)
- **`sensors.json`** — sensor names are resolved through the alias table
- **`triggers.json`** — `action.side` in peripheral-type actions is resolved
- **`triggers_custom.lua`** — `api:peripheral(side, ...)` resolves the side
- **`peripheral_interfaces.lua`** — the generator (`perepherials.lua`) creates `p.<alias> = p.<side>` entries when an alias file is passed as an argument

If a name has no matching alias, it passes through unchanged (backwards compatible).

---

## `sensors.json` — Velocity sensor mapping

Maps velocity sensor peripheral names to axes.

```json
{
  "velocity": {
    "velocity_sensor_1": "x",
    "velocity_sensor_2": "y",
    "velocity_sensor_3": "z"
  }
}
```

If a sensor is misconfigured or disconnected, that axis reads 0.

---

## `triggers.json` — JSON trigger rules

Rules that evaluate sensor readings and produce redstone/peripheral outputs.

```json
{
  "triggers": [
    {
      "id": "pitch_warning",
      "enabled": true,
      "condition": {
        "source": "angles.pitch",
        "operator": ">",
        "threshold": 10
      },
      "hysteresis": 2.0,
      "action": {
        "type": "redstone",
        "side": "bottom",
        "value": true
      }
    }
  ]
}
```

### Fields

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | string | yes | — | Unique identifier (shown in dashboard) |
| `enabled` | boolean | no | true | Set `false` to disable without deleting |
| `condition` | object | yes | — | `{ source, operator, threshold }` |
| `hysteresis` | number | no | 0 | Deadband to prevent rapid toggling |
| `debounce` | number | no | 1 | Consecutive ticks needed before firing |
| `action` | object | yes | — | `{ type, side, method?, value? }` |
| `target_node` | string | no | — | Route action to a different P2P node |

### condition.source

Dot-separated path into the readings table.

| Source | Description |
|---|---|
| `angles.pitch` | Pitch angle (degrees) |
| `angles.yaw` | Yaw angle (degrees) |
| `angles.roll` | Roll angle (degrees) |
| `altitude.height` | Altitude (meters) |
| `altitude.pressure` | Air pressure (kPa) |
| `velocity.x` | Velocity X (m/s) |
| `velocity.y` | Velocity Y (m/s) |
| `velocity.z` | Velocity Z (m/s) |
| `velocity_magnitude` | Speed (m/s) |
| `rel_angle` | Navigation angle (degrees) |

### condition.operator

| Operator | Fires when |
|---|---|
| `>` | value > threshold |
| `<` | value < threshold |
| `>=` | value >= threshold |
| `<=` | value <= threshold |
| `==` | abs(value - threshold) < 0.001 |

### Hysteresis

Prevents rapid on/off toggling:
- **Inactive → fires**: `value > threshold` (normal)
- **Active → clears**: `value <= (threshold - hysteresis)`

### Action types

| Type | Effect | Example |
|---|---|---|
| `redstone` | `redstone.setOutput(side, value)` | `{ "type": "redstone", "side": "bottom", "value": true }` |
| `peripheral` | `peripheral.call(side, method, active)` | `{ "type": "peripheral", "side": "top", "method": "setSpeed" }` |

---

## `config/nodes/<id>.json` — P2P node config

When launched as `dashboard airship-1`, loads `config/nodes/airship-1.json`.
This is the **primary config** in P2P mode — replaces global `settings.json`,
`bindings.json`, `sensors.json`, `triggers.json` for that node.

### Structure

```json
{
  "id": "airship-1",
  "network": {
    "modem_side": "back",
    "channel": 42
  },
  "display": {
    "monitor_side": "top",
    "locale": "en"
  },
  "sensors": {
    "velocity": {
      "top": "x"
    }
  },
  "bindings": {
    "front": { "action": "throttle", "axis": "x" }
  },
  "triggers": [
    {
      "id": "low_altitude",
      "condition": { "source": "altitude.height", "operator": "<", "threshold": 20 },
      "action": { "type": "redstone", "side": "back", "value": true },
      "target_node": "ground-station"
    }
  ]
}
```

### Fields

| Section | Field | Type | Description |
|---|---|---|---|
| `id` | | string | Unique node identifier |
| `network` | `.modem_side` | string | Modem side (`"back"`, `"left"`, `"right"`, `"top"`, `"bottom"`) |
| `network` | `.channel` | number | Network channel (default: 42) |
| `display` | `.monitor_side` | string\|null | Monitor side or null for terminal |
| `display` | `.locale` | string | Language code (`"en"`, `"ru"`) |
| `sensors` | | object\|null | Same format as `sensors.json` (omit if no local sensors) |
| `bindings` | | object\|null | Same format as `bindings.json` (omit if no local bindings) |
| `triggers` | | array | Array of trigger rules (omit if none) |

### Trigger routing via `target_node`

Each trigger rule can route its action to a different node:

```json
{
  "id": "low_alt",
  "condition": { "source": "altitude.height", "operator": "<", "threshold": 20 },
  "action": { "type": "redstone", "side": "front", "value": true },
  "target_node": "ground-station"
}
```

| target_node value | Behavior |
|---|---|
| omitted | Execute locally |
| matches current node id | Execute locally |
| different node id | Send `exec` request via network |

---

## Lua scripts (code-based configuration)

These complement the JSON config. They are loaded via `require` and provide
full Lua flexibility.

### `config/display_custom.lua` — Custom display renderer

Replaces the built-in `display.render()`. See [DISPLAY.md](DISPLAY.md) for
full API reference.

```lua
-- config/display_custom.lua
return function(ctx)
  local out = ctx.output    -- term or monitor
  local d = ctx.data        -- { readings, controls, triggers, remote, network }
  local t = ctx.translate   -- i18n translate
  local enc = ctx.encode    -- Cyrillic font

  out.clear()
  out.setCursorPos(1, 1)
  out.write(enc(t("dashboard.title")))

  local y = 3
  out.setCursorPos(1, y)
  out.write(string.format("Altitude: %.1f m", d.readings.altitude.height))

  for id, info in pairs(d.network) do
    y = y + 2
    out.setCursorPos(1, y)
    out.write("Peripherals on " .. id .. ":")
    for _, p in ipairs(info.peripherals or {}) do
      y = y + 1
      out.setCursorPos(1, y)
      out.write("  " .. p.name .. " (" .. tostring(p.type) .. ")")
    end
  end
end
```

If this file doesn't exist or doesn't return a function, the built-in
`display.render()` is used instead.

### `config/triggers_custom.lua` — Lua code triggers

Runs alongside JSON triggers. See [TRIGGERS.md](TRIGGERS.md) for full API.

```lua
-- config/triggers_custom.lua
return {
  {
    id = "smart_warning",
    check = function(data)
      return data.readings.altitude.height < 20
          and data.readings.velocity_magnitude > 3
    end,
    fire = function(api)
      api:redstone("back", true)
      api:exec("ground-station", { type = "redstone", side = "front", value = true })
    end,
    clear = function(api)
      api:redstone("back", false)
      api:exec("ground-station", { type = "redstone", side = "front", value = false })
    end,
  },
}
```

If this file doesn't exist or doesn't return a table, no code triggers run.

---

## Quick reference

| File | Purpose | Format |
|---|---|---|
| `config/settings.json` | Global settings | JSON |
| `config/bindings.json` | Redstone input → control action | JSON |
| `config/aliases.json` | Peripheral alias → side mapping | JSON |
| `config/sensors.json` | Velocity sensor axis mapping | JSON |
| `config/triggers.json` | Threshold-based trigger rules | JSON |
| `config/nodes/<id>.json` | P2P per-node config | JSON |
| `config/display_custom.lua` | Custom dashboard renderer | Lua function |
| `config/triggers_custom.lua` | Lua-code triggers | Lua table |
