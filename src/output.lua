---@class OutputModule
local output = {}

--- Apply trigger outputs to redstone/peripheral
--- Reads state.triggers and executes configured actions
---@param state State Central state with trigger evaluations
function output.tick(state)
  local rules = config.get("triggers", "triggers") or {}
  for _, rule in ipairs(rules) do
    local tr_state = state.triggers[rule.id]
    if tr_state then
      applyAction(rule.action, tr_state.active)
    else
      applyAction(rule.action, false)
    end
  end
end

--- Execute a single action (redstone output or peripheral call)
---@param action table { type: string, side: string, method?: string, value?: boolean }
---@param active boolean Whether trigger is currently firing
function applyAction(action, active)
  if not action then
    return
  end
  if action.type == "redstone" and action.side then
    redstone.setOutput(action.side, active and action.value ~= false)
  elseif action.type == "peripheral" and action.side and action.method then
    pcall(peripheral.call, action.side, action.method, active)
  end
end

return output
