---@class DisplayModule
local display = {}
local i18n = require("lib.i18n")

display._output = nil
display._encode = function(t) return t end

local function addLine(out, text, y)
  out.setCursorPos(1, y)
  out.write(display._encode(text))
  return y + 1
end

local renderLabels = {}

function display.init(monitor_side, locale)
  if locale == "ru" then
    local ok, mod = pcall(require, "lib.font")
    if ok and mod then
      display._encode = mod.encode
    end
  end
  if monitor_side then
    local ok, mon = pcall(peripheral.wrap, monitor_side)
    if ok then
      mon.setTextScale(0.5)
      display._output = mon
    else
      display._output = term
    end
  else
    display._output = term
  end
  renderLabels.y = display._output and 2 or 2
end

local function num(v)
  local n = tonumber(v)
  return n or 0
end

function display.render(readings, state)
  local out = display._output
  local t = i18n.t
  local e = display._encode

  out.clear()
  out.setCursorPos(1, 1)
  out.write(t("dashboard.title"))
  if state.controls.altitude_hold then
    out.write(e("  [" .. t("dashboard.altitude_hold") .. ": " .. t("dashboard.on") .. "]"))
  end

  local y = addLine(out, "", 2)

  y = addLine(out, string.format("%s: %7.1f %s    %s: %7.1f %s",
    t("dashboard.altitude"), num(readings.altitude.height), t("dashboard.units.meters"),
    t("dashboard.pressure"), num(readings.altitude.pressure), t("dashboard.units.kPa")), y)

  y = addLine(out, string.format("%s: %6.1f %s    %s: %6.1f %s",
    t("dashboard.pitch"), num(readings.angles.pitch), t("dashboard.units.degrees"),
    t("dashboard.yaw"), num(readings.angles.yaw), t("dashboard.units.degrees")), y)

  y = addLine(out, string.format("%s: %6.1f %s",
    t("dashboard.roll"), num(readings.angles.roll), t("dashboard.units.degrees")), y)

  y = addLine(out, "-------------------------", y)

  y = addLine(out, string.format("%s %s: %6.1f %s",
    t("dashboard.velocity"), t("dashboard.x_axis"),
    num(readings.velocity.x), t("dashboard.units.m_s")), y)

  y = addLine(out, string.format("%s %s: %6.1f %s",
    t("dashboard.velocity"), t("dashboard.y_axis"),
    num(readings.velocity.y), t("dashboard.units.m_s")), y)

  y = addLine(out, string.format("%s %s: %6.1f %s",
    t("dashboard.velocity"), t("dashboard.z_axis"),
    num(readings.velocity.z), t("dashboard.units.m_s")), y)

  y = addLine(out, string.format("%s: %6.1f %s",
    t("dashboard.velocity_magnitude"),
    num(readings.velocity_magnitude), t("dashboard.units.m_s")), y)

  y = addLine(out, "-------------------------", y)

  y = addLine(out, string.format("%s: %6.1f %s",
    t("dashboard.rel_angle"),
    num(readings.rel_angle), t("dashboard.units.degrees")), y)

  for id, tr_state in pairs(state.triggers) do
    y = addLine(out, string.format("%s %s: %s (%.1f)",
      t("dashboard.trigger"), id,
      tr_state.active and t("dashboard.active") or t("dashboard.inactive"),
      num(tr_state.value)), y)
  end

  y = addLine(out, "========================", y)
end

--- Return current output target (term or monitor)
function display.getOutput()
  return display._output
end

--- Return current font encoder function
function display.getEncode()
  return display._encode
end

return display
