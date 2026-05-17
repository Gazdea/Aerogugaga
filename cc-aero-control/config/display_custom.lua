-- config/display_custom.lua
-- Optional user-defined display renderer.
-- If this file exists and returns a function, it replaces the built-in
-- display.render(). The function receives a context table with:
--
--   ctx.output     — term or monitor (write, setCursorPos, clear)
--   ctx.translate  — i18n translate function (key → string)
--   ctx.encode     — Cyrillic font encoder (text → encoded)
--   ctx.data       — full state: { readings, controls, triggers, remote, network }
--   ctx.state      — reference to raw state module (for direct access)
--
-- Return nil (or don't create this file) to use the built-in renderer.

return function(ctx)
  local out = ctx.output
  local d = ctx.data
  local t = ctx.translate
  local enc = ctx.encode

  out.clear()
  out.setCursorPos(1, 1)
  out.write(enc(t("dashboard.title")))

  local y = 3
  out.setCursorPos(1, y); out.write(enc("-- Sensors --"))
  y = y + 1
  out.setCursorPos(1, y)
  out.write(string.format("Altitude: %.1f m", d.readings.altitude.height))

  y = y + 1
  out.setCursorPos(1, y)
  out.write(string.format("Speed: %.1f m/s", d.readings.velocity_magnitude))

  y = y + 1
  out.setCursorPos(1, y); out.write(enc("-- Network --"))
  for id, info in pairs(d.network) do
    y = y + 1
    out.setCursorPos(1, y)
    out.write(id .. ":")
    for _, p in ipairs(info.peripherals or {}) do
      y = y + 1
      out.setCursorPos(1, y)
      out.write("  " .. p.name .. " (" .. p.type .. ")")
    end
  end

  y = y + 1
  out.setCursorPos(1, y); out.write(enc("-- Remote --"))
  for id, rmt in pairs(d.remote) do
    local h = rmt.readings and rmt.readings.altitude and rmt.readings.altitude.height
    y = y + 1
    out.setCursorPos(1, y)
    out.write(id .. " altitude: " .. (h and string.format("%.1f", h) or "?") .. " m")
  end

  y = y + 1
  out.setCursorPos(1, y); out.write(enc("-- Triggers --"))
  for id, tr in pairs(d.triggers) do
    y = y + 1
    out.setCursorPos(1, y)
    local status = tr.active and "ACTIVE" or "inactive"
    out.write(id .. ": " .. status)
  end
end
