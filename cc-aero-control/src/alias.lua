local alias = {}
local config = require("src.config")

function alias.resolve(name)
  local aliases = config.get("aliases", "aliases") or {}
  if aliases[name] then
    return aliases[name]
  end
  return name
end

function alias.reverse(real_name)
  local aliases = config.get("aliases", "aliases") or {}
  for alias_name, target in pairs(aliases) do
    if target == real_name then
      return alias_name
    end
  end
  return real_name
end

function alias.getAll()
  return config.get("aliases", "aliases") or {}
end

return alias
