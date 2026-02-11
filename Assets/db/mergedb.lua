--[[
Merge TurtleWoW override data (pfDB) into VGDB.

Turtle files store data in pfDB[category][key.."-turtle"].
This script copies each entry into VGDB[category][key],
replacing existing entries and removing those marked with "_".
]]--

local DELETE_MARKER = "_"

-- Merge source table into destination table
-- Entries with value "_" are deleted from destination
local function mergeInto(dst, src)
    if not dst or not src then return end
    for k, v in pairs(src) do
        if v == DELETE_MARKER then
            dst[k] = nil
        else
            dst[k] = v
        end
    end
end

-- Data tables: pfDB[cat]["data-turtle"] -> VGDB[cat]["data"]
local dataCategories = { "quests", "units", "items", "objects", "areatrigger" }
for _, cat in ipairs(dataCategories) do
    if pfDB[cat] and pfDB[cat]["data-turtle"] then
        VGDB[cat] = VGDB[cat] or {}
        VGDB[cat]["data"] = VGDB[cat]["data"] or {}
        mergeInto(VGDB[cat]["data"], pfDB[cat]["data-turtle"])
    end
end

-- Locale tables: pfDB[cat]["enUS-turtle"] -> VGDB[cat]["enUS"]
local localeCategories = { "quests", "units", "items", "zones" }
for _, cat in ipairs(localeCategories) do
    if pfDB[cat] and pfDB[cat]["enUS-turtle"] then
        VGDB[cat] = VGDB[cat] or {}
        VGDB[cat]["enUS"] = VGDB[cat]["enUS"] or {}
        mergeInto(VGDB[cat]["enUS"], pfDB[cat]["enUS-turtle"])
    end
end

-- Free pfDB memory after merge
pfDB = nil
