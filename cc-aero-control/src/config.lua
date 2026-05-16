---@class ConfigModule
local config = {}

local defaults = {
  settings = {
    update_interval = 0.05,
    monitor_side = nil,
    locale = "en",
    debug = false,
  },
  bindings = {},
  sensors = { velocity = {} },
  triggers = { triggers = {} },
}

local cache = {}

---@param path string File path
---@return table|nil Parsed JSON table or nil
local function loadJSON(path)
  local file = fs.open(path, "r")
  if not file then
    return nil
  end
  local content = file.readAll()
  file.close()
  local ok, result = pcall(textutils.parseJSON, content)
  if not ok then
    return nil
  end
  return result
end

--- Get a config section or a specific key within it
--- Loads config/<section>.json, falls back to defaults on error
---@param section string Config section name (e.g. "settings", "bindings")
---@param key? string Optional key within section
---@return any Config value (table for section, value for key)
function config.get(section, key)
  if not cache[section] then
    local loaded = loadJSON("config/" .. section .. ".json")
    cache[section] = loaded or (defaults[section] or {})
  end
  if key ~= nil then
    return cache[section][key]
  end
  return cache[section]
end

--- Clear config cache so next get() re-reads from disk
function config.reload()
  for k in pairs(cache) do
    cache[k] = nil
  end
end

return config
