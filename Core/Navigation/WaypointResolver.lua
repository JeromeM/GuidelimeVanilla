--[[
Guidelime Vanilla - Waypoint Resolution

Author: Grommey

Description:
Resolves coordinates from guide step data. Pure logic module
with no UI dependencies. Handles quest status checks, step type
detection, description generation, and the 7-priority waypoint
resolution system.

Split from GuideNavigation.lua for maintainability.
]]--

local GLV = LibStub("GuidelimeVanilla")

local WaypointResolver = {}

--[[ VISITED NPC TRACKING ]]--

-- Get visited NPCs from persistent storage
local function getVisitedNPCs()
    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"})
    local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"})
    if not currentGuideId or not currentStepIndex then return {} end

    local visited = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "VisitedTARs", currentStepIndex})
    return visited or {}
end

-- Save visited NPC to persistent storage
function WaypointResolver:SaveVisitedNPC(npcId)
    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"})
    local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"})
    if not currentGuideId or not currentStepIndex or not npcId then return end

    local visited = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "VisitedTARs", currentStepIndex}) or {}
    visited[npcId] = true
    GLV.Settings:SetOption(visited, {"Guide", "Guides", currentGuideId, "VisitedTARs", currentStepIndex})
end

-- Clear visited NPCs for a step (called when step is completed)
function WaypointResolver:ClearVisitedNPCs(guideId, stepIndex)
    if not guideId or not stepIndex then return end
    GLV.Settings:SetOption(nil, {"Guide", "Guides", guideId, "VisitedTARs", stepIndex})
end

--[[ QUEST STATUS FUNCTIONS ]]--

-- Check if a quest is in the player's quest log and its completion status
-- Returns: inLog (boolean), isComplete (boolean)
function WaypointResolver:GetQuestStatus(questId)
    if not questId then return false, false end

    local numId = tonumber(questId)

    -- First check QuestTracker's data (reliable by exact ID)
    if GLV.QuestTracker and GLV.QuestTracker.store then
        local store = GLV.QuestTracker.store

        -- Check if quest was already completed/turned in
        if store.Completed and store.Completed[numId] then
            return false, true  -- Not in log, but was completed
        end

        -- Check if quest is tracked as accepted
        if store.Accepted and store.Accepted[numId] then
            -- Quest was accepted, check if still in log and if complete
            local expectedName = GLV:GetQuestNameByID(questId)
            if expectedName then
                local numEntries = GetNumQuestLogEntries()
                for i = 1, numEntries do
                    local title, level, tag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i)
                    if title and not isHeader and GLV.QuestTracker:QuestNamesMatch(title, expectedName) then
                        return true, (isComplete == 1 or isComplete == true)
                    end
                end
            end
            -- Name scan failed but quest was tracked as accepted.
            -- Don't assume turned in — name mismatch or quest log timing can
            -- cause false negatives. Turnin/abandon hooks handle store cleanup.
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[WaypointResolver]|r Quest " .. tostring(numId) .. " tracked as accepted but not found by name — assuming still in log")
            end
            return true, false
        end
    end

    -- Fallback: Check quest log directly by name (for quests accepted before tracking started)
    local expectedName = GLV:GetQuestNameByID(questId)
    if expectedName then
        local numEntries = GetNumQuestLogEntries()
        for i = 1, numEntries do
            local title, level, tag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i)
            if title and not isHeader and GLV.QuestTracker:QuestNamesMatch(title, expectedName) then
                return true, (isComplete == 1 or isComplete == true)
            end
        end
    end

    return false, false
end

