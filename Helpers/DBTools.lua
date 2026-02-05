--[[
Guidelime Vanilla

Author: Grommey

Description:
DB Query functions
]]--
local GLV = LibStub("GuidelimeVanilla")


--[[ LOCAL FUNCTIONS ]]--

-- Find closest unit/NPC by ID in a specific zone
local function findClosestUnit(unitID, questZone)
    if not unitID then
        return nil, nil
    end
    
    local nearest = nil
    local bestUnit = nil

    -- Ensure we have player position
    local currentPlayerPos = nil
    if GLV.GuideNavigation and GLV.GuideNavigation.GetPlayerPosition then
        currentPlayerPos = GLV.GuideNavigation:GetPlayerPosition()
    end
    
    if not currentPlayerPos then
        return nil, nil
    end

    local playerX, playerY = currentPlayerPos.x, currentPlayerPos.y
    
    if VGDB and VGDB["units"] and VGDB["units"]["data"] and VGDB["units"]["data"][unitID] and VGDB["units"]["data"][unitID]["coords"] then
        for _, coordSet in ipairs(VGDB["units"]["data"][unitID]["coords"]) do
            if coordSet and coordSet[1] and coordSet[2] and coordSet[3] then
                if not questZone or (coordSet[3] and questZone and coordSet[3] == questZone) then
                    if playerX and playerY then
                        local x, y = (playerX * 100) - coordSet[1], (playerY * 100) - coordSet[2]
                        local distance = math.sqrt(x * x + y * y)

                        if not nearest or distance < nearest then
                            nearest = distance
                            bestUnit = {
                                type = "objective",
                                npcId = unitID,
                                x = coordSet[1],
                                y = coordSet[2],
                                z = coordSet[3],
                                distance = distance
                            }
                        end
                    end
                end
            end
        end
    end
    
    return bestUnit, nearest
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
function GLV:GetNPCCoordinates(npcID)
    if not npcID then return nil end
    
    local npcData = VGDB and VGDB["units"] and VGDB["units"]["data"] and VGDB["units"]["data"][tonumber(npcID)]
    if not npcData or not npcData.coords then return nil end
    
    for _, coordSet in ipairs(npcData.coords) do
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


--[[ SPELL RELATED FUNCTIONS ]]--

