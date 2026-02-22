--[[
Guidelime Vanilla

Author: Grommey

Description:
Guide Editor module - Create, edit, save, and manage guides in-game.
Data model, save/load, import, tag insertion, auto-detect, preview.
]]--
local GLV = LibStub("GuidelimeVanilla")

local GuideEditor = {}
GLV.GuideEditor = GuideEditor

-- Custom Guides pack name
local CUSTOM_PACK = "Custom Guides"

-- Tag colors for syntax highlighting (same mapping as codes in Parser)
GuideEditor.TAG_COLORS = {
    N   = "FF6B8BD4",  -- blue (guide name)
    NX  = "FF6B8BD4",  -- blue (next guide)
    GA  = "FFa335ee",  -- purple (faction filter)
    A   = "FFa335ee",  -- purple (class/race filter)
    QA  = "FF00ffff",  -- cyan (quest accept)
    QC  = "FF0079d2",  -- blue (quest complete)
    QT  = "FF00ff00",  -- green (quest turnin)
    G   = "FFFFFF00",  -- yellow (goto)
    TAR = "FFFFD700",  -- gold (target)
    CI  = "FFFF8C00",  -- dark orange (collect item)
    UI  = "FFFF6347",  -- tomato (use item)
    H   = "FF9370DB",  -- medium purple (hearthstone)
    S   = "FF9370DB",  -- medium purple (bind hearthstone)
    P   = "FF87CEEB",  -- sky blue (flight path)
    F   = "FF87CEEB",  -- sky blue (fly to)
    T   = "FF32CD32",  -- lime green (train)
    LE  = "FF32CD32",  -- lime green (learn)
    SK  = "FF32CD32",  -- lime green (skill)
    XP  = "FFFFB347",  -- orange (experience)
    O   = "FF808080",  -- gray (ongoing)
    OC  = "FF808080",  -- gray (optional complete)
    D   = "FF808080",  -- gray (description)
}


--[[ INITIALIZATION ]]--

function GuideEditor:Init()
    -- Re-register all saved custom guides on addon load (from global storage)
    local guides = GLV.Settings:GetGlobalOption({"GuideEditor", "Guides"})
    if guides then
        for name, entry in pairs(guides) do
            if entry and entry.text then
                local packName = entry.packName or CUSTOM_PACK
                GLV:RegisterGuide(entry.text, packName)
            end
        end
    end
end


--[[ GUIDE DATA OPERATIONS ]]--

-- Save a guide to SavedVariables and register it
function GuideEditor:SaveGuide(name, text, packName)
    if not name or name == "" or not text then return false end

    packName = packName or CUSTOM_PACK

    local entry = {
        text = text,
        lastModified = time(),
        packName = packName,
    }

    GLV.Settings:SetGlobalOption(entry, {"GuideEditor", "Guides", name})
    GLV.Settings:SetGlobalOption(name, {"GuideEditor", "LastOpenGuide"})

    -- Register so it's playable immediately
    GLV:RegisterGuide(text, packName)

    return true
end

-- Load a saved guide by name
function GuideEditor:LoadGuide(name)
    if not name then return nil end
    local entry = GLV.Settings:GetGlobalOption({"GuideEditor", "Guides", name})
    return entry
end

-- Delete a saved guide
function GuideEditor:DeleteGuide(name)
    if not name then return false end
    GLV.Settings:SetGlobalOption(nil, {"GuideEditor", "Guides", name})

    -- If this was the last open guide, clear it
    local lastOpen = GLV.Settings:GetGlobalOption({"GuideEditor", "LastOpenGuide"})
    if lastOpen == name then
        GLV.Settings:SetGlobalOption(nil, {"GuideEditor", "LastOpenGuide"})
    end
    return true
end

-- Get list of saved guide names (sorted)
function GuideEditor:GetSavedGuideNames()
    local guides = GLV.Settings:GetGlobalOption({"GuideEditor", "Guides"})
    local names = {}
    if guides then
        for name, _ in pairs(guides) do
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

-- Get the last opened guide name
function GuideEditor:GetLastOpenGuide()
    return GLV.Settings:GetGlobalOption({"GuideEditor", "LastOpenGuide"})
end


--[[ METADATA EXTRACTION ]]--

-- Extract metadata from guide text using the parser (most robust approach)
function GuideEditor:ExtractMetadata(text)
    if not text then return {} end

    local meta = {}

    -- Use the actual parser to extract guide metadata
    if GLV.Parser and GLV.Parser.parseGuide then
        local guide = GLV.Parser:parseGuide(text, "EditorPreview")
        if guide then
            meta.name = guide.name
            meta.minLevel = guide.minLevel
            meta.maxLevel = guide.maxLevel
            meta.description = guide.description
            meta.faction = guide.faction
            -- guide.next is "12-20 The Barrens" (includes levels), keep full format
            if guide.next then
                meta.nextGuide = guide.next
            end
        end
    end

    return meta
end

-- Build the [N], [D] and [GA] header lines from metadata fields
function GuideEditor:BuildHeaderFromMetadata(name, minLevel, maxLevel, faction, description)
    local lines = {}

    -- [N min-max Name]
    if name and name ~= "" then
        local min = minLevel or "1"
        local max = maxLevel or "60"
        table.insert(lines, "[N " .. min .. "-" .. max .. " " .. name .. "]")
    end

    -- [D description] (convert newlines to \\ for guide format)
    if description and description ~= "" then
        local escaped = string.gsub(description, "\n", "\\\\")
        table.insert(lines, "[D " .. escaped .. "]")
    end

    -- [GA faction]
    if faction and faction ~= "" then
        table.insert(lines, "[GA " .. faction .. "]")
    end

    return lines