-- Get the first uncompleted quest action from step (QT before QA)
-- Returns: questTag, questId, actionType, objectiveIndex
function WaypointResolver:GetCurrentQuestAction(stepData)
    if not stepData then
        return nil, nil, nil, nil
    end

    -- Collect all quest tags in order from the step
    local questActions = {}

    -- First check step-level questTags (main source)
    if stepData.questTags then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Found " .. table.getn(stepData.questTags) .. " step-level questTags")
        end
        for _, questTag in ipairs(stepData.questTags) do
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r  - Tag: " .. tostring(questTag.tag) .. " QuestId: " .. tostring(questTag.questId) .. " ObjIdx: " .. tostring(questTag.objectiveIndex))
            end
            table.insert(questActions, {
                tag = questTag.tag,
                questId = questTag.questId,
                title = questTag.title,
                objectiveIndex = questTag.objectiveIndex,
                coords = stepData.coords
            })
        end
    else
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r No step-level questTags")
        end
    end

    -- Also check line-level questTags (fallback)
    if stepData.lines then
        for lineIdx, line in ipairs(stepData.lines) do
            if line.questTags then
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Found " .. table.getn(line.questTags) .. " line-level questTags on line " .. lineIdx)
                end
                for _, questTag in ipairs(line.questTags) do
                    if GLV.Debug then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r  - Tag: " .. tostring(questTag.tag) .. " QuestId: " .. tostring(questTag.questId) .. " ObjIdx: " .. tostring(questTag.objectiveIndex))
                    end
                    table.insert(questActions, {
                        tag = questTag.tag,
                        questId = questTag.questId,
                        title = questTag.title,
                        objectiveIndex = questTag.objectiveIndex,
                        coords = line.coords
                    })
                end
            end
        end
    end

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Total questActions: " .. table.getn(questActions))
    end

    -- Find the first action that needs to be done
    for _, action in ipairs(questActions) do
        local inLog, isComplete = self:GetQuestStatus(action.questId)

        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Checking " .. tostring(action.tag) .. " q" .. tostring(action.questId) .. " inLog=" .. tostring(inLog) .. " isComplete=" .. tostring(isComplete))
        end

        if action.tag == "TURNIN" then
            -- QT: Need to turn in if quest is in log
            if inLog then
                return action, action.questId, "TURNIN", action.objectiveIndex
            end
        elseif action.tag == "ACCEPT" then
            -- QA: Need to accept if quest is NOT in log
            if not inLog then
                return action, action.questId, "ACCEPT", action.objectiveIndex
            end
        elseif action.tag == "COMPLETE" then
            -- QC: Need to complete if quest is in log but not complete
            if inLog and not isComplete then
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Returning COMPLETE for q" .. tostring(action.questId) .. " objIdx=" .. tostring(action.objectiveIndex))
                end
                return action, action.questId, "COMPLETE", action.objectiveIndex
            end
        end
    end

    -- All actions done, return nil
    return nil, nil, nil, nil
end

--[[ STEP TYPE AND DESCRIPTION ]]--

-- Gets the step type from step data
function WaypointResolver:GetStepType(stepData)
    if not stepData or not stepData.lines then
        return nil
    end

    for _, line in ipairs(stepData.lines) do
        if line.stepType then
            return line.stepType
        end
    end

    return ""
end

