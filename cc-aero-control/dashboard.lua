local dir = fs.getDir(shell.getRunningProgram())
if dir ~= "" then
  if dir:sub(1, 1) ~= "/" then
    dir = fs.combine(shell.dir(), dir)
  end
  shell.setDir(dir)
end

package.path = shell.dir() .. "/?.lua;" .. package.path

local config = require("src.config")
local i18n = require("lib.i18n")
local state = require("src.state")
local proxy = require("lib.proxy")
local alias = require("src.alias")

local args = { ... }
local node_id = args[1]

if node_id then
  config.setNodeId(node_id)
end

local nodeCfg = config.node()
local isP2P = nodeCfg and nodeCfg.id ~= nil
local debug = config.get("settings", "debug")

local network
local scanner
local control_mod
local trigger_mod
local output_mod
local display_mod
local discovery
local custom_display

if isP2P then
  if nodeCfg.network and nodeCfg.network.modem_side then
    network = require("src.network")
    network.init(nodeCfg.network.modem_side, nodeCfg.network.channel or 42)
    network.announce(node_id, {
      sensors = nodeCfg.sensors ~= nil,
      outputs = nodeCfg.triggers and #nodeCfg.triggers > 0,
      display = nodeCfg.display ~= nil,
    })
  end
  if nodeCfg.sensors then
    scanner = require("src.scanner")
  end
  if nodeCfg.bindings then
    control_mod = require("src.control")
  end
  trigger_mod = require("src.trigger")
  output_mod = require("src.output")
  if nodeCfg.display then
    local locale = nodeCfg.display.locale or "en"
    i18n.init(locale, shell.dir() .. "/i18n")
    display_mod = require("src.display")
    display_mod.init(nodeCfg.display.monitor_side, locale)
  end
  discovery = require("src.discovery")
  local ok, mod = pcall(require, "config.display_custom")
  if ok and type(mod) == "function" then
    custom_display = mod
  end
else
  local locale = config.get("settings", "locale")
  i18n.init(locale, shell.dir() .. "/i18n")
  scanner = require("src.scanner")
  control_mod = require("src.control")
  trigger_mod = require("src.trigger")
  output_mod = require("src.output")
  display_mod = require("src.display")
  display_mod.init(config.get("settings", "monitor_side"), locale)
end

proxy.setAliasResolver(alias.resolve)

if debug then
  print("Mode:", isP2P and "p2p" or "local")
  print("Node:", node_id or "-")
  if isP2P then
    print("  Net:", (network and true) or false)
    print("  Sensors:", scanner ~= nil)
    print("  Triggers:", trigger_mod ~= nil)
    print("  Custom display:", custom_display ~= nil)
    local per_count = #discovery.scan()
    print("  Local peripherals:", per_count)
  end
end

local function deepMerge(target, source)
  for k, v in pairs(source) do
    if type(v) == "table" and type(target[k]) == "table" then
      deepMerge(target[k], v)
    else
      target[k] = v
    end
  end
end

local function buildCombinedReadings()
  local combined = {
    angles = { pitch = 0, yaw = 0, roll = 0 },
    altitude = { height = 0, pressure = 0 },
    velocity = { x = 0, y = 0, z = 0 },
    velocity_magnitude = 0,
    rel_angle = 0,
    raw = {},
  }
  for _, rs in pairs(state.remote) do
    if rs.readings then
      deepMerge(combined, rs.readings)
    end
  end
  return combined
end

local function getTriggerRules()
  if isP2P and nodeCfg then
    return nodeCfg.triggers or {}
  end
  return config.get("triggers", "triggers") or {}
end

local function buildDisplayCtx()
  return {
    output = display_mod and display_mod.getOutput() or term,
    translate = i18n.t,
    encode = display_mod and display_mod.getEncode() or function(t) return t end,
    data = {
      readings = state.readings,
      controls = state.controls,
      triggers = state.triggers,
      remote = state.remote,
      network = state.network,
    },
    state = state,
  }
end

local per_broadcast_counter = 0
local tick_count = 0
while true do
  if network then
    local msgs = network.pollAll()
    for _, msg in ipairs(msgs) do
      if msg.type == "state" and msg.node_id ~= node_id then
        state.mergeRemote(msg.node_id, msg)
      elseif msg.type == "exec" and msg.target == node_id then
        output_mod.applyAction(msg.action, true)
      elseif msg.type == "peripherals" and msg.node_id ~= node_id and msg.list then
        state.updateNetwork(msg.node_id, msg.list)
      end
    end
  end

  if isP2P then
    local combined = buildCombinedReadings()
    if scanner then
      local local_readings = scanner.scan()
      deepMerge(combined, local_readings)
      if network then
        network.broadcastState({ readings = local_readings })
      end
    end
    state.updateReadings(combined)

    if discovery and network then
      per_broadcast_counter = per_broadcast_counter + 1
      if per_broadcast_counter >= 20 then
        per_broadcast_counter = 0
        network.broadcastPeripherals(discovery.scan())
      end
    end
  else
    state.updateReadings(scanner.scan())
  end

  if control_mod then
    control_mod.tick(state)
    if network then
      network.broadcastState({ controls = state.controls })
    end
  end

  if trigger_mod then
    trigger_mod.tick(state.readings, state, getTriggerRules(), {
      network = network,
      debug = debug,
    })
  end

  local rules = getTriggerRules()
  for _, rule in ipairs(rules) do
    local tr_state = state.triggers[rule.id]
    local active = tr_state and tr_state.active or false
    if active then
      if network and rule.target_node and rule.target_node ~= node_id then
        network.sendExec(rule.target_node, rule.action)
      else
        output_mod.applyAction(rule.action, true)
      end
    end
  end

  if custom_display then
    custom_display(buildDisplayCtx())
  elseif display_mod and tick_count % 2 == 0 then
    display_mod.render(state.readings, state)
  end

  tick_count = tick_count + 1
  sleep(config.get("settings", "update_interval") or 0.05)
end
