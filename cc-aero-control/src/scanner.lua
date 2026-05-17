---@class ScannerModule
local scanner = {}

local p = require("peripheral_interfaces")
local config = require("src.config")
local alias = require("src.alias")

--- Scan all connected peripherals and return structured data
--- Uses config/sensors.json to map velocity sensors to axes
---@return table { angles: table, altitude: table, velocity: table,
---         velocity_magnitude: number, rel_angle: number, raw: table }
function scanner.scan()
  local data = {
    angles = { pitch = 0, yaw = 0, roll = 0 },
    altitude = { height = 0, pressure = 0 },
    velocity = { x = 0, y = 0, z = 0 },
    velocity_magnitude = 0,
    rel_angle = 0,
    raw = {},
  }

  if p.top then
    local ok, pitch, yaw, roll = pcall(p.top.getAngles, p.top)
    if ok then
      data.angles.pitch = pitch or 0
      data.angles.yaw = yaw or 0
      data.angles.roll = roll or 0
    end
  end

  if p.altitude_sensor_0 then
    local ok_h, height = pcall(p.altitude_sensor_0.getHeight, p.altitude_sensor_0)
    if ok_h then
      data.altitude.height = height or 0
    end
    local ok_p, pressure = pcall(p.altitude_sensor_0.getAirPressure, p.altitude_sensor_0)
    if ok_p then
      data.altitude.pressure = pressure or 0
    end
  end

  if p.navigation_table_1 then
    local ok_a, angle = pcall(p.navigation_table_1.getRelativeAngle, p.navigation_table_1)
    if ok_a then
      data.rel_angle = angle or 0
    end
  end

  local axes = config.get("sensors", "velocity") or {}
  for sensor_name, axis in pairs(axes) do
    local actual_name = alias.resolve(sensor_name)
    local sensor = p[actual_name]
    if sensor then
      local ok, r1, r2, r3 = pcall(sensor.getVelocity, sensor)
      if ok then
        data.raw[sensor_name] = { r1, r2, r3 }
        data.velocity[axis] = r1 or 0
      end
    end
  end

  data.velocity_magnitude = math.sqrt(
    data.velocity.x ^ 2 + data.velocity.y ^ 2 + data.velocity.z ^ 2
  )

  return data
end

return scanner
