---@class OutputModule
local output = {}
local config = require("src.config")

--- Apply trigger outputs to redstone/peripheral
--- Reads state.triggers and executes configured actions
--- Supports target_node for P2P routing (local actions only)
---@param state State Central state with trigger evaluations
---@param node_id? string Current node id (actions matching this node execute locally)
function output.tick(state, node_id)
  local rules = config.get("triggers", "triggers") or {}
  for _, rule in ipairs(rules) do
    local tr_state = state.triggers[rule.id]
    local active = tr_state and tr_state.active or false
    if not shouldRoute(rule, node_id) then
      output.applyAction(rule.action, active)
    end
  end
end

--- Check if an action should be routed to another node
---@param rule table Trigger rule with optional target_node
---@param node_id? string Current node id
---@return boolean true if action should be sent remotely
function output.shouldRoute(rule, node_id)
  if not rule.target_node then return false end
  if not node_id then return false end
  return rule.target_node ~= node_id
end

--- Execute a single action (redstone output or peripheral call)
---@param action table { type: string, side: string, method?: string, value?: boolean }
---@param active boolean Whether trigger is currently firing
function output.applyAction(action, active)
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
