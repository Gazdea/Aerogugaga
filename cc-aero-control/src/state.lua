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

---@class NetworkInfo
---@field peripherals table[] List of peripheral { name, type, methods? }
---@field last_seen number Computer time of last contact

---@class State
---@field readings Readings
---@field controls Controls
---@field triggers table<string, TriggerState>
---@field remote table<string, { readings: Readings, controls: Controls }>
---@field network table<string, NetworkInfo>

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
  remote = {},
  network = {},
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

--- Store data received from a remote node
---@param node_id string
---@param data table { readings?: Readings, controls?: Controls }
function state.mergeRemote(node_id, data)
  if not state.remote[node_id] then
    state.remote[node_id] = {}
  end
  if data.readings then
    state.remote[node_id].readings = data.readings
  end
  if data.controls then
    state.remote[node_id].controls = data.controls
  end
end

--- Clear all remote data
function state.clearRemote()
  state.remote = {}
end

--- Store peripheral info received from a remote node
---@param node_id string
---@param peripherals table[] List of { name, type, methods? }
function state.updateNetwork(node_id, peripherals)
  if not state.network[node_id] then
    state.network[node_id] = {}
  end
  state.network[node_id].peripherals = peripherals
  state.network[node_id].last_seen = os.clock()
end

return state
