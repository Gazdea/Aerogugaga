---@class ProxyModule
local proxy = {}

local _aliasResolver = nil

--- Set a function to resolve aliases before peripheral calls
--- The resolver receives a side/name string and returns the actual side string
---@param fn function|nil Resolver function or nil to clear
function proxy.setAliasResolver(fn)
  _aliasResolver = fn
end

--- Resolve a name through the alias resolver if set
---@param name string
---@return string
local function resolve(name)
  if _aliasResolver then
    return _aliasResolver(name)
  end
  return name
end

--- Safe pcall-wrapped peripheral.call
--- Returns up to 8 values on success, nil on failure
---@param side string Peripheral side name
---@param method string Method name to call
---@vararg any Arguments passed to the method
---@return any... Up to 8 return values
function proxy.call(side, method, ...)
  local ok, r1, r2, r3, r4, r5, r6, r7, r8 = pcall(peripheral.call, resolve(side), method, ...)
  if ok then
    return r1, r2, r3, r4, r5, r6, r7, r8
  end
end

--- Safe pcall-wrapped peripheral.wrap
---@param side string Peripheral side name
---@return table|nil Wrapped peripheral or nil if not present
function proxy.wrap(side)
  local ok, per = pcall(peripheral.wrap, resolve(side))
  if ok and per then
    return per
  end
  return nil
end

return proxy
