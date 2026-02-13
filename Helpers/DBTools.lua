--[[
Guidelime Vanilla

Author: Grommey

Description:
DB Query functions
]]--
local GLV = LibStub("GuidelimeVanilla")


--[[ LOCAL FUNCTIONS ]]--

-- Get entity data from VGDB (units, items, objects)
-- Returns entity data table or nil
local function getEntityData(entityType, entityId)
    if not VGDB or not VGDB[entityType] or not VGDB[entityType]["data"] then
        return nil
    end
    return VGDB[entityType]["data"][tonumber(entityId)]
end

-- Find first valid coordinate set from entity coords array
-- Returns {x, y, z} or nil
local function getFirstValidCoords(entityData)
    if not entityData or not entityData.coords then return nil end
    for _, coordSet in ipairs(entityData.coords) do
        if coordSet and coordSet[1] and coordSet[2] and coordSet[3] then
            return coordSet
        end
    end
    return nil
end

-- Collect coordinates from a list of entity IDs
-- entityType: "units" or "objects"
-- entityIds: array of IDs
-- coordType: "start", "end", or "objective"
-- Returns array of coord entries
local function collectEntityCoords(entityType, entityIds, coordType)
    local coords = {}
    local idField = (entityType == "units") and "npcId" or "objectId"
    for _, entityId in ipairs(entityIds) do
        local entityData = getEntityData(entityType, entityId)
        local validCoords = getFirstValidCoords(entityData)
        if validCoords then
            local entry = {
                type = coordType,
                x = validCoords[1],
                y = validCoords[2],
                z = validCoords[3]
            }
            entry[idField] = entityId
            table.insert(coords, entry)
        elseif GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[DBTools]|r No coords for " .. entityType .. " #" .. tostring(entityId))
        end
    end
    return coords
end

-- Find closest unit/NPC by ID in a specific zone
local function findClosestUnit(unitID, questZone)
    if not unitID then
        return nil, nil
    end

    -- Use zone-aware GetNPCCoordinates (filters by player zone, returns closest spawn)
    local npcCoords = GLV:GetNPCCoordinates(unitID)
    if not npcCoords or not npcCoords.x or not npcCoords.y or not npcCoords.z then
        return nil, nil
    end

    -- Calculate distance for sorting among multiple candidates
    local nearest = nil
    local currentPlayerPos = nil
    if GLV.GuideNavigation and GLV.GuideNavigation.GetPlayerPosition then
        currentPlayerPos = GLV.GuideNavigation:GetPlayerPosition()
    end

    if currentPlayerPos then
        local dx = (currentPlayerPos.x * 100) - npcCoords.x
        local dy = (currentPlayerPos.y * 100) - npcCoords.y
        nearest = math.sqrt(dx * dx + dy * dy)
    end

    return {
        type = "objective",
        npcId = unitID,
        x = npcCoords.x,
        y = npcCoords.y,
        z = npcCoords.z,
        distance = nearest or 0
    }, nearest
end

-- Resolve coordinates for an item objective with fallback chain:
-- 1) Direct item coordinates, 2) Units that drop, 3) Objects that contain, 4) Quest start NPC
-- Returns coord entry or nil
local function resolveItemObjectiveCoords(quest, targetItemID)
    local itemData = getEntityData("items", targetItemID)

    -- 1) Direct item coordinates
    if itemData then
        local validCoords = getFirstValidCoords(itemData)
        if validCoords then
            return {
                type = "objective", itemId = targetItemID,
                x = validCoords[1], y = validCoords[2], z = validCoords[3]
            }
        end
    end

    if not itemData then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[DBTools]|r No item data for item #" .. tostring(targetItemID))
        end
        return nil
    end

    -- Determine quest zone from start NPC/Object for proximity filtering
    local questZone = nil
    if quest.start and quest.start.U and quest.start.U[1] then
        local startNPC = getEntityData("units", quest.start.U[1])
        local startCoords = getFirstValidCoords(startNPC)
        if startCoords then questZone = startCoords[3] end
    end
    if not questZone and quest.start and quest.start.O and quest.start.O[1] then
        local startObj = getEntityData("objects", quest.start.O[1])
        local startCoords = getFirstValidCoords(startObj)
        if startCoords then questZone = startCoords[3] end
    end

    -- 2) Units that drop this item
    if itemData.U then
        local bestUnits = {}
        for unitID, dropChance in pairs(itemData.U) do
            local closestUnit, nearest = findClosestUnit(unitID, questZone)
            if closestUnit and nearest then
                table.insert(bestUnits, {unit = closestUnit, nearest = nearest})
            end
        end
        table.sort(bestUnits, function(a, b) return a.nearest < b.nearest end)
        if bestUnits[1] then
            return bestUnits[1].unit
        end
    end

    -- 3) Objects that contain this item
    if itemData.O then
        for objID, dropChance in pairs(itemData.O) do
            local objData = getEntityData("objects", objID)
            local validCoords = getFirstValidCoords(objData)
            if validCoords then
                return {
                    type = "objective", itemId = targetItemID, objectId = objID,
                    x = validCoords[1], y = validCoords[2], z = validCoords[3],
                    note = "Object that loots this item"
                }
            end
        end
    end

    -- 4) Fallback: quest start NPC location
    if quest.start and quest.start.U and quest.start.U[1] then
        local startNPC = getEntityData("units", quest.start.U[1])
        local startCoords = getFirstValidCoords(startNPC)
        if startCoords then
            return {
                type = "objective", itemId = targetItemID,
                x = startCoords[1], y = startCoords[2], z = startCoords[3],
                note = "Fallback: Using quest start location for item objective"
            }
        end
    end

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[DBTools]|r No coords found for item #" .. tostring(targetItemID) .. " (all fallbacks exhausted)")
    end
    return nil