-- Generates step description based on step data and target coordinates
function WaypointResolver:GetStepDescription(stepData, targetCoords, currentAction)
    local description = "Follow the guide"

    -- Use currentAction's questId if available, otherwise find from step data
    local questId = nil
    if currentAction and currentAction.questId then
        questId = currentAction.questId
    elseif stepData and stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.questId then
                questId = line.questId
                break
            end
        end
    end

    if questId then
        local questName = GLV:GetQuestNameByID(questId)
        local questLevel = GLV:GetQuestLevelByID(questId)

        if questName then
            -- Determine action type from currentAction or targetCoords
            local actionType = currentAction and currentAction.tag or nil

            -- Add quest icon symbol based on action type (yellow color)
            local questIcon = ""
            if actionType == "TURNIN" then
                questIcon = "|cFFFFFC01?|r "
            elseif actionType == "ACCEPT" then
                questIcon = "|cFFFFFC01!|r "
            end

            if actionType == "TURNIN" then
                -- Turn in quest - prioritize quest database NPC over targetCoords
                local npcName = GLV:GetQuestTurninNPCName(questId)
                if not npcName and targetCoords and targetCoords.npcId then
                    npcName = GLV:getTargetName(targetCoords.npcId)
                end
                if npcName then
                    description = questName .. " | Turn in to " .. npcName
                else
                    description = questName .. " | Turn in"
                end
            elseif actionType == "ACCEPT" then
                -- Accept quest - prioritize quest database NPC over targetCoords
                local npcName = GLV:GetQuestAcceptNPCName(questId)
                if not npcName and targetCoords and targetCoords.npcId then
                    npcName = GLV:getTargetName(targetCoords.npcId)
                end
                if npcName then
                    description = questName .. " | Accept from " .. npcName
                else
                    description = questName .. " | Accept"
                end
            elseif targetCoords and targetCoords.type == "target" then
                if targetCoords.npcId then
                    local npcName = GLV:getTargetName(targetCoords.npcId)
                    if npcName then
                        description = questName .. " | Talk to " .. npcName
                    else
                        description = questName .. " | Find NPC " .. targetCoords.npcId
                    end
                else
                    description = questName .. " | Objective"
                end
            elseif targetCoords and targetCoords.type == "objective" then
                if targetCoords.npcId then
                    local npcName = GLV:getTargetName(targetCoords.npcId)
                    if npcName then
                        description = questName .. " | Kill " .. npcName
                    else
                        description = questName .. " | Kill NPC " .. targetCoords.npcId
                    end
                elseif targetCoords.itemId then
                    local itemName = GLV:GetItemNameById(tonumber(targetCoords.itemId))
                    if itemName then
                        description = questName .. " | Collect " .. itemName
                    else
                        description = questName .. " | Collect Item " .. targetCoords.itemId
                    end
                elseif targetCoords.objectId then
                    description = questName .. " | Interact with Object"
                else
                    description = questName .. " | Complete Objective"
                end
            else
                description = questName
            end

            description = questIcon .. "[" .. questLevel .. "]" .. " | " .. description
        else
            description = "Quest " .. questId
        end
    end

    return description, questId
end

-- Finds coordinates by type from a coordinate list
function WaypointResolver:FindCoordinatesByType(coordsList, stepType)
    local targetCoords = nil

    if stepType == "ACCEPT" then
        for _, coord in ipairs(coordsList) do
            if coord.type == "start" then
                targetCoords = coord
                break
            end
        end
    elseif stepType == "COMPLETE" then
        for _, coord in ipairs(coordsList) do
            if coord.type == "objective" then
                targetCoords = coord
                break
            end
        end
        if not targetCoords then
            for _, coord in ipairs(coordsList) do
                if coord.type == "end" then
                    targetCoords = coord
                    break
                end
            end
        end
    elseif stepType == "TURNIN" then
        for _, coord in ipairs(coordsList) do
            if coord.type == "end" then
                targetCoords = coord
                break
            end
        end
        if not targetCoords then
            for _, coord in ipairs(coordsList) do
                if coord.type == "start" then
                    targetCoords = coord
                    break
                end
            end
        end
    elseif stepType == "OBJECTIVE" then
        for _, coord in ipairs(coordsList) do
            if coord.type == "objective" then
                targetCoords = coord
                break
            end
        end
        if not targetCoords then
            for _, coord in ipairs(coordsList) do
                if coord.type == "start" then
                    targetCoords = coord
                    break
                end
            end
        end
    end

    if not targetCoords then
        targetCoords = coordsList[1]
    end

    return targetCoords
end

--[[ COORDINATE COLLECTION HELPERS ]]--

-- Extract TAR coordinates from step data (skips visited NPCs and TARs on quest lines)
local function extractTARCoordinates(stepData)
    local tarCoords = {}
    if not stepData or not stepData.lines then
        return tarCoords
    end

    -- Get visited NPCs from persistent storage
    local visitedNPCs = getVisitedNPCs()

    for _, line in ipairs(stepData.lines) do
        -- Skip TARs on lines with quest tags (QA/QT/QC).
        -- QA/QT: quest DB provides NPC coords. QC: quest DB provides objective coords.
        -- TARs on quest lines are informational context, not navigation targets.
        local hasQuestTag = false
        if line.questTags then
            for _, qt in ipairs(line.questTags) do
                if qt.tag == "ACCEPT" or qt.tag == "TURNIN" or qt.tag == "COMPLETE" then
                    hasQuestTag = true
                    break
                end
            end
        end

        if not hasQuestTag and line.targetIds then
            for _, targetId in ipairs(line.targetIds) do
                -- Skip visited NPCs
                if not visitedNPCs[targetId] then
                    local npcCoords = GLV:GetNPCCoordinates(targetId)
                    if npcCoords and npcCoords.x and npcCoords.y and npcCoords.z then
                        table.insert(tarCoords, {
                            x = npcCoords.x,
                            y = npcCoords.y,
                            z = npcCoords.z,
                            type = "target",
                            npcId = targetId
                        })
                    end
                end
            end
        end
    end

    return tarCoords
