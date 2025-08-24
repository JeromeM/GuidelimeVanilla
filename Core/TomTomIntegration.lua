--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
TomTom TWOW Integration.
Handles waypoint management when changing guide steps.
]]--
local GLV = LibStub("GuidelimeVanilla")

local TomTomIntegration = {}

-- Current active waypoint
local currentWaypoint = nil


--[[ AVAILABILITY CHECK FUNCTIONS ]]--

-- Check if TomTom TWOW is available
function TomTomIntegration:IsAvailable()
    return TomTom and type(TomTom) == "table"
end


--[[ WAYPOINT MANAGEMENT FUNCTIONS ]]--

-- Add a waypoint to TomTom
function TomTomIntegration:AddWaypoint(coords, description)
    if not self:IsAvailable() then 
        return 
    end
    
    -- Remove previous waypoint if exists
    self:RemoveCurrentWaypoint()
    
    -- Add new waypoint using a simpler approach
    if coords and coords.x and coords.y then
        local success, result = pcall(function()
            -- Convert zone ID to zone name
            local zoneName = GLV:GetZoneNameByID(coords.z or 1)
            
            if not zoneName then
                return nil
            end
            
            -- Use TomTom's zone info functions to get continent and zone
            local cleanZone = TomTom:CleanZoneName(zoneName)
            local continent, zone = TomTom:GetZoneInfo(cleanZone)
            
            if not continent or not zone then
                return nil
            end
            
            local options = {
                title = description or "Guide Objective",
                persistent = false,
                minimap = true,
                world = true
            }
            
            return TomTom:AddMFWaypoint(continent, zone, coords.x/100, coords.y/100, options)
        end)
        
        if success and result then
            currentWaypoint = result
        end
    end
end

-- Remove current waypoint
function TomTomIntegration:RemoveCurrentWaypoint()
    if not self:IsAvailable() then return end
    
    if currentWaypoint then
        TomTom:RemoveWaypoint(currentWaypoint)
        currentWaypoint = nil
        
        -- Waypoint removed
    end
end

-- Clear all waypoints (when guide is unloaded)
function TomTomIntegration:ClearAllWaypoints()
    if not self:IsAvailable() then return end
    
    self:RemoveCurrentWaypoint()
end


--[[ COORDINATE HANDLING FUNCTIONS ]]--

-- Helper function to find coordinates based on step type
function TomTomIntegration:FindCoordinatesByType(coordsList, stepType)
    local targetCoords = nil
    
    if stepType == "ACCEPT" then
        -- For ACCEPT steps, use START coordinates (quest giver)
        for _, coord in ipairs(coordsList) do
            if coord.type == "start" then
                targetCoords = coord
                break
            end
        end
    elseif stepType == "COMPLETE" then
        -- For COMPLETE steps, ALWAYS use OBJECTIVE coordinates (what needs to be done)
        for _, coord in ipairs(coordsList) do
            if coord.type == "objective" then
                targetCoords = coord
                break
            end
        end
        -- If no objectives found, fall back to END coordinates (quest turn-in)
        if not targetCoords then
            for _, coord in ipairs(coordsList) do
                if coord.type == "end" then
                    targetCoords = coord
                    break
                end
            end
        end
    elseif stepType == "TURNIN" then
        -- For TURNIN steps, ALWAYS use END coordinates (quest turn-in NPC)
        for _, coord in ipairs(coordsList) do
            if coord.type == "end" then
                targetCoords = coord
                break
            end
        end
        -- If no END coords found, fall back to START coordinates (quest giver)
        if not targetCoords then
            for _, coord in ipairs(coordsList) do
                if coord.type == "start" then
                    targetCoords = coord
                    break
                end
            end
        end
    elseif stepType == "OBJECTIVE" then
        -- For OBJECTIVE steps (kill enemies, collect items, etc.), use OBJECTIVE coordinates
        for _, coord in ipairs(coordsList) do
            if coord.type == "objective" then
                targetCoords = coord
                break
            end
        end
        -- If no objectives found, fall back to START coordinates (quest giver location)
        if not targetCoords then
            for _, coord in ipairs(coordsList) do
                if coord.type == "start" then
                    targetCoords = coord
                    break
                end
            end
        end
    end
    
    -- If no specific type found, use first coordinate set
    if not targetCoords then
        targetCoords = coordsList[1]
    end
    
    return targetCoords
end