end

-- Get current locale for database queries
local function getLocalizedKey()
    local loc = nil
    if GLV and GLV.Settings and GLV.Settings.GetOption then
        loc = GLV.Settings:GetOption("Locale")
    end
    if not loc and GetLocale then
        loc = GetLocale()
    end
    if not loc or loc == "" then loc = "enUS" end
    return loc
end


--[[ UNIT RELATED FUNCTIONS ]]--

-- Get NPC name by unit ID
function GLV:getTargetName(id)
    local npcName = "UNKNOWN_NAME"
    local Localized = getLocalizedKey()
    if not VGDB or not VGDB["units"] or not VGDB["units"][Localized] then
        return npcName
    end

    npcName = VGDB["units"][Localized][tonumber(id)]
    return npcName or "UNKNOWN_NAME"
end

-- Get NPC coordinates by unit ID
-- Prefers coordinates in the player's current zone when NPC has multiple spawn locations
function GLV:GetNPCCoordinates(npcID)
    if not npcID then return nil end

    local npcData = VGDB and VGDB["units"] and VGDB["units"]["data"] and VGDB["units"]["data"][tonumber(npcID)]
    if not npcData or not npcData.coords then return nil end

    -- Collect all coordinates in the player's current zone
    local playerZoneName = GetZoneText()
    local zoneMatches = {}
    local firstValid = nil

    for _, coordSet in ipairs(npcData.coords) do
        if coordSet[1] and coordSet[2] and coordSet[3] then
            if not firstValid then
                firstValid = {x = coordSet[1], y = coordSet[2], z = coordSet[3]}
            end
            if playerZoneName then
                local zoneName = self:GetZoneNameByID(coordSet[3])
                if zoneName and string.lower(zoneName) == string.lower(playerZoneName) then
                    table.insert(zoneMatches, {x = coordSet[1], y = coordSet[2], z = coordSet[3]})
                end
            end
        end
    end

    -- If only one match (or none) in zone, return it directly
    if table.getn(zoneMatches) <= 1 then
        return zoneMatches[1] or firstValid
    end

    -- Multiple spawns in same zone: return closest to player
    local C, Z, pX, pY = Astrolabe:GetCurrentPlayerPosition()
    if not pX or not pY then
        return zoneMatches[1]
    end

    local closest = nil
    local closestDist = nil
    for _, coords in ipairs(zoneMatches) do
        local dx = coords.x / 100 - pX
        local dy = coords.y / 100 - pY
        local dist = dx * dx + dy * dy
        if not closestDist or dist < closestDist then
            closestDist = dist
            closest = coords
        end
    end

    return closest
end


--[[ SPELL RELATED FUNCTIONS ]]--

-- Get spell name by spell ID (uses Nampower API)
function GLV:getSpellName(id)
    local numId = tonumber(id)
    if not numId then return "UNKNOWN_SPELL" end

    -- Get raw spell name from available APIs
    local rawName, rawRank
    if GetSpellNameAndRankForId then
        rawName, rawRank = GetSpellNameAndRankForId(numId)
    end
    if not rawName and GetSpellRec then
        local spellRec = GetSpellRec(numId)
        if spellRec and spellRec.name then
            rawName = spellRec.name
        end
    end
    if not rawName then return "UNKNOWN_SPELL" end

    -- If API properly split name/rank (e.g., "Cooking" + "Apprentice"), use name directly
    if rawRank and rawRank ~= "" then
        return rawName
    end

    -- Otherwise try to strip tier prefix from the raw name
    -- e.g., "Apprentice Cook" → strip "Apprentice " → "Cook" → match "Cooking" in skill lines
    local tierPrefixes = {"Apprentice ", "Journeyman ", "Expert ", "Artisan ", "Master "}
    for _, prefix in ipairs(tierPrefixes) do
        local prefixLen = string.len(prefix)
        if string.len(rawName) > prefixLen and
           string.sub(rawName, 1, prefixLen) == prefix then
            local strippedName = string.sub(rawName, prefixLen + 1)
            -- Try to find the actual skill name via partial match in skill lines
            for i = 1, GetNumSkillLines() do
                local skillName = GetSkillLineInfo(i)
                if skillName and string.find(skillName, strippedName, 1, true) then
                    return skillName  -- e.g., "Cooking" instead of "Cook"
                end
            end
            return strippedName  -- Best guess if skill not in visible lines yet
        end
    end

    return rawName
