---@class FontModule
local font = {}

--- Cyrillic → CC:T textpack codepoint mapping
--- Texture pack replaces CP437 font slots with Cyrillic glyphs
local map = {}

-- Capital letters (А-Я)
map["А"] = "\191"; map["Б"] = "\192"; map["В"] = "\193"; map["Г"] = "\194"
map["Д"] = "\195"; map["Е"] = "\196"; map["Ё"] = "\197"; map["Ж"] = "\198"
map["З"] = "\199"; map["И"] = "\200"; map["Й"] = "\201"; map["К"] = "\202"
map["Л"] = "\203"; map["М"] = "\204"; map["Н"] = "\205"; map["О"] = "\206"
map["П"] = "\207"; map["Р"] = "\208"; map["С"] = "\209"; map["Т"] = "\210"
map["У"] = "\211"; map["Ф"] = "\212"; map["Х"] = "\213"; map["Ц"] = "\214"
map["Ч"] = "\215"; map["Ш"] = "\216"; map["Щ"] = "\217"; map["Ъ"] = "\218"
map["Ы"] = "\219"; map["Ь"] = "\220"; map["Э"] = "\221"; map["Ю"] = "\222"
map["Я"] = "\223"

-- Lowercase letters (а-я)
map["а"] = "\224"; map["б"] = "\225"; map["в"] = "\226"; map["г"] = "\227"
map["д"] = "\228"; map["е"] = "\229"; map["ё"] = "\230"; map["ж"] = "\231"
map["з"] = "\232"; map["и"] = "\233"; map["й"] = "\234"; map["к"] = "\235"
map["л"] = "\236"; map["м"] = "\237"; map["н"] = "\238"; map["о"] = "\239"
map["п"] = "\240"; map["р"] = "\241"; map["с"] = "\242"; map["т"] = "\243"
map["у"] = "\244"; map["ф"] = "\245"; map["х"] = "\246"; map["ц"] = "\247"
map["ч"] = "\248"; map["ш"] = "\249"; map["щ"] = "\250"; map["ъ"] = "\251"
map["ы"] = "\252"; map["ь"] = "\253"; map["э"] = "\254"; map["ю"] = "\255"
map["я"] = "\013"

--- Encode Cyrillic UTF-8 text to CC:T textpack codepoints
---@param text string UTF-8 input (e.g. "Привет")
---@return string Encoded string for CC:T terminal/monitor
function font.encode(text)
  if not text then
    return ""
  end
  return text:gsub("([\194-\223][\128-\191])", function(seq)
    local c = map[seq]
    if c then
      return c
    end
    return seq
  end)
end

return font
