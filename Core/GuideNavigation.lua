--[[
Guidelime Vanilla - Navigation System

Author: Grommey
Version: 0.2

Description:
Autonomous navigation system with custom arrow display.
No longer depends on TomTom addon.

A lot of this code has been copied from TomTom, pfQuest !
Thanks to the authors of these addons !
]]--

local GLV = LibStub("GuidelimeVanilla")

local GuideNavigation = {}

--[[ CONSTANTS ]]--

local ARROW_TEXTURE_PATH = "Interface\\AddOns\\GuidelimeVanilla\\Textures\\NavArrows"
local TOTAL_ARROWS = 108
local UPDATE_FREQUENCY = 0.02 -- Very frequent updates like pfQuest

--[[ STATE VARIABLES ]]--

local currentWaypoint = nil
local navigationFrame = nil
local updateTimer = 0
local isNavigationActive = false

--[[ HELPER FUNCTIONS ]]--

-- Helper modulo function for Vanilla compatibility
local function modulo(val, by)
    return val - math.floor(val/by)*by
end

--[[ FRAME CREATION AND MANAGEMENT ]]--

-- Creates the main navigation frame with all UI elements
function GuideNavigation:CreateNavigationFrame()
    if navigationFrame then
        return
    end
    
    -- Main frame (invisible)
    navigationFrame = CreateFrame("Frame", "GLV_NavigationFrame", UIParent)
    navigationFrame:SetWidth(48)
    navigationFrame:SetHeight(48)
    navigationFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    navigationFrame:SetFrameStrata("HIGH")
    navigationFrame:Hide()
    
    navigationFrame:SetMovable(true)
    navigationFrame:EnableMouse(true)
    navigationFrame:RegisterForDrag("LeftButton")
    navigationFrame:SetScript("OnDragStart", function()
        if IsShiftKeyDown() then
            this:StartMoving()
        end
    end)
    navigationFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        GLV.Settings:SetOption({this:GetLeft(), this:GetTop()}, {"Navigation", "FramePosition"})
    end)
    
    navigationFrame.arrow = navigationFrame:CreateTexture(nil, "ARTWORK")
    navigationFrame.arrow:SetAllPoints(navigationFrame)
    navigationFrame.arrow:SetTexture(ARROW_TEXTURE_PATH)
    navigationFrame.arrow:SetVertexColor(1, 1, 1, 1)
    navigationFrame.arrow:SetTexCoord(0, 56/512, 0, 42/512)
    
    navigationFrame.questName = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.questName:SetPoint("TOP", navigationFrame, "BOTTOM", 0, -8)
    navigationFrame.questName:SetTextColor(1, 0.8, 0)
    navigationFrame.questName:SetText("")
    navigationFrame.questName:SetJustifyH("CENTER")
    
    navigationFrame.objective = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.objective:SetPoint("TOP", navigationFrame.questName, "BOTTOM", 0, -5)
    navigationFrame.objective:SetTextColor(1, 1, 1)
    navigationFrame.objective:SetText("")
    navigationFrame.objective:SetJustifyH("CENTER")
    
    navigationFrame.distance = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.distance:SetPoint("TOP", navigationFrame.objective, "BOTTOM", 0, -5)
    navigationFrame.distance:SetTextColor(0.8, 0.8, 0.8)
    navigationFrame.distance:SetText("")
    navigationFrame.distance:SetJustifyH("CENTER")
    
    local savedPos = GLV.Settings:GetOption({"Navigation", "FramePosition"})
    if savedPos and savedPos[1] and savedPos[2] then
        navigationFrame:ClearAllPoints()
        navigationFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", savedPos[1], savedPos[2])
    end
    
    navigationFrame:SetScript("OnUpdate", function()
        GuideNavigation:OnUpdate()
    end)
end

--[[ COORDINATE AND CALCULATION FUNCTIONS ]]--