end

-- Collect all coordinates from step lines
local function collectAllStepCoordinates(stepData)
    local allCoords = {}
    if stepData and stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.coords and table.getn(line.coords) > 0 then
                for _, coord in ipairs(line.coords) do
                    table.insert(allCoords, coord)
                end
            end
        end
    end
    return allCoords
end

-- Collect all waypoints in order: TAR targets, then quest NPCs (QT/QA)
-- Returns a sequential list of waypoints to navigate through
local function collectOrderedWaypoints(stepData)
    local waypoints = {}
    if not stepData or not stepData.lines then
        return waypoints
    end

    -- Get visited NPCs from persistent storage
    local visitedNPCs = getVisitedNPCs()

    -- First, collect NPC IDs for completed quest actions (to skip their TARs)
    local completedQuestNPCs = {}
    for _, line in ipairs(stepData.lines) do
        if line.questTags then
            for _, questTag in ipairs(line.questTags) do
                local questId = questTag.questId
                local inLog, isComplete = WaypointResolver:GetQuestStatus(questId)

                if questTag.tag == "TURNIN" and not inLog then
                    -- Quest already turned in - mark the turn-in NPC as "done"
                    local quest = VGDB and VGDB["quests"] and VGDB["quests"]["data"] and VGDB["quests"]["data"][tonumber(questId)]
                    if quest and quest["end"] and quest["end"].U then
                        local npcId = quest["end"].U[1]
                        if npcId then
                            completedQuestNPCs[npcId] = true
                        end
                    end
                elseif questTag.tag == "ACCEPT" and inLog then
                    -- Quest already accepted - mark the accept NPC as "done"
                    local quest = VGDB and VGDB["quests"] and VGDB["quests"]["data"] and VGDB["quests"]["data"][tonumber(questId)]
                    if quest and quest["start"] and quest["start"].U then
                        local npcId = quest["start"].U[1]
                        if npcId then
                            completedQuestNPCs[npcId] = true
                        end
                    end
                end
            end
        end
    end

    -- First pass: collect TAR targets in order
    -- Skip TARs on lines with quest tags (QA/QT/QC) — quest DB provides coords.
    -- TARs on quest lines are informational context, not navigation targets.
    for _, line in ipairs(stepData.lines) do
        if line.targetIds then
            local hasQuestTag = false
            if line.questTags then
                for _, qt in ipairs(line.questTags) do
                    if qt.tag == "ACCEPT" or qt.tag == "TURNIN" or qt.tag == "COMPLETE" then
                        hasQuestTag = true
                        break
                    end
                end
            end

            if not hasQuestTag then
                for _, targetId in ipairs(line.targetIds) do
                    -- Skip TAR if: NPC's quest action is done, OR already visited
                    if not completedQuestNPCs[targetId] and not visitedNPCs[targetId] then
                        local npcCoords = GLV:GetNPCCoordinates(targetId)
                        if npcCoords and npcCoords.x and npcCoords.y and npcCoords.z then
                            local npcName = GLV:getTargetName(targetId) or ("NPC " .. targetId)
                            table.insert(waypoints, {
                                x = npcCoords.x,
                                y = npcCoords.y,
                                z = npcCoords.z,
                                type = "target",
                                npcId = targetId,
                                description = "Go to " .. npcName
                            })
                        end
                    end
                end
            end
        end
    end

    -- Second pass: collect quest NPCs (QT then QA) from quest database
    -- Only add waypoints for actions that still need to be done
    for _, line in ipairs(stepData.lines) do
        if line.questTags then
            for _, questTag in ipairs(line.questTags) do
                local questId = questTag.questId
                local questName = GLV:GetQuestNameByID(questId) or ("Quest " .. questId)

                -- Check quest status to skip already-done actions
                local inLog, isComplete = WaypointResolver:GetQuestStatus(questId)

                if questTag.tag == "TURNIN" then
                    -- Only add QT waypoint if quest is still in log (not yet turned in)
                    if inLog then
                        -- Get turn-in NPC from quest database
                        local quest = VGDB and VGDB["quests"] and VGDB["quests"]["data"] and VGDB["quests"]["data"][tonumber(questId)]
                        if quest and quest["end"] and quest["end"].U then
                            local npcId = quest["end"].U[1]
                            if npcId then
                                local npcCoords = GLV:GetNPCCoordinates(npcId)
                                if npcCoords and npcCoords.x and npcCoords.y and npcCoords.z then
                                    local npcName = GLV:getTargetName(npcId) or ("NPC " .. npcId)
                                    -- Format: ? Quest Name | Turn in to NPC
                                    local description = "|cFFFFFC01?|r " .. questName .. " | Turn in to " .. npcName
                                    table.insert(waypoints, {
                                        x = npcCoords.x,
                                        y = npcCoords.y,
                                        z = npcCoords.z,
                                        type = "turnin",
                                        npcId = npcId,
                                        questId = questId,
                                        actionType = "TURNIN",
                                        description = description
                                    })
                                end
                            end
                        end
                    end
                elseif questTag.tag == "ACCEPT" then
                    -- Only add QA waypoint if quest is NOT in log (not yet accepted)
                    if not inLog then
                        -- Get accept NPC from quest database
                        local quest = VGDB and VGDB["quests"] and VGDB["quests"]["data"] and VGDB["quests"]["data"][tonumber(questId)]
                        if quest and quest["start"] and quest["start"].U then
                            local npcId = quest["start"].U[1]
                            if npcId then
                                local npcCoords = GLV:GetNPCCoordinates(npcId)
                                if npcCoords and npcCoords.x and npcCoords.y and npcCoords.z then
                                    local npcName = GLV:getTargetName(npcId) or ("NPC " .. npcId)
                                    -- Format: ! Quest Name | Accept from NPC
                                    local description = "|cFFFFFC01!|r " .. questName .. " | Accept from " .. npcName
                                    table.insert(waypoints, {
                                        x = npcCoords.x,
                                        y = npcCoords.y,
                                        z = npcCoords.z,
                                        type = "accept",
                                        npcId = npcId,
                                        questId = questId,
                                        actionType = "ACCEPT",
                                        description = description
                                    })
                                end
                            end
                        end
                    end
                -- Note: QC (COMPLETE) is NOT added to ordered waypoints
                -- QC uses the existing dynamic "closest objective" system
                end
            end
        end
    end

    return waypoints
