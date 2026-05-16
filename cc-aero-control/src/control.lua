---@class ControlModule
local control = {}
local config = require("cc-aero-control.src.config")

control._prev = {}

--- Process redstone inputs and update state.controls
--- Uses config/bindings.json to map sides to actions
--- Supported actions: throttle, yaw, altitude_hold, stop
---@param state State Central state (modified in-place)
function control.tick(state)
  local bindings = config.get("bindings") or {}
  for side, binding in pairs(bindings) do
    local on = redstone.getInput(side)
    if binding.invert then
      on = not on
    end

    if binding.action == "throttle" and binding.axis then
      state.controls.throttle[binding.axis] = on and 1 or 0

    elseif binding.action == "yaw" then
      state.controls.yaw_target = on and (binding.speed or 1) or nil

    elseif binding.action == "altitude_hold" then
      if binding.edge == "rising" then
        if on and not control._prev[side] then
          state.controls.altitude_hold = not state.controls.altitude_hold
        end
      else
        state.controls.altitude_hold = on
      end

    elseif binding.action == "stop" then
      if on then
        state.controls.throttle.x = 0
        state.controls.throttle.y = 0
        state.controls.throttle.z = 0
        state.controls.yaw_target = nil
      end
    end
    control._prev[side] = on
  end
end

return control
