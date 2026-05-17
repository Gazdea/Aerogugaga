local discovery = {}

function discovery.scan()
  local list = {}
  for _, name in ipairs(peripheral.getNames()) do
    local ok_type, ptype = pcall(peripheral.getType, name)
    local ok_methods, methods = pcall(peripheral.getMethods, name)
    local entry = { name = name }
    if ok_type then
      entry.type = type(ptype) == "table" and table.concat(ptype, ", ") or ptype
    else
      entry.type = "unknown"
    end
    if ok_methods and methods then
      table.sort(methods)
      entry.methods = methods
    end
    table.insert(list, entry)
  end
  table.sort(list, function(a, b) return a.name < b.name end)
  return list
end

return discovery