-- Gets the current player position using Astrolabe
function GuideNavigation:GetPlayerPosition()
    local C, Z, X, Y = Astrolabe:GetCurrentPlayerPosition()
    return {
        c = C,
        x = X,
        y = Y,
        z = Z
    }
end

-- Calculates distance between two points using Astrolabe
function GuideNavigation:CalculateDistance(pos1, pos2)
    local dist, xDelta, yDelta = Astrolabe:ComputeDistance( pos1.c, pos1.z, pos1.x, pos1.y, pos2.c, pos2.z, pos2.x, pos2.y )
    return dist, xDelta, yDelta
end

-- Formats distance text with proper units
function GuideNavigation:FormatDistance(distance)
    local distanceInMeters = distance * 10
    
    if distanceInMeters < 1000 then
        return string.format("%.0fm", distanceInMeters / 10)
    else
        return string.format("%.1fkm", distanceInMeters / 10000)
    end
end

-- Gets color based on distance (green=close, yellow=medium, red=far)
function GuideNavigation:GetDistanceColor(distance)
    local closeDistance = 5
    local farDistance = 50
    
    local ratio = distance / farDistance
    ratio = math.min(1, math.max(0, ratio))
    
    local r, g, b
    if ratio <= 0.5 then
        local t = ratio * 2
        r = t
        g = 1
        b = 0
    else
        local t = (ratio - 0.5) * 2
        r = 1
        g = 1 - t
        b = 0
    end
    
    return r, g, b
end

-- Calculates angle from player to target, accounting for player facing
function GuideNavigation:CalculateAngle(playerPos, targetPos)
    local degtemp = 0
    local playerFacing = GetPlayerFacing()
    local dist, xDelta, yDelta = Astrolabe:ComputeDistance( playerPos.c, playerPos.z, playerPos.x, playerPos.y, targetPos.c, targetPos.z, targetPos.x, targetPos.y )
    if not xDelta or not yDelta then return end
    local dir = atan2(xDelta, -(yDelta))
    if ( dir > 0 ) then
        degtemp = math.pi*2 - dir
    else
        degtemp = -dir
    end

    if degtemp < 0 then degtemp = degtemp + 360 end
    
    local angle = math.rad(degtemp)
    angle = angle - playerFacing

    return angle
end

-- Converts angle to arrow index (0-107)
function GuideNavigation:AngleToArrowIndex(angle)
    local cell = modulo(math.floor(angle / (math.pi*2) * 108 + 0.5), 108)
    return cell
end

-- Gets texture coordinates for arrow index
function GuideNavigation:GetArrowTexCoords(index)
    index = math.max(0, math.min(index, TOTAL_ARROWS - 1))
    
    local column = modulo(index, 9)
    local row = math.floor(index / 9)
    
    local xstart = (column * 56) / 512
    local ystart = (row * 42) / 512
    local xend = ((column + 1) * 56) / 512
    local yend = ((row + 1) * 42) / 512
    
    return xstart, xend, ystart, yend
end

--[[ WAYPOINT MANAGEMENT ]]--

-- Sets a new waypoint with coordinates and description
function GuideNavigation:SetWaypoint(coords, description)
    if not coords or not coords.x or not coords.y then
        return false
    end
    
    local zoneName = GLV:GetZoneNameByID(coords.z)
    local cont, zone = self:GetZoneInfo(zoneName)

    currentWaypoint = {
        c = cont,
        x = coords.x / 100,
        y = coords.y / 100,
        z = zone or GLV:GetCurrentZoneID(),
        description = description or "Guide Objective"
    }
    
    return true
end

-- Clears the current waypoint
function GuideNavigation:ClearWaypoint()
    currentWaypoint = nil
end

-- Adds a waypoint (replaces TomTom function)
function GuideNavigation:AddWaypoint(coords, description)
    self:RemoveCurrentWaypoint()
    
    if self:SetWaypoint(coords, description) then
        if GLV.Settings:GetOption({"Navigation", "AutoShow"}, true) then
            self:Show()
        end
    end
