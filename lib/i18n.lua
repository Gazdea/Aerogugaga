---@class I18nModule
local i18n = {}

local strings = {}

--- Initialize i18n with locale and optional base path
--- Loads <basePath>/<locale>.lua, falls back to <basePath>/en.lua
---@param locale string Locale name (e.g. "en", "ru")
---@param basePath? string Path to locale files (default "i18n")
function i18n.init(locale, basePath)
  locale = locale or "en"
  basePath = basePath or "i18n"
  local paths = { basePath .. "/" .. locale .. ".lua", basePath .. "/en.lua" }
  for _, path in ipairs(paths) do
    local ok, result = pcall(dofile, path)
    if ok and type(result) == "table" then
      strings = result
      return
    end
  end
  strings = {}
end

--- Translate a dot-separated key with optional format args
--- Supports nested keys: "dashboard.title", "dashboard.units.meters"
--- Falls back to key string if not found
---@param key string Dot-separated translation key
---@vararg any Optional format arguments for string.format
---@return string Translated string or key if missing
function i18n.t(key, ...)
  local parts = {}
  for k in key:gmatch("[^.]+") do
    table.insert(parts, k)
  end
  local current = strings
  for _, k in ipairs(parts) do
    if type(current) ~= "table" then
      return key
    end
    current = current[k]
  end
  if type(current) ~= "string" then
    return key
  end
  local args = { ... }
  if #args > 0 then
    return string.format(current, ...)
  end
  return current
end

return i18n
