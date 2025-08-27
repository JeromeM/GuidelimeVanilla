--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Guide Parser.
This file is used to extract every steps in the guide and format it
]]--
local GLV = LibStub("GuidelimeVanilla")

local Parser = {}

local codes = {
    N   = "NAME",
    NX  = "NEXT_GUIDE",
    D   = "DESCRIPTION",
    O   = "OPTIONAL",
    OC  = "OPTIONAL_COMPLETE_WITH_NEXT",
    GA  = "GUIDE_APPLIES",
    Q   = "QUEST",
    QA  = "ACCEPT",
    QC  = "COMPLETE",
    QT  = "TURNIN",
    QS  = "SKIP",
    G   = "GOTO",
    L   = "LOCATION",
    XP  = "EXPERIENCE",
    CI  = "COLLECT_ITEM",
    TAR = "TARGET_ID",
    A   = "APPLIES",
    LE  = "LEARN",
    SP  = "SPELL",
    R   = "REPAIR",
    V   = "VENDOR",
    H   = "HEARTHSTONE",
    S   = "BIND_HEARTHSTONE",
    UI  = "USE_ITEM",
}
local reverseCodes = {}
for k, v in pairs(codes) do reverseCodes[v] = k end


--[[ CORE PARSING FUNCTIONS ]]--

-- Get super tag for quest-related tags
function Parser:getSuperTag(tag)
	if tag == "ACCEPT" then return "QUEST" end
	if tag == "TURNIN" then return "QUEST" end
	if tag == "COMPLETE" then return "QUEST" end
	return tag
end

-- Parse experience requirement formats from XP tags
function Parser:ParseExperienceRequirement(xpString)
    if not xpString or xpString == "" then
        return nil
    end
    
    -- Extract only the numeric part at the beginning of the string
    -- [XP3] or [XP4-290 Grind text] or [XP3.5 Some text]
    local numericPart, textPart = string.match(xpString, "^([%d%.%-]+)(.*)")
    if not numericPart then
        return nil
    end
    
    -- [XP3] -> Reach level 3
    local simpleLevel = string.match(numericPart, "^(%d+)$")
    if simpleLevel then
        return {
            targetLevel = tonumber(simpleLevel),
            targetPercent = 100,
            type = "level",
            text = textPart
        }
    end
    
    -- [XP3-100] -> Need 100 XP for level 3
    local levelMinus, xpMinus = string.match(numericPart, "^(%d+)%-(%d+)$")
    if levelMinus and xpMinus then
        return {
            targetLevel = tonumber(levelMinus),
            xpMinus = tonumber(xpMinus),
            type = "level_minus",
            text = textPart
        }
    end
    
    -- [XP3.5] -> Level 3 with 50% XP or [XP2.925] -> Level 2 with 92.5% XP
    local levelFloat = tonumber(numericPart)
    if levelFloat then
        local level = math.floor(levelFloat)
        local decimal = levelFloat - level
        
        -- Handle cases like XP5.10 (which should be 10%, not 1%)
        local percent
        if string.find(numericPart, "%.%d%d$") then
            -- If we have exactly 2 digits after the point (ex: 5.10), treat them as direct percentages
            percent = decimal * 100
        else
            -- Otherwise, normal conversion (ex: 5.5 = 50%)
            percent = decimal * 100
        end
        
        return {
            targetLevel = level,
            targetPercent = percent,
            type = "level_percent",
            text = textPart
        }
    end
    
    return nil
end