end

-- Find quest coordinates for objectives
local function findQuestObjectiveCoordinates(stepData, playerPos, objectiveIndex)
    if not stepData or not stepData.lines then
        return nil
    end

    for _, line in ipairs(stepData.lines) do
        -- Get objectiveIndex from line's questTags if not provided
        local lineObjectiveIndex = objectiveIndex
        if not lineObjectiveIndex and line.questTags then
            for _, questTag in ipairs(line.questTags) do
                if questTag.objectiveIndex then
                    lineObjectiveIndex = questTag.objectiveIndex
                    break
                end
            end
        end

        if line.questId then
            local questCoords = GLV:GetQuestAllCoords(line.questId, lineObjectiveIndex)
            if questCoords and table.getn(questCoords) > 0 then
                -- Find closest objective coordinate
                local closestCoord = nil
                local closestDistance = nil

                for _, coord in ipairs(questCoords) do
                    if coord.type == "objective" then
                        local coordPos = {
                            c = playerPos.c,
                            x = coord.x / 100,
                            y = coord.y / 100,
                            z = coord.z
                        }

                        local distance = GLV.GuideNavigation:CalculateDistance(playerPos, coordPos)
                        if not closestDistance or distance < closestDistance then
                            closestDistance = distance
                            closestCoord = coord
                        end
                    end
                end

                if closestCoord then
                    return closestCoord
                else
                    return WaypointResolver:FindCoordinatesByType(questCoords, WaypointResolver:GetStepType(stepData))
                end
            end
        end
    end
    return nil
end