end

-- Removes current waypoint (replaces TomTom function)
function GuideNavigation:RemoveCurrentWaypoint()
    self:ClearWaypoint()
    self:Hide()
end

-- Clears all waypoints (replaces TomTom function)
function GuideNavigation:ClearAllWaypoints()
    self:RemoveCurrentWaypoint()
end

--[[ NAVIGATION VISIBILITY CONTROL ]]--

-- Shows the navigation frame
function GuideNavigation:Show()
    if not navigationFrame then
        self:CreateNavigationFrame()
    end
    
    if currentWaypoint then
        navigationFrame:Show()
        isNavigationActive = true
        self:UpdateNavigation()
    end
end

-- Hides the navigation frame
function GuideNavigation:Hide()
    if navigationFrame then
        navigationFrame:Hide()
            navigationFrame.questName:SetText("")
    navigationFrame.objective:SetText("")
    navigationFrame.distance:SetText("")
    end
    isNavigationActive = false
end

-- Toggles navigation visibility
function GuideNavigation:Toggle()
    if isNavigationActive then
        self:Hide()
    else
        self:Show()
    end
end

--[[ UPDATE AND DISPLAY FUNCTIONS ]]--

-- Updates the navigation display
function GuideNavigation:UpdateNavigation()
    if not navigationFrame or not currentWaypoint or not isNavigationActive then
        return
    end
    
    local playerPos = self:GetPlayerPosition()
    if not playerPos then
        return
    end
    
    if playerPos.z ~= currentWaypoint.z then
        navigationFrame.questName:SetText("")
        navigationFrame.objective:SetText("Different Zone")
        navigationFrame.distance:SetText("")
        navigationFrame.distance:SetTextColor(1, 0.5, 0.5)
        navigationFrame.arrow:SetAlpha(0.3)
        return
    end
    
    if currentWaypoint.description then
        local description = currentWaypoint.description
        if string.find(description, " - ") then
            local questName, objective = strsplit(" - ", description, 2)
            navigationFrame.questName:SetText(questName or "")
            navigationFrame.objective:SetText(objective or "")
        else
            navigationFrame.questName:SetText("")
            navigationFrame.objective:SetText(description)
        end
    else
        navigationFrame.questName:SetText("")
        navigationFrame.objective:SetText("Guide Objective")
    end
    
    local distance, xDelta, yDelta = self:CalculateDistance(playerPos, currentWaypoint)
    
    local distanceText = self:FormatDistance(distance)
    navigationFrame.distance:SetText("Distance: " .. distanceText)
    
    local r, g, b = self:GetDistanceColor(distance)
    navigationFrame.arrow:SetVertexColor(r, g, b, 1)
    
    if distance < 3 then
        navigationFrame.distance:SetTextColor(0, 1, 0)
        navigationFrame.arrow:SetAlpha(0.5)
    else
        navigationFrame.distance:SetTextColor(0.8, 0.8, 0.8)
        navigationFrame.arrow:SetAlpha(1.0)
    end
    
    local angle = self:CalculateAngle(playerPos, currentWaypoint)
    local arrowIndex = self:AngleToArrowIndex(angle)
    
    local left, right, top, bottom = self:GetArrowTexCoords(arrowIndex)
    navigationFrame.arrow:SetTexCoord(left, right, top, bottom)
end

-- OnUpdate handler for frame updates
function GuideNavigation:OnUpdate()
    if not isNavigationActive then
        return
    end
    
    updateTimer = updateTimer + arg1
    if updateTimer >= UPDATE_FREQUENCY then
        updateTimer = 0
        self:UpdateNavigation()
    end
end

--[[ GUIDE INTEGRATION FUNCTIONS ]]--