end

-- Get full spell info by spell ID (uses Nampower API)
function GLV:getSpellInfo(id)
    local numId = tonumber(id)
    if not numId or not GetSpellRec then return nil end

    local spellRec = GetSpellRec(numId)
    if not spellRec then return nil end

    return {
        name = spellRec.name,
        rank = spellRec.rank,
        icon = spellRec.spellIconID,
        manaCost = spellRec.manaCost,
        school = spellRec.school,
        level = spellRec.spellLevel
    }
end


--[[ QUEST RELATED FUNCTIONS ]]--

-- Cache for quest name to ID lookups (performance optimization)
local questNameCache = {}

-- Get quest ID by quest name (with caching)
function GLV:GetQuestIDByName(name)
    if not name then return nil end

    -- Check cache first
    if questNameCache[name] then
        return questNameCache[name]
    end

    local Localized = getLocalizedKey()
    if not VGDB or not VGDB.quests or not VGDB.quests[Localized] then
        return nil
    end

    -- Collect all matching IDs, return the smallest.
    -- Same-name quest chains (e.g., "The Tome of Divinity") have multiple
    -- quests with the same name — the lowest ID is the first in the chain.
    local smallestId = nil
    for id, data in pairs(VGDB.quests[Localized]) do
        if data and data.T and data.T == name then
            local numId = tonumber(id)
            if numId and (not smallestId or numId < smallestId) then
                smallestId = numId
            end
        end
    end

    if smallestId then
        questNameCache[name] = smallestId
        return smallestId
    end

    return nil
end

-- Clear quest name cache (call when locale changes)
function GLV:ClearQuestNameCache()
    questNameCache = {}
end

-- Get quest name by quest ID
function GLV:GetQuestNameByID(id)
    local Localized = getLocalizedKey()
    if not VGDB or not VGDB.quests or not VGDB.quests[Localized] then
        return "UNKNOWN_QUEST"
    end

    local numId = tonumber(id)
    if not numId then
        return "UNKNOWN_QUEST"
    end
    
    local questData = VGDB.quests[Localized][numId]
    if not questData or not questData.T then
        return "UNKNOWN_QUEST"
    end

    return questData.T
end

-- Get quest level by quest ID
function GLV:GetQuestLevelByID(id)
    if not VGDB or not VGDB.quests or not VGDB.quests["data"] then
        return nil
    end

    local numId = tonumber(id)
    if not numId then
        return nil
    end

    local questData = VGDB.quests["data"][numId]
    if not questData then
        return nil
    end

    local questLevel = questData.lvl
    if not questLevel then
        return nil
    end

    return questLevel
end

-- Get quest turn-in NPC name from database
function GLV:GetQuestTurninNPCName(questId)
    if not questId then return nil end

    local locale = self.Settings:GetOption({"Locale"}) or "enUS"
    local quest = VGDB and VGDB["quests"] and VGDB["quests"]["data"] and VGDB["quests"]["data"][tonumber(questId)]

    if quest and quest["end"] and quest["end"].U then
        local npcId = quest["end"].U[1]  -- Get first turn-in NPC
        if npcId then
            return self:getTargetName(npcId)
        end
    end

    return nil
end

-- Get quest accept NPC name from database
function GLV:GetQuestAcceptNPCName(questId)
    if not questId then return nil end

    local locale = self.Settings:GetOption({"Locale"}) or "enUS"
    local quest = VGDB and VGDB["quests"] and VGDB["quests"]["data"] and VGDB["quests"]["data"][tonumber(questId)]

    if quest and quest["start"] and quest["start"].U then
        local npcId = quest["start"].U[1]  -- Get first quest giver NPC
        if npcId then
            return self:getTargetName(npcId)
        end
    end

    return nil
end

