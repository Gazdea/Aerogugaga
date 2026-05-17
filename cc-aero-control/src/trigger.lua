local trigger = {}
local config = require("src.config")

trigger._states = {}

function trigger.tick(readings, state, rules_override, api_helpers)
  local rules = rules_override or config.get("triggers", "triggers") or {}
  for _, rule in ipairs(rules) do
    if rule.enabled ~= false then
      if not trigger._states[rule.id] then
        trigger._states[rule.id] = { active = false, value = 0 }
      end
      local cur = trigger._states[rule.id]
      local value = resolveSource(readings, rule.condition.source)
      local hysteresis = rule.hysteresis or 0
      local threshold = rule.condition.threshold or 0

      if cur.active then
        if rule.condition.operator == ">" or rule.condition.operator == ">=" then
          cur.active = value > (threshold - hysteresis)
        elseif rule.condition.operator == "<" or rule.condition.operator == "<=" then
          cur.active = value < (threshold + hysteresis)
        else
          cur.active = evalCondition(value, rule.condition)
        end
      else
        cur.active = evalCondition(value, rule.condition)
      end

      cur.value = value
      state.triggers[rule.id] = {
        active = cur.active,
        value = value,
        threshold = threshold,
        operator = rule.condition.operator,
        source = rule.condition.source,
      }
    end
  end

  loadCodeTriggers(state, api_helpers)
end

local function loadCodeTriggers(state, api_helpers)
  local ok, custom = pcall(require, "config.triggers_custom")
  if not ok or type(custom) ~= "table" then return end

  local data_api = {
    readings = state.readings,
    controls = state.controls,
    triggers = state.triggers,
    remote = state.remote,
    network = state.network,
  }

  local trigger_api = {}
  function trigger_api:redstone(side, value)
    if side then redstone.setOutput(side, value) end
  end
  function trigger_api:peripheral(side, method, ...)
    if side and method then pcall(peripheral.call, side, method, ...) end
  end
  function trigger_api:exec(target, action)
    if target and action and api_helpers and api_helpers.network then
      api_helpers.network.sendExec(target, action)
    end
  end
  function trigger_api:log(msg)
    if api_helpers and api_helpers.debug and msg then
      print("[trigger] " .. msg)
    end
  end

  for _, ct in ipairs(custom) do
    if type(ct) == "table" and ct.id and ct.check then
      if ct.enabled ~= false then
        if not trigger._states[ct.id] then
          trigger._states[ct.id] = { active = false, value = 0 }
        end
        local was_active = trigger._states[ct.id].active
        local now_active = ct.check(data_api)
        trigger._states[ct.id].active = now_active
        state.triggers[ct.id] = {
          active = now_active,
          value = 0,
          threshold = 0,
          operator = "custom",
          source = "custom",
        }
        if now_active and not was_active and ct.fire then
          ct.fire(trigger_api)
        elseif not now_active and was_active and ct.clear then
          ct.clear(trigger_api)
        end
      end
    end
  end
end

function resolveSource(readings, source)
  if not source then
    return 0
  end
  local parts = {}
  for part in source:gmatch("[%w_]+") do
    table.insert(parts, part)
  end
  local val = readings
  for _, part in ipairs(parts) do
    if type(val) ~= "table" then
      return 0
    end
    val = val[part]
  end
  return type(val) == "number" and val or 0
end

function evalCondition(value, condition)
  local op = condition.operator or ">"
  local threshold = condition.threshold or 0
  if op == ">" then
    return value > threshold
  elseif op == "<" then
    return value < threshold
  elseif op == ">=" then
    return value >= threshold
  elseif op == "<=" then
    return value <= threshold
  elseif op == "==" then
    return math.abs(value - threshold) < 0.001
  end
  return false
end

return trigger