-- Main guide parsing function
function Parser:parseGuide(guide, group)
    local parsedGuide = {}
    
    parsedGuide.steps = {}
    parsedGuide.group = group

    local isFirstLine = true

    for line in string.gfind(guide .. "\n", "([^\n]*)\n") do
        local parsedLine = {}

        line = string.gsub(line, "^%s*(.-)%s*$", "%1")

        if isFirstLine and line == "" then
            isFirstLine = false
        else
            isFirstLine = false
            if self:filterClassRace(line) then
                if line ~= "" then
                    local count = 0
                    stepText, count = string.gsub(line, "%[(.-)%]", function(code)
                        local tag = codes[string.sub(code, 1, 3)]
                        if tag == nil then tag = codes[string.sub(code, 1, 2)] end
                        if tag == nil then tag = codes[string.sub(code, 1, 1)] end

                        local tagContent = string.sub(code, safe_strlen(reverseCodes[tag]) + 1)
                        tagContent = string.gsub(tagContent, "^%s*", "")

                        if tag == "NAME" then
                            parsedGuide.minLevel, parsedGuide.maxLevel, parsedGuide.name, parsedGuide.id = self:getGuideName(tagContent)
                            return ""

                        elseif tag == "DESCRIPTION" then
                            parsedGuide.description = self:getGuideDescription(tagContent)
                            return ""

                        elseif tag == "GUIDE_APPLIES" then
                            parsedGuide.faction = tagContent
                            return ""

                        elseif tag == "NEXT_GUIDE" then
                            parsedGuide.next = tagContent
                            parsedGuide.hasCheckbox = true
                            parsedGuide.clickToNext = true
                            return "-"

                        elseif tag == "OPTIONAL" then
                            parsedLine.optional = true
                            return ""

                        elseif tag == "OPTIONAL_COMPLETE_WITH_NEXT" then
                            parsedLine.complete_with_next = true
                            parsedLine.check = false
                            return ""

                        elseif tag == "APPLIES" then
                            return "|c" .. GLV.Colors[tag] .. self:replaceClassRace(tagContent) .. "|r"

                        elseif tag == "TARGET_ID" then
                            return GLV:getTargetName(tagContent)

                        elseif tag == "LEARN" then
                            parsedLine.icon = "Interface\\GossipFrame\\TrainerGossipIcon"
                            if not parsedLine.learnTags then parsedLine.learnTags = {} end
                            table.insert(parsedLine.learnTags, {
                                spellId = tonumber(tagContent)
                            })
                            return "|c" .. GLV.Colors[tag] .. self:Learn(tagContent) .. "|r"

                        elseif tag == "COLLECT_ITEM" then
                            return "|c" .. GLV.Colors[tag] .. self:CollectItem(tagContent) .. "|r"

                        elseif tag == "USE_ITEM" then
                            return "|c" .. GLV.Colors[tag] .. GLV:GetItemNameById(tagContent) .. "|r"

                        elseif self:getSuperTag(tag) == "QUEST" then
                            local fullText = ""
                            local questTitle = ""
                            local questId = nil
                            local questCoords = nil
                            questTitle, questId, questCoords = self:GetQuestInfo(tagContent)
                            parsedLine.questId = tonumber(questId)
                            parsedLine.hasCheckbox = true
                            
                            -- Add step type and questId for tracking
                            if tag == "ACCEPT" then
                                parsedLine.stepType = "ACCEPT"
                                fullText = fullText .. "Accept "
                                parsedLine.icon = "Interface\\GossipFrame\\AvailableQuestIcon"
                            elseif tag == "TURNIN" then
                                parsedLine.stepType = "TURNIN"
                                fullText = fullText .. "Turnin "
                                parsedLine.icon = "Interface\\GossipFrame\\ActiveQuestIcon"
                            elseif tag == "COMPLETE" then
                                parsedLine.stepType = "COMPLETE"
                                fullText = fullText .. "Complete "
                            end
                            
                            -- Store quest tag for multi-quest step handling
                            if not parsedLine.questTags then parsedLine.questTags = {} end
                            table.insert(parsedLine.questTags, {
                                tag = tag,
                                questId = tonumber(questId),
                                title = questTitle
                            })
                            
                            -- Add coordinates to the parsed line
                            if questCoords and table.getn(questCoords) > 0 then
                                parsedLine.coords = questCoords
                            end

                            fullText = fullText .. "|c" .. GLV.Colors[tag] .. questTitle .. "|r"
                            return fullText

                        elseif tag == "REPAIR" then
                            return "|c" .. GLV.Colors[tag] .. "Repair " .. "|r"

                        elseif tag == "VENDOR" then
                            parsedLine.icon = "Interface\\GossipFrame\\VendorGossipIcon"
                            return "|c" .. GLV.Colors[tag] .. "Vendor " .. "|r"

                        elseif tag == "HEARTHSTONE" then
                            parsedLine.icon = "Interface\\Icons\\INV_Misc_Rune_01"
                            parsedLine.useItemId = 6948
                            return tagContent

                        elseif tag == "BIND_HEARTHSTONE" then
                            parsedLine.bindHearthstone = true
                            return "|c" .. GLV.Colors[tag] .. tagContent .. "|r"
                            
                        elseif tag == "EXPERIENCE" then
                            -- Parse different XP formats
                            local xpData = self:ParseExperienceRequirement(tagContent)
                            if xpData then
                                parsedLine.hasCheckbox = true
                                parsedLine.experienceRequirement = xpData
                                
                                return "|c" .. GLV.Colors[tag] .. xpData.text .. "|r"
                            end

                        end

                        return "[" .. code .. "]"

                    end)
                    if stepText == "" and count == 0 then
                        stepText = line
                    end
                    parsedLine.text = stepText

                else
                    parsedLine = {
                        text = "",
                        emptyLine = true
                    }
                end

                if parsedLine.text ~= "" or parsedLine.emptyLine == true then
                    table.insert(parsedGuide.steps, parsedLine)
                end
            end
        end
    end

    return parsedGuide
