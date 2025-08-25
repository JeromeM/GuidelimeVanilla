--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
DB Query functions
]]--
local GLV = LibStub("GuidelimeVanilla")


--[[ LOCAL FUNCTIONS ]]--

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
    npcName = "UNKNOWN_NAME"
    local Localized = getLocalizedKey()
    if not VGDB or not VGDB["units"] or not VGDB["units"][Localized] then 
        return npcName
    end

    npcName = VGDB["units"][Localized][tonumber(id)]
    return npcName
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

-- Get spell name by spell ID
function GLV:getSpellName(id)
    if not VGDB or not VGDB.spells then
        return "UNKNOWN_SPELL"
    end

    local numId = tonumber(id)
    local spell = VGDB.spells[numId]

    if spell and spell.n then
        return spell.n
    end

    return "UNKNOWN"
end


--[[ QUEST RELATED FUNCTIONS ]]--

-- Get quest ID by quest name
function GLV:GetQuestIDByName(name)
    local Localized = getLocalizedKey()
    if not VGDB or not VGDB.quests or not VGDB.quests[Localized] then
        return nil
    end
    
    for id, data in pairs(VGDB.quests[Localized]) do
        if data and data.T and data.T == name then
            return id
        end
    end
    
    return nil
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

-- Get all coordinates for a quest (start, end, objectives)
function GLV:GetQuestAllCoords(id, questPart)
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
    end
    
    if quest.obj then
        if quest.obj.U then
            for _, npcID in ipairs(quest.obj.U) do
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
                            type = "objective",
                            npcId = npcID,
                            x = validCoords[1],
                            y = validCoords[2],
                            z = validCoords[3]
                        })
                    end
                end
            end
        end
        
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
                        if quest.start and quest.start.U and quest.start.U[1] then
                            local startNPC = VGDB["units"]["data"][quest.start.U[1]]
                            if startNPC then
                                if startNPC.coords then
                                    if startNPC.coords[1] then
                                        questZone = startNPC.coords[1][3]
                                    end
                                end
                            end
                        end
                        
                        local bestUnit = nil
                        local bestDistance = 999999
                        
                        for unitID, dropChance in pairs(units) do
                            if VGDB["units"]["data"][unitID] and VGDB["units"]["data"][unitID]["coords"] then
                                for _, coordSet in ipairs(VGDB["units"]["data"][unitID]["coords"]) do
                                    if coordSet and coordSet[1] and coordSet[2] and coordSet[3] then
                                        if not questZone or (coordSet[3] and questZone and coordSet[3] == questZone) then
                                            local distance = 999999
                                            if GetPlayerMapPosition and GetPlayerMapPosition("player") then
                                                local playerX, playerY = GetPlayerMapPosition("player")
                                                if playerX and playerY then
                                                    playerX = playerX * 100
                                                    playerY = playerY * 100
                                                    
                                                    local dx = coordSet[1] - playerX
                                                    local dy = coordSet[2] - playerY
                                                    distance = math.sqrt(dx * dx + dy * dy)
                                                end
                                            end
                                            
                                            if distance and bestDistance and distance < bestDistance then
                                                bestDistance = distance
                                                bestUnit = {
                                                    type = "objective",
                                                    itemId = targetItemID,
                                                    npcId = unitID,
                                                    x = coordSet[1],
                                                    y = coordSet[2],
                                                    z = coordSet[3],
                                                    note = "Unit that loots this item (same zone, closest)"
                                                }
                                            end
                                        end
                                    end
                                end
                            end
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