local config = require("src.config")
local i18n = require("lib.i18n")
local scanner = require("src.scanner")
local control = require("src.control")
local trigger = require("src.trigger")
local output = require("src.output")
local display = require("src.display")
local state = require("src.state")

local locale = config.get("settings", "locale")
i18n.init(locale)
display.init(config.get("settings", "monitor_side"), locale)

if config.get("settings", "debug") then
  print("Dashboard starting")
  print("  Locale:", locale)
  local bind_count = 0
  for _ in pairs(config.get("bindings") or {}) do
    bind_count = bind_count + 1
  end
  print("  Bindings:", bind_count)
  print("  Triggers:", #(config.get("triggers", "triggers") or {}))
end

local tick_count = 0
while true do
  local readings = scanner.scan()
  state.updateReadings(readings)
  control.tick(state)
  trigger.tick(readings, state)
  output.tick(state)

  if tick_count % 2 == 0 then
    display.render(readings, state)
  end

  tick_count = tick_count + 1
  sleep(config.get("settings", "update_interval") or 0.05)
end
