--[[
Guidelime Vanilla

Author: Grommey

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
    O   = "ONGOING",
    OC  = "OPTIONAL_COMPLETE_WITH_NEXT",
    GA  = "GUIDE_APPLIES",
    Q   = "QUEST",
    QA  = "ACCEPT",
    QC  = "COMPLETE",
    QT  = "TURNIN",
    QS  = "SKIP",
    G   = "GOTO",
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
    P   = "GET_FLIGHT_PATH",
    F   = "FLY_TO",
    T   = "TRAIN",
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
    local numericPart, textPart = string.match(xpString, "^([%d%.%-%+]+)(.*)")
    if not numericPart then
        return nil
    end
    
    -- Helper to get display text (use provided text or generate default)
    local function getDisplayText(text, defaultText)
        if text and text ~= "" then
            return text
        end
        return defaultText
    end

    -- [XP3] -> Reach level 3
    local simpleLevel = string.match(numericPart, "^(%d+)$")
    if simpleLevel then
        return {
            targetLevel = tonumber(simpleLevel),
            targetPercent = 100,
            type = "level",
            text = getDisplayText(textPart, "Level " .. simpleLevel)
        }
    end

    -- [XP3-100] -> Need 100 XP for level 3
    local levelMinus, xpMinus = string.match(numericPart, "^(%d+)%-(%d+)$")
    if levelMinus and xpMinus then
        return {
            targetLevel = tonumber(levelMinus),
            xpMinus = tonumber(xpMinus),
            type = "level_minus",
            text = getDisplayText(textPart, "Level " .. levelMinus .. " (-" .. xpMinus .. " XP)")
        }
    end

    -- [XP3+100] -> Need level 3 + 100 XP
    local levelPlus, xpPlus = string.match(numericPart, "^(%d+)%+(%d+)$")
    if levelPlus and xpPlus then
        return {
            targetLevel = tonumber(levelPlus),
            xpPlus = tonumber(xpPlus),
            type = "level_plus",
            text = getDisplayText(textPart, "Level " .. levelPlus .. " (+" .. xpPlus .. " XP)")
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

        local defaultText = "Level " .. level
        if percent > 0 then
            defaultText = defaultText .. " (" .. string.format("%.0f", percent) .. "%)"
        end

        return {
            targetLevel = level,
            targetPercent = percent,
            type = "level_percent",
            text = getDisplayText(textPart, defaultText)
        }
    end
    
    return nil
end

-- Main guide parsing function that processes the entire guide text and extracts structured step data
function Parser:parseGuide(guide, group)
    local parsedGuide = {}
    
    parsedGuide.steps = {}
    parsedGuide.group = group

    local isFirstLine = true

    local lineIndex = 0
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
                            return ""

                        elseif tag == "ONGOING" then
                            parsedLine.ongoing = true
                            return ""

                        elseif tag == "OPTIONAL_COMPLETE_WITH_NEXT" then
                            parsedLine.complete_with_next = true
                            parsedLine.check = false
                            return ""

                        elseif tag == "GOTO" then
                            -- Parse coordinates from multiple formats:
                            -- [G 44,57 Dun Morogh] or [G 44.0, 76.1, Mulgore]
                            local x, y, zoneName

                            -- Try format: x, y, Zone (comma before zone)
                            x, y, zoneName = string.match(tagContent, "(%d+%.?%d*)%s*,%s*(%d+%.?%d*)%s*,%s*(.+)")

                            -- Fallback: x,y Zone (space before zone)
                            if not x then
                                x, y, zoneName = string.match(tagContent, "(%d+%.?%d*)%s*,%s*(%d+%.?%d*)%s+(.+)")
                            end

                            if x and y and zoneName then
                                -- Trim whitespace from zone name
                                zoneName = string.gsub(zoneName, "^%s*(.-)%s*$", "%1")
                                local zoneId = GLV:GetZoneIDByName(zoneName)
                                if zoneId then
                                    if not parsedLine.coords then parsedLine.coords = {} end
                                    table.insert(parsedLine.coords, {
                                        x = tonumber(x),
                                        y = tonumber(y),
                                        z = zoneId,
                                        type = "goto"
                                    })
                                end
                            end
                            return ""

                        elseif tag == "APPLIES" then
                            -- Store class/race info to prepend at start of line
                            parsedLine.appliesTo = tagContent
                            return ""

                        elseif tag == "TARGET_ID" then
                            -- Store target ID for navigation
                            if not parsedLine.targetIds then parsedLine.targetIds = {} end
                            table.insert(parsedLine.targetIds, tonumber(tagContent))
                            return GLV:getTargetName(tagContent)

                        elseif tag == "SPELL" then
                            -- Display spell name (standalone [SP id] tag)
                            local spellName = GLV:getSpellName(tagContent)
                            return "|c" .. GLV.Colors["LEARN"] .. spellName .. "|r"

                        elseif tag == "LEARN" then
                            parsedLine.icon = "Interface\\GossipFrame\\TrainerGossipIcon"
                            parsedLine.hasCheckbox = true
                            parsedLine.stepType = "LEARN"
                            if not parsedLine.learnSpells then parsedLine.learnSpells = {} end

                            local spellId, spellName = self:Learn(tagContent)
                            table.insert(parsedLine.learnSpells, {
                                spellId = spellId,
                                spellName = spellName
                            })

                            return "|c" .. GLV.Colors[tag] .. spellName .. "|r"

                        elseif tag == "COLLECT_ITEM" then
                            local itemId, itemCount, itemName = self:CollectItem(tagContent)
                            if itemId then
                                if not parsedLine.collectItems then parsedLine.collectItems = {} end
                                table.insert(parsedLine.collectItems, {
                                    itemId = itemId,
                                    count = itemCount or 1,
                                    name = itemName
                                })
                                parsedLine.hasCheckbox = true
                            end
                            return "|c" .. GLV.Colors[tag] .. (itemName or "Unknown Item") .. "|r"

                        elseif tag == "USE_ITEM" then
                            local itemName = GLV:GetItemNameById(tagContent)
                            local itemTexture = self:GetItemTexture(tagContent)
                            parsedLine.icon = itemTexture
                            parsedLine.useItemId = tagContent 
                            return "|c" .. GLV.Colors[tag] .. itemName .. "|r"

                        elseif self:getSuperTag(tag) == "QUEST" then
                            local fullText = ""
                            local questTitle = ""
                            local questId = nil
                            local questCoords = nil
                            local objectiveIndex = nil
                            questTitle, questId, questCoords, objectiveIndex = self:GetQuestInfo(tagContent)

                            -- [Q] tag is just a quest reference, not an action
                            if tag == "QUEST" then
                                return "|c" .. GLV.Colors[tag] .. questTitle .. "|r"
                            end

                            parsedLine.questId = tonumber(questId)
                            parsedLine.hasCheckbox = true

                            -- Use colored text symbols for quest actions
                            if tag == "ACCEPT" then
                                parsedLine.stepType = "ACCEPT"
                                fullText = "\n|cFFFFFC01!|r Accept "
                            elseif tag == "TURNIN" then
                                parsedLine.stepType = "TURNIN"
                                fullText = "\n|cFFFFFC01?|r Turnin "
                            elseif tag == "COMPLETE" then
                                parsedLine.stepType = "COMPLETE"
                                fullText = "Complete "
                            end

                            if not parsedLine.questTags then parsedLine.questTags = {} end
                            table.insert(parsedLine.questTags, {
                                tag = tag,
                                questId = tonumber(questId),
                                title = questTitle,
                                objectiveIndex = objectiveIndex  -- nil for whole quest, 1/2/3 for specific objective
                            })
                            
                            if questCoords and table.getn(questCoords) > 0 then
                                -- Append quest coords instead of replacing (preserve explicit [G] coords)
                                if not parsedLine.coords then parsedLine.coords = {} end
                                for _, coord in ipairs(questCoords) do
                                    table.insert(parsedLine.coords, coord)
                                end
                            end

                            fullText = fullText .. "|c" .. GLV.Colors[tag] .. questTitle .. "|r"
                            return fullText

                        elseif tag == "REPAIR" then
                            return "|c" .. GLV.Colors[tag] .. "Repair " .. "|r"

                        elseif tag == "VENDOR" then
                            --parsedLine.icon = "Interface\\GossipFrame\\VendorGossipIcon"
                            return "|c" .. GLV.Colors[tag] .. "Vendor " .. "|r"

                        elseif tag == "TRAIN" then
                            parsedLine.icon = "Interface\\GossipFrame\\TrainerGossipIcon"
                            return ""

                        elseif tag == "HEARTHSTONE" then
                            parsedLine.icon = "Interface\\Icons\\INV_Misc_Rune_01"
                            parsedLine.useItemId = 6948
                            parsedLine.stepType = "HEARTHSTONE"
                            parsedLine.hearthDestination = tagContent
                            parsedLine.hasCheckbox = true
                            return tagContent

                        elseif tag == "BIND_HEARTHSTONE" then
                            parsedLine.bindHearthstone = true
                            parsedLine.bindLocation = tagContent
                            parsedLine.hasCheckbox = true
                            parsedLine.stepType = "BIND_HEARTHSTONE"
                            return "|c" .. GLV.Colors[tag] .. tagContent .. "|r"
                            
                        elseif tag == "EXPERIENCE" then
                            local xpData = self:ParseExperienceRequirement(tagContent)
                            if xpData then
                                parsedLine.hasCheckbox = true
                                parsedLine.experienceRequirement = xpData
                                
                                return "|c" .. GLV.Colors[tag] .. xpData.text .. "|r"
                            end

                        elseif tag == "GET_FLIGHT_PATH" then
                            local flightPathName = self:GetFlightPathInfo(tagContent)
                            parsedLine.stepType = "GET_FP"
                            parsedLine.hasCheckbox = true
                            parsedLine.icon = "Interface\\Icons\\Ability_Mount_GriffonMount"
                            parsedLine.destination = flightPathName

                            local fullText = "|c" .. GLV.Colors[tag] .. flightPathName .. "|r"
                            return fullText

                        elseif tag == "FLY_TO" then
                            local flightPathName = self:GetFlightPathInfo(tagContent)
                            parsedLine.stepType = "FLY_TO"
                            parsedLine.hasCheckbox = true
                            parsedLine.icon = "Interface\\Icons\\Ability_Mount_GriffonMount"
                            parsedLine.destination = flightPathName

                            local fullText = "Fly to |c" .. GLV.Colors[tag] .. flightPathName .. "|r"
                            return fullText

                        end

                        return "[" .. code .. "]"

                    end)
                    if stepText == "" and count == 0 then
                        stepText = line
                    end

                    -- Prepend class/race info at the start of the line if present
                    if parsedLine.appliesTo then
                        -- Remove leading newlines from stepText before prepending class
                        stepText = string.gsub(stepText, "^%s*\n", "")
                        local classText = "|c" .. GLV.Colors["APPLIES"] .. self:replaceClassRace(parsedLine.appliesTo) .. " :|r "
                        stepText = classText .. stepText
                    end

                    parsedLine.text = stepText

                    -- Check if this is an equip step (original line contains "Equip" and has useItemId)
                    if parsedLine.useItemId and string.find(string.lower(line), "equip") then
                        parsedLine.equipItemId = tonumber(parsedLine.useItemId)
                        parsedLine.stepType = "EQUIP"
                        parsedLine.hasCheckbox = true
                    end

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
        lineIndex = lineIndex + 1
    end

    return parsedGuide
end


--[[ GUIDE METADATA FUNCTIONS ]]--

-- Extract guide name, levels and create unique ID from the NAME tag content
function Parser:getGuideName(content)
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

    -- Pattern 4: No level numbers, just a name (e.g., "START WITH THIS as Tauren")
    if not guideName then
        guideName = content
        lvlMin = nil
        lvlMax = nil
    end

    -- Create a unique guide identifier
    local guideId = "Unknown"
    if guideName and guideName ~= "" then
        guideId = string.gsub(guideName, "%s+", "_")
        if lvlMin and lvlMin ~= "" then
            guideId = guideId .. "_" .. lvlMin
        end
        if lvlMax and lvlMax ~= "" then
            guideId = guideId .. "_" .. lvlMax
        end
    else
        guideId = "Unknown_Guide"
    end

    return lvlMin, lvlMax, guideName, guideId
end

-- Extract and format guide description from the DESCRIPTION tag content
function Parser:getGuideDescription(content)
    local guideDescription = string.gsub(content, "\\\\", "\n")
    return guideDescription
end


--[[ CONTENT PROCESSING FUNCTIONS ]]--

-- Get quest information including coordinates from quest ID and part number
function Parser:GetQuestInfo(content)
    local questID, _, questPart = string.match(content, "(%d+)(,?)(%d?)")
    local questName = GLV:GetQuestNameByID(questID)

    local coords = GLV:GetQuestAllCoords(questID, questPart)

    -- Convert questPart to number (nil if empty string)
    local objectiveIndex = nil
    if questPart and questPart ~= "" then
        objectiveIndex = tonumber(questPart)
    end

    return questName, questID, coords, objectiveIndex
end

-- Get spell name and ID for learn tags from the LEARN tag content
function Parser:Learn(content)
    local subcode, id = string.match(content, "(SP)%s(%d+)")
    if subcode == "SP" and id then
        id = string.gsub(id, "%s+", "")
        local numericId = tonumber(id)
        local spellName = GLV:getSpellName(id)
        
        return numericId, spellName
    end
    return nil, "Unknown Spell"
end

-- Get item info for collect item tags from the COLLECT_ITEM tag content
-- Format: [CI itemId] or [CI itemId,count]
function Parser:CollectItem(content)
    local itemID, separator, itemCount = string.match(content, "(%d+)(,?)(%d*)")
    if not itemID then return nil, nil, nil end

    local numericId = tonumber(itemID)
    local numericCount = tonumber(itemCount) or 1
    local itemName = GLV:GetItemNameById(itemID)

    return numericId, numericCount, itemName
end

function Parser:GetItemTexture(content)
    local itemID = tonumber(content)
    if not itemID then
        return ""
    end

    local _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    if not itemTexture then
        -- Force cache the item by querying tooltip (async, will be available on next load)
        if not GLV.itemCacheTooltip then
            GLV.itemCacheTooltip = CreateFrame("GameTooltip", "GLV_ItemCacheTooltip", nil, "GameTooltipTemplate")
            GLV.itemCacheTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        end
        GLV.itemCacheTooltip:SetHyperlink("item:" .. itemID)

        -- Fallback icon for items not yet cached
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    return itemTexture
end

function Parser:GetFlightPathInfo(content)
    local flightPathName = string.gsub(content, "^%s*(.-)%s*$", "%1")
    if flightPathName == "" then
        flightPathName = "Unknown Flight Path"
    end
    
    return flightPathName
end

--[[ FILTERING AND REPLACEMENT FUNCTIONS ]]--

-- Known WoW classes (lowercase) for separating races from classes in [A] tags
local KNOWN_CLASSES = {
    warrior = true, paladin = true, hunter = true, rogue = true,
    priest = true, shaman = true, mage = true, warlock = true, druid = true,
}

-- Filter lines based on player class and race to show only applicable content
-- Within a single [A] tag, races and classes are AND'd:
--   [A Dwarf, Human, Priest] = (Dwarf OR Human) AND Priest
-- Multiple [A] tags are AND'd with each other:
--   [A Dwarf, Human] [A Priest] = (Dwarf OR Human) AND Priest
function Parser:filterClassRace(line)
    local playerClass = GLV.Settings:GetOption({"CharInfo", "Class"}) or ""
    local playerRace = GLV.Settings:GetOption({"CharInfo", "Race"}) or ""
    local normalizedClass = string.lower(playerClass)
    local normalizedRace = string.lower(playerRace)

    local classRaceTags = {}
    for tag in string.gfind(line, "%[A ([^%]]+)%]") do
        table.insert(classRaceTags, tag)
    end

    if next(classRaceTags) then
        for _, tag in pairs(classRaceTags) do
            -- Separate entries into races and classes
            local races = {}
            local classes = {}
            for entry in string.gfind(tag, "[^,]+") do
                entry = string.gsub(entry, "^%s*(.-)%s*$", "%1")
                if entry ~= "" then
                    if KNOWN_CLASSES[string.lower(entry)] then
                        table.insert(classes, string.lower(entry))
                    else
                        table.insert(races, string.lower(entry))
                    end
                end
            end

            -- If races listed, player race must match one
            if table.getn(races) > 0 then
                local raceMatch = false
                for _, r in ipairs(races) do
                    if r == normalizedRace then
                        raceMatch = true
                        break
                    end
                end
                if not raceMatch then return false end
            end

            -- If classes listed, player class must match one
            if table.getn(classes) > 0 then
                local classMatch = false
                for _, c in ipairs(classes) do
                    if c == normalizedClass then
                        classMatch = true
                        break
                    end
                end
                if not classMatch then return false end
            end
        end
        return true
    end
    return true
end

-- Replace class/race tags with appropriate text based on current player
function Parser:replaceClassRace(content)
    local playerClass = string.lower(UnitClass("player"))
    local playerRace = string.lower(UnitRace("player"))

    for classRaceTag in string.gfind(content, "([^,]+)") do

        classRaceTag = string.gsub(classRaceTag, "%s+", "")

        if string.lower(classRaceTag) == playerClass or string.lower(classRaceTag) == playerRace then
            return classRaceTag
        end

    end
    -- Return the original content if no match found (prevents nil concatenation)
    return content or ""
end

GLV.Parser = Parser