-- Get spell name by spell ID (uses Nampower API)
function GLV:getSpellName(id)
    local numId = tonumber(id)
    if not numId then return "UNKNOWN_SPELL" end

    -- Use Nampower GetSpellRec API
    if GetSpellRec then
        local spellRec = GetSpellRec(numId)
        if spellRec and spellRec.name then
            return spellRec.name
        end
    end

    return "UNKNOWN_SPELL"
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

    for id, data in pairs(VGDB.quests[Localized]) do
        if data and data.T and data.T == name then
            questNameCache[name] = id
            return id
        end
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
    if not id then 
        return nil 
    end
    
    if not VGDB or not VGDB["quests"] or not VGDB["quests"]["data"] then 
        return nil 
    end
    
    local quest = VGDB["quests"]["data"][tonumber(id)]
    if not quest then
        return nil
    end
    
    questPart = tonumber(questPart) or 1
    
    local allCoords = {}
    
    if not onlyObjectives then
        if quest.start then
            if quest.start.U then
                for _, npcID in ipairs(quest.start.U) do
                    local npcData = VGDB["units"]["data"][npcID]
                    if npcData and npcData.coords then
                        local validCoords = nil
                        for _, coordSet in ipairs(npcData.coords) do
                            if coordSet and coordSet[1] and coordSet[2] and coordSet[3] then
                                validCoords = coordSet
                                break
                            end
                        end
                        
                        if validCoords then
                            table.insert(allCoords, {
                                type = "start",
                                npcId = npcID,
                                x = validCoords[1],
                                y = validCoords[2],
                                z = validCoords[3]
                            })
                        end
                    end
                end
            end
            
            if quest.start.O then
                for _, objID in ipairs(quest.start.O) do
                    local objData = VGDB["objects"]["data"][objID]
                    if objData and objData.coords then
                        local validCoords = nil
                        for _, coordSet in ipairs(objData.coords) do
                            if coordSet and coordSet[1] and coordSet[2] and coordSet[3] then
                                validCoords = coordSet
                                break
                            end
                        end
                        
                        if validCoords then
                            table.insert(allCoords, {
                                type = "start",
                                objectId = objID,
                                x = validCoords[1],
                                y = validCoords[2],
                                z = validCoords[3]
                            })
                        end
                    end
                end
            end
        end
        
        if quest["end"] then
            if quest["end"].U then
                for _, npcID in ipairs(quest["end"].U) do
                    local npcData = VGDB["units"]["data"][npcID]
                    if npcData and npcData.coords then
                        local validCoords = nil
                        for _, coordSet in ipairs(npcData.coords) do
                            if coordSet and coordSet[1] and coordSet[2] and coordSet[3] then
                                validCoords = coordSet
                                break
                            end
                        end

                        if validCoords then
                            table.insert(allCoords, {
                                type = "end",
                                npcId = npcID,
                                x = validCoords[1],
                                y = validCoords[2],
                                z = validCoords[3]
                            })
                        end
                    end
                end
            end
            -- Handle quest end on Objects (e.g., A Dwarven Corpse)
            if quest["end"].O then
                for _, objectID in ipairs(quest["end"].O) do
                    local objectData = VGDB["objects"]["data"][objectID]
                    if objectData and objectData.coords then
                        local validCoords = nil
                        for _, coordSet in ipairs(objectData.coords) do
                            if coordSet and coordSet[1] and coordSet[2] and coordSet[3] then
                                validCoords = coordSet
                                break
                            end
                        end

                        if validCoords then
                            table.insert(allCoords, {
                                type = "end",
                                objectId = objectID,
                                x = validCoords[1],
                                y = validCoords[2],
                                z = validCoords[3]
                            })
                        end
                    end
                end
            end
        end
    end
    
    if quest.obj then
        -- UNITS OBJECTIVES
        if quest.obj.U then
            for _, npcID in ipairs(quest.obj.U) do
                local bestUnit, nearest = findClosestUnit(npcID, questZone)
                if bestUnit then
                    table.insert(allCoords, bestUnit)
                end
            end
        end
        
        -- ITEMS OBJECTIVES
        if quest.obj.I then
            local targetItemID = quest.obj.I[questPart]
            if targetItemID then
                local itemData = VGDB["items"]["data"][targetItemID]
                local objectiveCoordsAdded = false
                
                if itemData and itemData.coords then
                    local validCoords = nil
                    for _, coordSet in ipairs(itemData.coords) do
                        if coordSet and coordSet[1] and coordSet[2] and coordSet[3] then
                            validCoords = coordSet
                            break
                        end
                    end
                    
                    if validCoords then
                        table.insert(allCoords, {
                            type = "objective",
                            itemId = targetItemID,
                            x = validCoords[1],
                            y = validCoords[2],
                            z = validCoords[3]
                        })
                        objectiveCoordsAdded = true
                    end
                end
                
                if not objectiveCoordsAdded then
                    if VGDB["items"]["data"][targetItemID]["U"] then
                        local units = VGDB["items"]["data"][targetItemID]["U"]

                        local questZone = nil
                        -- Try to get quest zone from start Unit
                        if quest.start and quest.start.U and quest.start.U[1] then
                            local startNPC = VGDB["units"]["data"][quest.start.U[1]]
                            if startNPC and startNPC.coords and startNPC.coords[1] then
                                questZone = startNPC.coords[1][3]
                            end
                        end
                        -- Fallback: try to get quest zone from start Object
                        if not questZone and quest.start and quest.start.O and quest.start.O[1] then
                            local startObj = VGDB["objects"]["data"][quest.start.O[1]]
                            if startObj and startObj.coords and startObj.coords[1] then
                                questZone = startObj.coords[1][3]
                            end
                        end
                        
                        local bestUnit = nil
                        local bestUnits = {}

                        for unitID, dropChance in pairs(units) do
                            local closestUnit, nearest = findClosestUnit(unitID, questZone)
                            if closestUnit and nearest then
                                table.insert(bestUnits, {unit = closestUnit, nearest = nearest })
                            end
                        end

                        table.sort(bestUnits, function(a, b) return a.nearest < b.nearest end)
                        if (bestUnits[1]) then
                            bestUnit = bestUnits[1].unit
                        end
                        
                        if bestUnit then
                            table.insert(allCoords, bestUnit)
                            objectiveCoordsAdded = true
                        end
                    end
                    
                    if not objectiveCoordsAdded and VGDB["items"]["data"][targetItemID]["O"] then
                        local objects = VGDB["items"]["data"][targetItemID]["O"]
                        for objID, dropChance in pairs(objects) do
                            local objData = VGDB["objects"]["data"][objID]
                            if objData and objData.coords then
                                local coords = objData.coords[1]
                                if coords and coords[1] and coords[2] and coords[3] then
                                    table.insert(allCoords, {
                                        type = "objective",
                                        itemId = targetItemID,
                                        objectId = objID,
                                        x = coords[1],
                                        y = coords[2],
                                        z = coords[3],
                                        note = "Object that loots this item"
                                    })
                                    objectiveCoordsAdded = true
                                    break
                                end
                            end
                        end
                    end
                    
                    if not objectiveCoordsAdded and quest.start and quest.start.U and quest.start.U[1] then
                        local startNPC = VGDB["units"]["data"][quest.start.U[1]]
                        if startNPC and startNPC.coords and startNPC.coords[1] then
                            local startCoords = startNPC.coords[1]
                            if startCoords[1] and startCoords[2] and startCoords[3] then
                                table.insert(allCoords, {
                                    type = "objective",
                                    itemId = targetItemID,
                                    x = startCoords[1],
                                    y = startCoords[2],
                                    z = startCoords[3],
                                    note = "Fallback: Using quest start location for item objective"
                                })
                                objectiveCoordsAdded = true
                            end
                        end
                    end
                end
            end
        end
        
        if quest.obj.O then
            for _, objID in ipairs(quest.obj.O) do
                local objData = VGDB["objects"]["data"][objID]
                if objData and objData.coords then
                    local validCoords = nil
                    for _, coordSet in ipairs(objData.coords) do
                        if coordSet and coordSet[1] and coordSet[2] and coordSet[3] then
                            validCoords = coordSet
                            break
                        end
                    end
                    
                    if validCoords then
                        table.insert(allCoords, {
                            type = "objective",
                            objectId = objID,
                            x = validCoords[1],
                            y = validCoords[2],
                            z = validCoords[3]
                        })
                    end
                end
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