end


--[[ GUIDE METADATA FUNCTIONS ]]--

-- Extract guide name, levels and create unique ID
function Parser:getGuideName(content)
    -- Try different patterns to extract level and name
    local lvlMin, lvlMax, guideName
    
    -- Pattern 1: "1-11 Dun Morogh" or "1-11 Dun Morogh"
    lvlMin, lvlMax, guideName = string.match(content, "(%d+)%s*%-%s*(%d+)%s*(.+)")
    
    -- Pattern 2: "1 11 Dun Morogh" (without dash)
    if not lvlMin then
        lvlMin, lvlMax, guideName = string.match(content, "(%d+)%s+(%d+)%s+(.+)")
    end
    
    -- Pattern 3: Just try to extract any numbers and text
    if not lvlMin then
        lvlMin, lvlMax, guideName = string.match(content, "(%d+)%s*[%-%s]%s*(%d+)%s*(.+)")
    end
    
    -- Create a unique guide identifier
    local guideId = "Unknown"
    if guideName and guideName ~= "" then
        guideId = string.gsub(guideName, "%s+", "_") -- Replace spaces with underscores
        if lvlMin and lvlMin ~= "" then
            guideId = guideId .. "_" .. lvlMin
        end
        if lvlMax and lvlMax ~= "" then
            guideId = guideId .. "_" .. lvlMax
        end
    else
        -- Fallback: use group name if guide name is empty
        guideId = "Unknown_Guide"
    end
    
    return lvlMin, lvlMax, guideName, guideId
end

-- Extract and format guide description
function Parser:getGuideDescription(content)
    guideDescription = string.gsub(content, "\\\\", "\n")
    return guideDescription
end


--[[ CONTENT PROCESSING FUNCTIONS ]]--

-- Get quest information including coordinates
function Parser:GetQuestInfo(content)
    local questID, _, questPart = string.match(content, "(%d+)(,?)(%d?)")
    local questName = GLV:GetQuestNameByID(questID)
    
    -- Get quest coordinates from database using DBTools
    -- Pass questPart to get coordinates for the specific part
    local coords = GLV:GetQuestAllCoords(questID, questPart)
    
    return questName, questID, coords
end

-- Get spell name for learn tags
function Parser:Learn(content)
    -- SP XXXX
    local subcode, id = string.match(content, "(SP)%s(%d+)")
    id = string.gsub(id, "%s+", "")
    
    if subcode == "SP" then
         return GLV:getSpellName(id)
    end
    return "Unknown Spell"
end

-- Get item name for collect item tags
function Parser:CollectItem(content)
    local itemID, itemCount = string.match(content, "(%d+)(,?)(%d?)")
    local itemName = GLV:GetItemNameById(itemID)
    return itemName
end


--[[ FILTERING AND REPLACEMENT FUNCTIONS ]]--

-- Filter lines based on player class and race
function Parser:filterClassRace(line)
    local playerClass = GLV.Settings:GetOption({"CharInfo", "Class"}) or ""
    local playerRace = GLV.Settings:GetOption({"CharInfo", "Race"}) or ""
    
    local classRaceTags = {}
    for tag in string.gfind(line, "%[A ([^%]]+)%]") do
        table.insert(classRaceTags, tag)
    end

    if next(classRaceTags) then
        for tagIndex, tag in pairs(classRaceTags) do
            local isMatch = false
            for entry in string.gfind(tag, "[^,]+") do
                entry = string.gsub(entry, "^%s*(.-)%s*$", "%1")
                local normalizedEntry = string.lower(entry)
                local normalizedClass = string.lower(playerClass)
                local normalizedRace = string.lower(playerRace)

                if normalizedEntry == normalizedClass or normalizedEntry == normalizedRace then
                    isMatch = true
                    break
                end
            end
            if not isMatch then
                return false
            end
        end
        return true
    end
    return true
end

-- Replace class/race tags with appropriate text
function Parser:replaceClassRace(content)
    local playerClass = string.lower(UnitClass("player"))
    local playerRace = string.lower(UnitRace("player"))

    for classRaceTag in string.gfind(content, "([^,]+)") do

        classRaceTag = string.gsub(classRaceTag, "%s+", "")

        if string.lower(classRaceTag) == playerClass or string.lower(classRaceTag) == playerRace then
            return classRaceTag
        end

    end 
end

GLV.Parser = Parser