-- Gets the step type from step data
function GuideNavigation:GetStepType(stepData)
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
function GuideNavigation:GetStepDescription(stepData, targetCoords)
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
            if targetCoords and targetCoords.type == "target" then
                if targetCoords.npcId then
                    local npcName = GLV:getTargetName(targetCoords.npcId)
                    if npcName then
                        description = questName .. " - Talk to " .. npcName
                    else
                        description = questName .. " - Find NPC " .. targetCoords.npcId
                    end
                else
                    description = questName .. " - Objective"
                end
            elseif targetCoords and targetCoords.type == "objective" then
                if targetCoords.npcId then
                    local npcName = GLV:getTargetName(targetCoords.npcId)
                    if npcName then
                        description = questName .. " - Kill " .. npcName
                    else
                        description = questName .. " - Kill NPC " .. targetCoords.npcId
                    end
                elseif targetCoords.itemId then
                    local itemName = GLV:GetItemNameById(tonumber(targetCoords.itemId))
                    if itemName then
                        description = questName .. " - Collect " .. itemName
                    else
                        description = questName .. " - Collect Item " .. targetCoords.itemId
                    end
                elseif targetCoords.objectId then
                    description = questName .. " - Interact with Object"
                else
                    description = questName .. " - Complete Objective"
                end
            else
                description = questName
            end
        else
            description = "Quest " .. questId
        end
    end
    
    return description
end

-- Finds coordinates by type from a coordinate list
function GuideNavigation:FindCoordinatesByType(coordsList, stepType)
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

-- Updates waypoint for a specific guide step
function GuideNavigation:UpdateWaypointForStep(stepData)
    self:RemoveCurrentWaypoint()
    
    local targetCoords = nil
    local stepType = self:GetStepType(stepData)
    
    local tarCoords = {}
    if stepData and stepData.lines then
        for _, line in ipairs(stepData.lines) do
            local lineText = line.text or ""
            for targetId in string.gmatch(lineText, "%[TAR(%d+)%]") do
                local npcCoords = GLV:GetNPCCoordinates(targetId)
                if npcCoords and npcCoords.x and npcCoords.y and npcCoords.z then
                    table.insert(tarCoords, {x = npcCoords.x, y = npcCoords.y, z = npcCoords.z, type = "target", npcId = tonumber(targetId)})
                end
            end
        end
    end
    
    if table.getn(tarCoords) > 0 then
        targetCoords = tarCoords[1]
    end
    
    if not targetCoords and stepData and stepData.coords and table.getn(stepData.coords) > 0 then
        targetCoords = self:FindCoordinatesByType(stepData.coords, stepType)
    end
    
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
    
    if targetCoords then
        local description = self:GetStepDescription(stepData, targetCoords)
        self:AddWaypoint(targetCoords, description)
    end
end

-- Handles step changes in the guide
function GuideNavigation:OnStepChanged(stepData)
    self:UpdateWaypointForStep(stepData)
end

--[[ ZONE UTILITY FUNCTIONS ]]--

-- Gets zone information from zone name
function GuideNavigation:GetZoneInfo(zone, cont)
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

--[[ INITIALIZATION ]]--

-- Initializes the navigation system
function GuideNavigation:Init()
    if not GLV.Settings:GetOption({"Navigation", "AutoShow"}) then
        GLV.Settings:SetOption(true, {"Navigation", "AutoShow"})
    end
    
    if GLV.CurrentGuide then
        local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
        local currentStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
        
        if currentStep > 0 then
            if GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[currentStep] then
                local stepData = GLV.CurrentDisplaySteps[currentStep]
                self:OnStepChanged(stepData)
            elseif GLV.CurrentGuide and GLV.CurrentGuide.steps and GLV.CurrentGuide.steps[currentStep] then
                local stepData = GLV.CurrentGuide.steps[currentStep]
                self:OnStepChanged(stepData)
            end
        end
    end
end

-- Expose to GLV
GLV.GuideNavigation = GuideNavigation