local dir = fs.getDir(shell.getRunningProgram())
if dir ~= "" then
  if dir:sub(1, 1) ~= "/" then
    dir = fs.combine(shell.dir(), dir)
  end
  shell.setDir(dir)
end
package.path = shell.dir() .. "/?.lua;" .. package.path

local i18n = require("lib.i18n")

print("=== i18n Test ===")

-- Test 1: Load English
print("\n--- Test 1: en locale ---")
i18n.init("en", shell.dir() .. "/i18n")
print("title = " .. i18n.t("dashboard.title"))
print("altitude = " .. i18n.t("dashboard.altitude"))
print("units.meters = " .. i18n.t("dashboard.units.meters"))
print("missing.key = " .. i18n.t("missing.key"))

-- Test 2: Load Russian
print("\n--- Test 2: ru locale ---")
i18n.init("ru", shell.dir() .. "/i18n")
print("title = " .. i18n.t("dashboard.title"))
print("altitude = " .. i18n.t("dashboard.altitude"))
print("units.meters = " .. i18n.t("dashboard.units.meters"))

-- Test 3: Non-existent locale (should fallback to en)
print("\n--- Test 3: xx locale (fallback) ---")
i18n.init("xx", shell.dir() .. "/i18n")
print("title = " .. i18n.t("dashboard.title"))

-- Test 4: Font encoding (if font.lua available)
print("\n--- Test 4: font encoding ---")
local ok, font = pcall(require, "lib.font")
if ok then
  local test_str = i18n.t("dashboard.title")
  local encoded = font.encode(test_str)
  print("original len: " .. #test_str .. ", encoded len: " .. #encoded)
  print("encoded: " .. encoded)
else
  print("font.lua not loaded, skipping")
end

print("\n=== Done ===")
