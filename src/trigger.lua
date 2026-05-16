---@class TriggerModule
local trigger = {}
trigger._states = {}

--- Evaluate all trigger rules and update state.triggers
--- Supports hysteresis to prevent rapid toggling
--- Uses config/triggers.json for rule definitions
---@param readings table Current sensor readings
---@param state State Central state (triggers updated in-place)
function trigger.tick(readings, state)
  local rules = config.get("triggers", "triggers") or {}
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
end

--- Resolve a dot-separated source path from readings
--- e.g. "angles.pitch" -> readings["angles"]["pitch"]
---@param readings table
---@param source string Dot-separated path
---@return number
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

--- Evaluate a single condition
--- Supported operators: >, <, >=, <=, ==
---@param value number
---@param condition table { operator: string, threshold: number }
---@return boolean
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
