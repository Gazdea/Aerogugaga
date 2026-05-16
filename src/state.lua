---@class Readings
---@field angles table Pitch, yaw, roll angles
---@field altitude table Height and air pressure
---@field velocity table Velocity components X, Y, Z
---@field velocity_magnitude number Scalar speed
---@field rel_angle number Relative navigation angle
---@field raw table Raw sensor data

---@class Controls
---@field throttle table Throttle per axis {x, y, z}
---@field altitude_hold boolean Altitude hold toggle
---@field yaw_target number|nil Target yaw rate

---@class TriggerState
---@field active boolean Whether trigger is firing
---@field value number Current sensor value
---@field threshold number Trigger threshold
---@field operator string Comparison operator
---@field source string Data source path

---@class State
---@field readings Readings
---@field controls Controls
---@field triggers table<string, TriggerState>

---@type State
local state = {
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
  triggers = {},
}

--- Replace current sensor readings
---@param readings Readings
function state.updateReadings(readings)
  state.readings = readings
end

---@return Readings
function state.getReadings()
  return state.readings
end

---@return Controls
function state.getControls()
  return state.controls
end

return state
