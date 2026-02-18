--[[
Merge TurtleWoW override data into VGDB.

Turtle files store data in VGDB[category][key.."-turtle"].
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

-- Data tables: VGDB[cat]["data-turtle"] -> VGDB[cat]["data"]
local dataCategories = { "quests", "units", "items", "objects", "areatrigger" }
for _, cat in ipairs(dataCategories) do
    if VGDB[cat] and VGDB[cat]["data-turtle"] then
        VGDB[cat]["data"] = VGDB[cat]["data"] or {}
        mergeInto(VGDB[cat]["data"], VGDB[cat]["data-turtle"])
        VGDB[cat]["data-turtle"] = nil
    end
end

-- Locale tables: VGDB[cat]["enUS-turtle"] -> VGDB[cat]["enUS"]
local localeCategories = { "quests", "units", "items", "zones" }
for _, cat in ipairs(localeCategories) do
    if VGDB[cat] and VGDB[cat]["enUS-turtle"] then
        VGDB[cat]["enUS"] = VGDB[cat]["enUS"] or {}
        mergeInto(VGDB[cat]["enUS"], VGDB[cat]["enUS-turtle"])
        VGDB[cat]["enUS-turtle"] = nil
    end
end