-- Helper function to get step description
function TomTomIntegration:GetStepDescription(stepData, targetCoords)
    local description = "Guide Step"
    
    local questId = 0
    if stepData and stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.questId then
                questId = line.questId
                break
            end
        end
    end
    
    if questId then
        local questName = GLV:GetQuestNameByID(questId)
        
        if questName then
            if targetCoords and targetCoords.type == "objective" then
                -- For objectives, show what needs to be done
                if targetCoords.npcId then
                    local npcName = GLV:getTargetName(targetCoords.npcId)
                    description = "Kill " .. npcName
                elseif targetCoords.itemId then
                    description = "Collect " .. GLV:GetItemNameById(tonumber(targetCoords.itemId))
                elseif targetCoords.objectId then
                    description = "Interact with " .. questName
                else
                    description = questName .. " (Objective)"
                end
            else
                description = questName
            end
        end
    end
    
    return description
end


--[[ STEP PROCESSING FUNCTIONS ]]--

-- Get step type from parsed data
function TomTomIntegration:GetStepType(stepData)
    if not stepData or not stepData.lines then
        return nil
    end
    
    -- Check each line for step type
    for _, line in ipairs(stepData.lines) do
        if line.stepType then
            return line.stepType
        end
    end
    
    return "" -- Default fallback
end

-- Update waypoint when step changes
function TomTomIntegration:UpdateWaypointForStep(stepData)
    if not self:IsAvailable() then return end
    
    -- Remove current waypoint
    self:RemoveCurrentWaypoint()
    
    local targetCoords = nil
    local stepType = self:GetStepType(stepData)
    
    -- Extract coordinates from [TAR] tags first
    local tarCoords = {}
    if stepData and stepData.lines then
        for _, line in ipairs(stepData.lines) do
            local lineText = line.text or ""
            for targetId in string.gmatch(lineText, "%[TAR(%d+)%]") do
                -- Use DBTools functions to get coordinates
                local npcCoords = GLV:GetNPCCoordinates(targetId)
                if npcCoords and npcCoords.x and npcCoords.y and npcCoords.z then
                    table.insert(tarCoords, {x = npcCoords.x, y = npcCoords.y, z = npcCoords.z, type = "target", npcId = tonumber(targetId)})
                end
            end
        end
    end
    
    -- First try to use TAR coordinates
    if table.getn(tarCoords) > 0 then
        targetCoords = tarCoords[1]
    end
    
    -- If no TAR coords, check for coordinates in stepData.coords
    if not targetCoords and stepData and stepData.coords and table.getn(stepData.coords) > 0 then
        targetCoords = self:FindCoordinatesByType(stepData.coords, stepType)
    end
    
    -- If no coords in stepData.coords, check in stepData.lines
    if not targetCoords and stepData and stepData.lines then
        local allCoords = {}
        for _, line in ipairs(stepData.lines) do
            if line.coords and table.getn(line.coords) > 0 then
                for _, coord in ipairs(line.coords) do
                    table.insert(allCoords, coord)
                end
            end
        end
        
        if table.getn(allCoords) > 0 then
            targetCoords = self:FindCoordinatesByType(allCoords, stepType)
        end
    end
    
    -- Add waypoint if coordinates found
    if targetCoords then
        local description = self:GetStepDescription(stepData, targetCoords)
        self:AddWaypoint(targetCoords, description)
    end
end

-- Public function to be called from other modules
function TomTomIntegration:OnStepChanged(stepData)
    self:UpdateWaypointForStep(stepData)
end


--[[ INITIALIZATION FUNCTIONS ]]--

-- Initialize integration
function TomTomIntegration:Init()
    if self:IsAvailable() then
        -- Try to update waypoint for current guide if available
        if GLV.CurrentGuide then
            -- Get the current guide ID for correct settings path
            local currentGuideId = GLV.Ace.db.char.Guide.CurrentGuide or "Unknown"
            local currentStep = GLV.Ace.db.char.Guide.Guides[currentGuideId].CurrentStep or 0
            
            if currentStep > 0 then
                -- Use displaySteps instead of raw guide.steps to get the grouped steps with coordinates
                if GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[currentStep] then
                    local stepData = GLV.CurrentDisplaySteps[currentStep]
                    self:OnStepChanged(stepData)
                else
                    -- Fallback: try to get step directly from the guide
                    if GLV.CurrentGuide and GLV.CurrentGuide.steps and GLV.CurrentGuide.steps[currentStep] then
                        local stepData = GLV.CurrentGuide.steps[currentStep]
                        self:OnStepChanged(stepData)
                    end
                end
            end
        end
    end
end

-- Expose to GLV
GLV.TomTomIntegration = TomTomIntegration