--[[ MAIN RESOLUTION ]]--

-- Resolves waypoints for a step
-- Returns: {
--   waypoints = {},           -- Array of waypoint coordinates
--   description = "",         -- Navigation description text
--   specialMode = nil,        -- "XP", "EQUIP", "HEARTHSTONE", "NEXT_GUIDE", "USE_ITEM", or nil
--   specialModeData = nil,    -- Data specific to the special mode
--   questId = nil,            -- Current quest ID for progress display
--   actionType = nil,         -- Current action type (TURNIN, ACCEPT, COMPLETE)
--   objectiveIndex = nil,     -- Quest objective index
--   useItemId = nil           -- Item ID for use-item fallback
-- }
function WaypointResolver:ResolveWaypoints(stepData)
    local result = {
        waypoints = {},
        description = nil,
        specialMode = nil,
        specialModeData = nil,
        questId = nil,
        actionType = nil,
        objectiveIndex = nil,
        useItemId = nil
    }

    if not stepData then return result end

    -- Extract use item ID for fallback display
    if stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.useItemId then
                result.useItemId = line.useItemId
                break
            end
        end
    end

    -- Check for SKILL step
    if stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.skillRequirement then
                result.specialMode = "SKILL"
                result.specialModeData = line.skillRequirement
                return result
            end
        end
    end

    -- Check for XP step
    if stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.experienceRequirement then
                result.specialMode = "XP"
                result.specialModeData = line.experienceRequirement
                return result
            end
        end
    end

    -- Check for EQUIP step
    if stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.stepType == "EQUIP" and line.equipItemId then
                local itemName = GLV:GetItemNameById(line.equipItemId)
                result.specialMode = "EQUIP"
                result.specialModeData = { itemId = line.equipItemId, itemName = itemName }
                return result
            end
        end
    end

    -- Check for HEARTHSTONE step
    if stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.stepType == "HEARTHSTONE" and line.hearthDestination then
                result.specialMode = "HEARTHSTONE"
                result.specialModeData = line.hearthDestination
                return result
            end
        end
    end

    -- Check for NEXT_GUIDE step (last step with clickToNext flag)
    if GLV.CurrentGuide and GLV.CurrentGuide.clickToNext and GLV.CurrentGuide.next then
        local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
        local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
        local totalSteps = GLV.CurrentDisplayStepsCount or 0

        if currentStepIndex == totalSteps then
            result.specialMode = "NEXT_GUIDE"
            result.specialModeData = GLV.CurrentGuide.next
            return result
        end
    end

    -- Get current player position
    local playerPos = GLV.GuideNavigation:GetPlayerPosition()
    if not playerPos then
        return result
    end

    -- Get the current quest action (first uncompleted: QT > QA > QC)
    local currentAction, currentQuestId, actionType, currentObjectiveIndex = self:GetCurrentQuestAction(stepData)

    -- Use the current action's type, or fallback to step's type
    local stepType = actionType or self:GetStepType(stepData)

    -- Store quest tracking info in result
    result.questId = currentQuestId
    result.actionType = actionType or stepType
    result.objectiveIndex = currentObjectiveIndex

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Stored: currentQuestId=" .. tostring(result.questId) .. " currentActionType=" .. tostring(result.actionType) .. " objIdx=" .. tostring(currentObjectiveIndex))
    end

    local targetCoords = nil

    -- Priority 1: Explicit GOTO coordinates from all lines
    local allCoords = collectAllStepCoordinates(stepData)
    local gotoCoords = {}

    for _, coord in ipairs(allCoords) do
        if coord.type == "goto" then
            table.insert(gotoCoords, coord)
        end
    end

    -- Priority 2: Ordered waypoints (TAR targets + quest NPCs in sequence)
    local orderedWaypoints = collectOrderedWaypoints(stepData)

    -- Combine GOTO coords + ordered waypoints into a multi-waypoint sequence.
    -- GOTO coords (from [OC] lines) guide the player to the area first,
    -- then quest NPC waypoints handle the actual action.
    if table.getn(gotoCoords) > 0 then
        -- Append ordered waypoints after GOTO coords (if any)
        for _, wp in ipairs(orderedWaypoints) do
            table.insert(gotoCoords, wp)
        end
        local description, descQuestId = self:GetStepDescription(stepData, gotoCoords[1], currentAction)
        result.questId = result.questId or descQuestId
        result.waypoints = gotoCoords
        result.description = description
        if GLV.Debug and table.getn(gotoCoords) > 1 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Multi-waypoint: " .. table.getn(gotoCoords) .. " GOTO + ordered waypoints")
        end
        return result
    end

    if table.getn(orderedWaypoints) > 0 then
        result.waypoints = orderedWaypoints
        -- Use pre-computed description from first waypoint if available
        result.description = orderedWaypoints[1].description or self:GetStepDescription(stepData, orderedWaypoints[1], currentAction)
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Ordered waypoints: " .. table.getn(orderedWaypoints) .. " waypoints loaded")
            for i, wp in ipairs(orderedWaypoints) do
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r  " .. i .. ": " .. (wp.description or wp.type))
            end
        end
        return result
    end

    -- Priority 3: Legacy TAR coordinates (fallback if no ordered waypoints)
    local tarCoords = extractTARCoordinates(stepData)
    if table.getn(tarCoords) > 0 then
        result.waypoints = tarCoords
        targetCoords = tarCoords[1]
        if GLV.Debug and table.getn(tarCoords) > 1 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Multi-waypoint (TAR): " .. table.getn(tarCoords) .. " waypoints loaded")
        end
    end

    -- Priority 3b: Quest-specific coordinates for the current action (QT/QA/QC)
    if not targetCoords and currentQuestId then
        -- Pass objectiveIndex to get coordinates for specific quest objective
        local questCoords = GLV:GetQuestAllCoords(currentQuestId, currentObjectiveIndex)
        if questCoords and table.getn(questCoords) > 0 then
            targetCoords = self:FindCoordinatesByType(questCoords, stepType)
        end
    end

    -- Priority 4: Current action's line coordinates
    if not targetCoords and currentAction and currentAction.coords and table.getn(currentAction.coords) > 0 then
        targetCoords = self:FindCoordinatesByType(currentAction.coords, stepType)
    end

    -- Priority 5: Direct step coordinates
    if not targetCoords and stepData.coords and table.getn(stepData.coords) > 0 then
        targetCoords = self:FindCoordinatesByType(stepData.coords, stepType)
    end

    -- Priority 6: Other line coordinates (non-goto)
    if not targetCoords and table.getn(allCoords) > 0 then
        targetCoords = self:FindCoordinatesByType(allCoords, stepType)
    end

    -- Priority 7: Quest objective coordinates (for COMPLETE steps or fallback)
    if not targetCoords or stepType == "COMPLETE" then
        local questCoords = findQuestObjectiveCoordinates(stepData, playerPos, currentObjectiveIndex)
        if questCoords then
            targetCoords = questCoords
        end
    end

    -- Set waypoint if coordinates found
    if targetCoords then
        local description, descQuestId = self:GetStepDescription(stepData, targetCoords, currentAction)
        result.questId = result.questId or descQuestId
        result.description = description
        -- If we haven't set waypoints yet from TAR (priority 3), set single waypoint
        if table.getn(result.waypoints) == 0 then
            result.waypoints = { targetCoords }
        end
    elseif result.useItemId then
        -- No coordinates found but step has a use item - signal USE_ITEM mode
        result.specialMode = "USE_ITEM"
        result.specialModeData = { itemId = result.useItemId }
    end

    return result
end

--[[ ZONE UTILITY FUNCTIONS ]]--

-- Gets zone information from zone name
function WaypointResolver:GetZoneInfo(zone, cont)
    if zone == nil then
        return
    end
    zone = type(zone) == "string" and string.lower(zone) or zone
    for continent, zones in pairs(Astrolabe.ContinentList) do
        for index, zData in pairs(zones) do
            local nameLower = string.lower(zData.mapFile)
            local nameLower2 = string.lower(zData.mapName)
            if (cont ~= nil and cont == continent and zone == index) or zone == nameLower or zone == nameLower2 then
                return continent, index, zData.mapName
            end
        end
    end
    return nil, nil, nil
end

-- Expose to GLV
GLV.WaypointResolver = WaypointResolver
