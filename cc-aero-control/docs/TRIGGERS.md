# Code Triggers API

In addition to JSON triggers from `triggers.json` (or the node config), you
can define triggers as Lua functions in `config/triggers_custom.lua`. Both
systems run together on every tick.

## Structure

```lua
-- config/triggers_custom.lua
return {
  {
    id = "my_trigger",         -- unique string id
    enabled = true,            -- optional, default true
    check = function(data)     -- called every tick
      -- Return true to fire, false to clear
      return data.readings.altitude.height < 20
    end,
    fire = function(api)       -- called when trigger activates
      api.redstone("back", true)
      api.log("Trigger fired!")
    end,
    clear = function(api)      -- called when trigger deactivates
      api.redstone("back", false)
    end,
  },
}
```

## data object (passed to `check`)

```lua
data = {
  readings  — combined sensor readings (local + remote)
  controls  — { throttle = {x,y,z}, altitude_hold, yaw_target }
  triggers  — all evaluated trigger states (including JSON triggers)
  remote    — { [node_id] = { readings?, controls? } }
  network   — { [node_id] = { peripherals, last_seen } }
}
```

Access readings by dot-path:
```lua
data.readings.altitude.height      -- number
data.readings.velocity_magnitude   -- number
data.readings.angles.pitch         -- number
```

## api object (passed to `fire` / `clear`)

| Method | Description |
|---|---|
| `api:redstone(side, value)` | Set redstone output on side |
| `api:peripheral(side, method, ...)` | Call a peripheral method |
| `api:exec(target, action)` | Send exec request to remote node |
| `api:log(message)` | Debug print (only if `debug: true`) |

### api:redstone

```lua
api:redstone("back", true)     -- set output ON
api:redstone("back", false)    -- set output OFF
```

### api:peripheral

```lua
api:peripheral("top", "setSpeed", 50)
```

### api:exec

Sends an action to be executed on a remote node. The target node must be
connected on the same network channel.

```lua
api:exec("ground-station", {
  type = "redstone",
  side = "front",
  value = true,
})
```

### api:log

```lua
api:log("Altitude alert triggered")
-- prints: [trigger] Altitude alert triggered
```

## Multiple triggers

Return a table of trigger objects. All are evaluated every tick in order.

```lua
return {
  { id = "trigger_a", ... },
  { id = "trigger_b", ... },
}
```

## Edge detection

The trigger system handles edge detection automatically:
- `fire` is called only on the tick the trigger **becomes** active
- `clear` is called only on the tick the trigger **ceases** to be active

## Combining with JSON triggers

JSON triggers from `config/triggers.json` (or node config `triggers` field)
are evaluated first. Code triggers from `config/triggers_custom.lua` are
evaluated second. Both write to `state.triggers[id]`.

You can mix both approaches:
- Use JSON for simple threshold conditions
- Use Lua for complex logic (multi-variable, stateful, network-aware)

## Example: multi-condition

```lua
{
  id = "complex_warning",
  check = function(data)
    local h = data.readings.altitude.height
    local v = data.readings.velocity_magnitude
    local hold = data.controls.altitude_hold
    return h < 30 and v > 5 and not hold
  end,
  fire = function(api)
    api:redstone("back", true)
    api:exec("ground-station", {
      type = "redstone", side = "front", value = true
    })
  end,
  clear = function(api)
    api:redstone("back", false)
    api:exec("ground-station", {
      type = "redstone", side = "front", value = false
    })
  end,
}
```

## Notes

- `config/triggers_custom.lua` is loaded every tick via `require` (cached)
- If the file doesn't exist or doesn't return a table, no code triggers run
- Changes require a restart (require caches the module)
