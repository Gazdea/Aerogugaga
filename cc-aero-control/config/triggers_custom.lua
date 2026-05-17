-- config/triggers_custom.lua
-- Optional user-defined Lua triggers (complements triggers.json).
-- Return a table of trigger objects.
--
-- Each trigger:
--   id       — string, unique
--   enabled  — boolean (default true)
--   check(data) — return true to fire
--     data = { readings, controls, triggers, remote, network }
--   fire(api) — called when trigger activates
--   clear(api) — called when trigger deactivates (optional)
--
-- api helpers:
--   api.redstone(side, value)    — set redstone output
--   api.peripheral(side, method, ...) — call peripheral method
--   api.exec(target, action)     — send exec request to remote node
--   api.log(msg)                 — debug print

return {
  {
    id = "low_altitude_warning",
    enabled = true,
    check = function(data)
      return data.readings.altitude.height < 25
    end,
    fire = function(api)
      api.redstone("back", true)
      api.log("Low altitude! Firing redstone.")
    end,
    clear = function(api)
      api.redstone("back", false)
    end,
  },

  {
    id = "speed_safe_landing",
    enabled = true,
    check = function(data)
      return data.readings.altitude.height < 10
          and data.readings.velocity_magnitude < 2
    end,
    fire = function(api)
      api.exec("ground-station", {
        type = "redstone", side = "front", value = true
      })
      api.log("Safe landing altitude, notifying ground station.")
    end,
    clear = function(api)
      api.exec("ground-station", {
        type = "redstone", side = "front", value = false
      })
    end,
  },
}