-- Get all coordinates for a quest (start, end, objectives)
function GLV:GetQuestAllCoords(id, questPart, onlyObjective)
    if not id then return nil end

    local quest = VGDB and VGDB["quests"] and VGDB["quests"]["data"] and VGDB["quests"]["data"][tonumber(id)]
    if not quest then return nil end

    questPart = tonumber(questPart) or 1
    local allCoords = {}

    -- Start/End NPC and Object coordinates (skip if onlyObjective)
    if not onlyObjective then
        if quest.start then
            if quest.start.U then
                for _, v in ipairs(collectEntityCoords("units", quest.start.U, "start")) do table.insert(allCoords, v) end
            end
            if quest.start.O then
                for _, v in ipairs(collectEntityCoords("objects", quest.start.O, "start")) do table.insert(allCoords, v) end
            end
        end
        if quest["end"] then
            if quest["end"].U then
                for _, v in ipairs(collectEntityCoords("units", quest["end"].U, "end")) do table.insert(allCoords, v) end
            end
            if quest["end"].O then
                for _, v in ipairs(collectEntityCoords("objects", quest["end"].O, "end")) do table.insert(allCoords, v) end
            end
        end
    end

    -- Quest objectives (filtered by questPart/objectiveIndex when provided)
    if quest.obj then
        -- Unit objectives
        if quest.obj.U then
            if questPart and questPart > 0 then
                -- Specific objective: only check the unit at this index
                local npcID = quest.obj.U[questPart]
                if npcID then
                    local bestUnit = findClosestUnit(npcID, nil)
                    if bestUnit then table.insert(allCoords, bestUnit) end
                end
            else
                -- No specific objective: return all unit objectives
                for _, npcID in ipairs(quest.obj.U) do
                    local bestUnit = findClosestUnit(npcID, nil)
                    if bestUnit then table.insert(allCoords, bestUnit) end
                end
            end
        end
        -- Item objectives (with fallback chain)
        if quest.obj.I then
            local targetItemID = quest.obj.I[questPart]
            if targetItemID then
                local itemCoord = resolveItemObjectiveCoords(quest, targetItemID)
                if itemCoord then table.insert(allCoords, itemCoord) end
            end
        end
        -- Object objectives
        if quest.obj.O then
            if questPart and questPart > 0 then
                -- Specific objective: only check the object at this index
                local objID = quest.obj.O[questPart]
                if objID then
                    for _, v in ipairs(collectEntityCoords("objects", {objID}, "objective")) do table.insert(allCoords, v) end
                end
            else
                for _, v in ipairs(collectEntityCoords("objects", quest.obj.O, "objective")) do table.insert(allCoords, v) end
            end
        end
    end

    return allCoords
end


--[[ ZONE RELATED FUNCTIONS ]]--

-- Get current zone name
function GLV:GetCurrentZoneName()
    local zoneName = GetZoneText();
    return zoneName
end

function GLV:GetCurrentZoneID()
    local zoneName = GetZoneText();
    return self:GetZoneIDByName(zoneName)
end

-- Get zone name by zone ID
function GLV:GetZoneNameByID(zoneID)
    if not zoneID then return nil end
    
    local Localized = getLocalizedKey()
    if not VGDB or not VGDB["zones"] or not VGDB["zones"][Localized] then 
        return nil
    end
    
    return VGDB["zones"][Localized][tonumber(zoneID)]
end

-- Get zone ID by name
function GLV:GetZoneIDByName(zoneName)
    if not zoneName then return nil end
    
    local Localized = getLocalizedKey()
    if not VGDB or not VGDB["zones"] or not VGDB["zones"][Localized] then 
        return nil
    end

    for id, name in pairs(VGDB["zones"][Localized]) do
        if name == zoneName then
            return id
        end
    end
    
    return nil
end

--[[ ITEM RELATED FUNCTIONS ]]--

-- Get item name by item ID
function GLV:GetItemNameById(itemID)
    if not itemID then return "UNKNOWN_ITEM" end
    
    local Localized = getLocalizedKey()
    if not VGDB or not VGDB["items"] or not VGDB["items"][Localized] then 
        return "UNKNOWN_ITEM"
    end
    
    local itemName = VGDB["items"][Localized][tonumber(itemID)]
    return itemName or "UNKNOWN_ITEM"
end

-- Get item coordinates by item ID
function GLV:GetItemCoordinates(itemID)
    if not itemID then return nil end
    
    local itemData = VGDB and VGDB["items"] and VGDB["items"]["data"] and VGDB["items"]["data"][tonumber(itemID)]
    if not itemData or not itemData.coords then return nil end
    
    for _, coordSet in ipairs(itemData.coords) do
        if coordSet[1] and coordSet[2] and coordSet[3] then
            return {
                x = coordSet[1],
                y = coordSet[2],
                z = coordSet[3]
            }
        end
    end
    
    return nil
end