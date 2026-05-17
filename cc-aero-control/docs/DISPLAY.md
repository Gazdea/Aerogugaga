# Custom Display API

If `config/display_custom.lua` exists and returns a function, it **replaces**
the built-in `display.render()`. The function receives a single context table
with everything needed to build your own dashboard layout.

## Context table

```lua
ctx = {
  output    — term or monitor (write, setCursorPos, clear, getSize)
  translate — i18n translation function: t("key") → string
  encode    — Cyrillic font encoder: encode("text") → encoded string
  data      — full state snapshot (see below)
  state     — raw state module reference (for advanced access)
}
```

## data table

```lua
data = {
  readings  — combined sensor readings (local + remote merged)
  controls  — current control state { throttle, altitude_hold, yaw_target }
  triggers  — evaluated trigger states { ["id"] = { active, value, ... } }
  remote    — data from other nodes { [node_id] = { readings?, controls? } }
  network   — peripheral lists from all nodes { [node_id] = { peripherals, last_seen } }
}
```

## readings sub-fields

| Path | Type | Description |
|---|---|---|
| `readings.angles.pitch` | number | Pitch angle (degrees) |
| `readings.angles.yaw` | number | Yaw angle (degrees) |
| `readings.angles.roll` | number | Roll angle (degrees) |
| `readings.altitude.height` | number | Altitude (meters) |
| `readings.altitude.pressure` | number | Air pressure (kPa) |
| `readings.velocity.x` | number | Velocity X (m/s) |
| `readings.velocity.y` | number | Velocity Y (m/s) |
| `readings.velocity.z` | number | Velocity Z (m/s) |
| `readings.velocity_magnitude` | number | Speed (m/s) |
| `readings.rel_angle` | number | Navigation relative angle (degrees) |

## Example

```lua
-- config/display_custom.lua
return function(ctx)
  local out = ctx.output
  local d = ctx.data
  local t = ctx.translate
  local enc = ctx.encode

  out.clear()
  local y = 1
  out.setCursorPos(1, y)
  out.write(enc(t("dashboard.title")))

  y = 3
  out.setCursorPos(1, y)
  out.write(string.format("Height: %.1f m", d.readings.altitude.height))

  y = y + 1
  out.setCursorPos(1, y)
  out.write(string.format("Speed: %.1f m/s", d.readings.velocity_magnitude))

  for id, info in pairs(d.network) do
    y = y + 2
    out.setCursorPos(1, y)
    out.write("Node " .. id .. " peripherals:")
    for _, p in ipairs(info.peripherals or {}) do
      y = y + 1
      out.setCursorPos(1, y)
      out.write("  " .. p.name .. " (" .. tostring(p.type) .. ")")
    end
  end
end
```

## Notes

- `config/display_custom.lua` is loaded once at startup via `require`
- Changes to the file require a restart to take effect
- If the file doesn't exist or doesn't return a function, the built-in
  `display.render()` is used
- Use `pcall(peripheral.wrap, side)` if you need a monitor not configured
  in the node config