end

-- Build [NX] line from metadata (nextGuide already contains "11-19 Darkshore" format)
function GuideEditor:BuildNextGuideLine(nextGuide)
    if not nextGuide or nextGuide == "" then return nil end
    return "[NX " .. nextGuide .. "]"
end


--[[ SYNTAX HIGHLIGHTING ]]--

-- Colorize guide text for preview (color tags by type)
function GuideEditor:ColorizeText(text)
    if not text then return "" end

    local result = {}
    -- Process line by line
    for line in string.gfind(text .. "\n", "(.-)\n") do
        -- Replace tags with colored versions
        local colored = string.gsub(line, "%[([%a]+)([^%]]*)%]", function(tag, params)
            local color = self.TAG_COLORS[tag]
            if color then
                return "|c" .. color .. "[" .. tag .. params .. "]|r"
            else
                return "[" .. tag .. params .. "]"
            end
        end)
        table.insert(result, colored)
    end

    return table.concat(result, "\n")
end


--[[ TAG INSERTION HELPERS ]]--

-- Insert text at cursor position in the currently focused per-line EditBox.
-- Falls back to the last line if no per-line box has focus.
-- Tracks the last focused per-line box via .lastFocusedLine on editChild.
function GuideEditor:InsertTag(editBox, tagText)
    local editChild = getglobal("GLV_EditorEditChild")
    if not editChild or not editChild.lineBoxes then
        -- Fallback: hidden editBox
        if editBox then editBox:SetFocus(); editBox:Insert(tagText) end
        return
    end

    local boxes = editChild.lineBoxes
    local focusedBox = editChild.lastFocusedLine
    if not focusedBox and table.getn(boxes) > 0 then
        focusedBox = boxes[table.getn(boxes)]
    end
    if not focusedBox then return end

    -- Special case: newline insertion → simulate Enter (create new line below)
    if tagText == "\n" or tagText == "\n " then
        focusedBox:SetFocus()
        -- Find index of focused box
        local myIdx = 0
        for i = 1, table.getn(boxes) do
            if boxes[i] == focusedBox then myIdx = i; break end
        end
        if myIdx > 0 and editChild.createLineBox then
            local newBox = editChild.createLineBox(myIdx + 1, "")
            newBox:SetFocus()
            -- Sync
            if editChild.syncToHidden then editChild.syncToHidden() end
        end
        return
    end

    focusedBox:SetFocus()
    focusedBox:Insert(tagText)
end

-- Get player position as formatted [G x.1f,y.1f Zone]
function GuideEditor:GetPlayerPositionTag()
    SetMapToCurrentZone()
    local px, py = GetPlayerMapPosition("player")
    if not px or not py or (px == 0 and py == 0) then
        return nil, "Cannot get position (indoors?)"
    end
    local zone = GetZoneText()
    if not zone or zone == "" then
        return nil, "Cannot get zone name"
    end
    local tag = string.format("[G %.1f,%.1f %s]", px * 100, py * 100, zone)
    return tag
end

-- Get last accepted quest as [QA id] tag
function GuideEditor:GetLastAcceptedQuestTag()
    if not GLV.QuestTracker or not GLV.QuestTracker.store then return nil end

    local accepted = GLV.QuestTracker.store.Accepted
    if not accepted then return nil end

    local latestId = nil
    local latestTime = 0

    for id, data in pairs(accepted) do
        if type(data) == "table" and data.timestamp then
            if data.timestamp > latestTime then
                latestTime = data.timestamp
                latestId = id
            end
        end
    end

    if latestId then
        return "[QA" .. latestId .. "]"
    end
    return nil
end


--[[ IMPORT ]]--

-- Get importable guide packs and their guides
function GuideEditor:GetImportableGuides()
    local packs = {}
    if not GLV.loadedGuides then return packs end

    for packName, guides in pairs(GLV.loadedGuides) do
        if guides and next(guides) then
            local guideList = {}
            for guideId, guideData in pairs(guides) do
                table.insert(guideList, {
                    id = guideId,
                    name = guideData.name or guideId,
                    minLevel = guideData.minLevel,
                    maxLevel = guideData.maxLevel,
                })
            end
            table.sort(guideList, function(a, b)
                local aMin = tonumber(a.minLevel) or 0
                local bMin = tonumber(b.minLevel) or 0
                if aMin ~= bMin then return aMin < bMin end
                return (a.name or "") < (b.name or "")
            end)
            table.insert(packs, {name = packName, guides = guideList})
        end
    end
    table.sort(packs, function(a, b) return a.name < b.name end)

    return packs
end

-- Import a guide from a loaded pack into the editor
function GuideEditor:ImportGuide(packName, guideId)
    if not GLV.loadedGuides then return nil end
    local pack = GLV.loadedGuides[packName]
    if not pack then return nil end
    local guideData = pack[guideId]
    if not guideData or not guideData.text then return nil end

    return guideData.text
end


--[[ TOGGLE ]]--

function GuideEditor:Toggle()
    local frame = getglobal("GLV_EditorFrame")
    if frame then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    end
end
