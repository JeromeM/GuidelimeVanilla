--[[
Guidelime Vanilla - Navigation System

Author: Grommey
Version: 0.2

Description:
Autonomous navigation system with custom arrow display.
No longer depends on TomTom addon.
]]--

local GLV = LibStub("GuidelimeVanilla")

local GuideNavigation = {}

-- Navigation state
local currentWaypoint = nil
local navigationFrame = nil
local updateTimer = 0
local isNavigationActive = false

-- Constants
local ARROW_TEXTURE_PATH = "Interface\\AddOns\\GuidelimeVanilla\\Textures\\NavArrows"
local ARROW_SIZE = 48 -- Taille réduite de la flèche
local ARROWS_PER_ROW = 9
local TOTAL_ARROWS = 108
local UPDATE_FREQUENCY = 0.02 -- Mise à jour très fréquente comme pfQuest

--[[ FRAME CREATION FUNCTIONS ]]--

-- Create the navigation frame
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
    
    -- Make it movable only with Shift
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
        -- Save position
        GLV.Settings:SetOption({this:GetLeft(), this:GetTop()}, {"Navigation", "FramePosition"})
    end)
    
    -- Arrow texture
    navigationFrame.arrow = navigationFrame:CreateTexture(nil, "ARTWORK")
    navigationFrame.arrow:SetAllPoints(navigationFrame)
    navigationFrame.arrow:SetTexture(ARROW_TEXTURE_PATH)
    navigationFrame.arrow:SetVertexColor(1, 1, 1, 1)
    navigationFrame.arrow:SetTexCoord(0, 56/512, 0, 42/512)
    
    -- Quest name text
    navigationFrame.questName = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.questName:SetPoint("TOP", navigationFrame, "BOTTOM", 0, -5)
    navigationFrame.questName:SetTextColor(1, 0.8, 0) -- Couleur dorée
    navigationFrame.questName:SetText("")
    navigationFrame.questName:SetJustifyH("CENTER")
    
    -- Objective text
    navigationFrame.objective = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.objective:SetPoint("TOP", navigationFrame.questName, "BOTTOM", 0, -2)
    navigationFrame.objective:SetTextColor(1, 1, 1)
    navigationFrame.objective:SetText("")
    navigationFrame.objective:SetJustifyH("CENTER")
    
    -- Distance text
    navigationFrame.distance = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.distance:SetPoint("TOP", navigationFrame.objective, "BOTTOM", 0, -2)
    navigationFrame.distance:SetTextColor(0.8, 0.8, 0.8)
    navigationFrame.distance:SetText("")
    navigationFrame.distance:SetJustifyH("CENTER")
    
    -- Load saved position
    local savedPos = GLV.Settings:GetOption({"Navigation", "FramePosition"})
    if savedPos and savedPos[1] and savedPos[2] then
        navigationFrame:ClearAllPoints()
        navigationFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", savedPos[1], savedPos[2])
    end
    
    -- Update script
    navigationFrame:SetScript("OnUpdate", function()
        GuideNavigation:OnUpdate()
    end)
end

--[[ COORDINATE AND CALCULATION FUNCTIONS ]]--

-- Get player position
function GuideNavigation:GetPlayerPosition()
    -- local x, y = GetPlayerMapPosition("player")
    -- if x == 0 and y == 0 then
    --     return nil
    -- end
    
    -- return {
    --     x = x * 100, -- pfQuest utilise cette échelle
    --     y = y * 100,
    --     z = GLV:GetCurrentZoneID()
    -- }
    local C, Z, X, Y = Astrolabe:GetCurrentPlayerPosition()
    return {
        c = C,
        x = X,
        y = Y,
        z = Z
    }
end

-- Calculate distance between two points
function GuideNavigation:CalculateDistance(pos1, pos2)
    -- if not pos1 or not pos2 then
    --     return 0
    -- end
    
    -- local dx = pos2.x - pos1.x
    -- local dy = pos2.y - pos1.y
    
    -- return math.sqrt(dx * dx + dy * dy)
    local dist, xDelta, yDelta = Astrolabe:ComputeDistance( pos1.c, pos1.z, pos1.x, pos1.y, pos2.c, pos2.z, pos2.x, pos2.y )
    return dist, xDelta, yDelta
end

-- Format distance text with proper units
function GuideNavigation:FormatDistance(distance)
    local distanceInMeters = distance * 10 -- Conversion approximative en mètres
    
    if distanceInMeters < 1000 then
        return string.format("%.0fm", distanceInMeters / 10)
    else
        return string.format("%.1fkm", distanceInMeters / 10000)
    end
end

-- Get color based on distance (green=close, yellow=medium, red=far)
function GuideNavigation:GetDistanceColor(distance)
    -- Distances de référence (ajustables)
    local closeDistance = 5   -- Très proche = vert
    local farDistance = 50    -- Très loin = rouge
    
    local ratio = distance / farDistance
    ratio = math.min(1, math.max(0, ratio)) -- Clamp entre 0 et 1
    
    -- Transition douce : vert -> jaune -> rouge
    local r, g, b
    if ratio <= 0.5 then
        -- Vert vers jaune (0-0.5)
        local t = ratio * 2
        r = t
        g = 1
        b = 0
    else
        -- Jaune vers rouge (0.5-1)
        local t = (ratio - 0.5) * 2
        r = 1
        g = 1 - t
        b = 0
    end
    
    return r, g, b
end

-- Calculate angle from player to target, accounting for player facing
function GuideNavigation:CalculateAngle(playerPos, targetPos)
    -- if not playerPos or not targetPos then
    --     return 0
    -- end
    
    -- -- Copié de pfQuest - calcul exact
    -- local xDelta = (targetPos.x - playerPos.x) * 1.5
    -- local yDelta = (targetPos.y - playerPos.y)
    -- local dir = math.atan2(xDelta, -(yDelta))
    -- dir = dir > 0 and (math.pi*2) - dir or -dir
    -- if dir < 0 then dir = dir + 360 end
    -- local angle = math.rad(dir)
    
    -- -- Get player facing direction
    -- local playerFacing = GetPlayerFacing()
    -- if not playerFacing then
    --     playerFacing = 0
    -- end
    
    -- -- Calculate relative angle
    -- angle = angle - playerFacing
    
    -- return angle
    local degtemp = 0
    local playerFacing = GetPlayerFacing()
    local dist, xDelta, yDelta = Astrolabe:ComputeDistance( playerPos.c, playerPos.z, playerPos.x, playerPos.y, targetPos.c, targetPos.z, targetPos.x, targetPos.y )
	if not xDelta or not yDelta then return end
	local dir = atan2(xDelta, -(yDelta))
	if ( dir > 0 ) then
		degtemp = math.pi*2 - dir;
	else
		degtemp = -dir;
	end

    if degtemp < 0 then degtemp = degtemp + 360; end
    
    local angle = math.rad(degtemp)
    angle = angle - playerFacing

	return angle
end

-- Helper modulo function for Vanilla compatibility
local function modulo(val, by)
    return val - math.floor(val/by)*by
end

-- Convert angle to arrow index (0-107)
function GuideNavigation:AngleToArrowIndex(angle)
    -- Copié de pfQuest - méthode exacte
    local cell = modulo(math.floor(angle / (math.pi*2) * 108 + 0.5), 108)
    return cell
end

-- Get texture coordinates for arrow index
function GuideNavigation:GetArrowTexCoords(index)
    -- S'assurer que l'index est valide
    index = math.max(0, math.min(index, TOTAL_ARROWS - 1))
    
    -- Copié de pfQuest - coordonnées exactes
    local column = modulo(index, 9)
    local row = math.floor(index / 9)
    
    -- Dimensions des flèches selon pfQuest : 56x42 pixels dans une texture 512x512
    local xstart = (column * 56) / 512
    local ystart = (row * 42) / 512
    local xend = ((column + 1) * 56) / 512
    local yend = ((row + 1) * 42) / 512
    
    return xstart, xend, ystart, yend
end

--[[ UPDATE AND DISPLAY FUNCTIONS ]]--

-- Update the navigation display
function GuideNavigation:UpdateNavigation()
    if not navigationFrame or not currentWaypoint or not isNavigationActive then
        return
    end
    
    local playerPos = self:GetPlayerPosition()
    if not playerPos then
        return
    end
    
    -- Check if we're in the same zone
    if playerPos.z ~= currentWaypoint.z then
        -- Different zone - show zone message
        navigationFrame.distance:SetText("Zone différente")
        navigationFrame.distance:SetTextColor(1, 0.5, 0.5)
        navigationFrame.arrow:SetAlpha(0.3)
        return
    end
    
    -- Calculate distance
    local distance, xDelta, yDelta = self:CalculateDistance(playerPos, currentWaypoint)
    
    -- Format distance text
    local distanceText = self:FormatDistance(distance)
    navigationFrame.distance:SetText("Distance: " .. distanceText)
    
    -- Get distance-based color for arrow
    local r, g, b = self:GetDistanceColor(distance)
    navigationFrame.arrow:SetVertexColor(r, g, b, 1)
    
    -- If very close, show "arrived" state
    if distance < 3 then
        navigationFrame.distance:SetTextColor(0, 1, 0) -- Vert
        navigationFrame.arrow:SetAlpha(0.5)
    else
        navigationFrame.distance:SetTextColor(0.8, 0.8, 0.8) -- Gris normal
        navigationFrame.arrow:SetAlpha(1.0)
    end
    
    -- Calculate angle and update arrow
    local angle = self:CalculateAngle(playerPos, currentWaypoint)
    local arrowIndex = self:AngleToArrowIndex(angle)
    
    -- Update arrow texture coordinates directement sans lissage
    local left, right, top, bottom = self:GetArrowTexCoords(arrowIndex)
    navigationFrame.arrow:SetTexCoord(left, right, top, bottom)
end

-- OnUpdate handler
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

--[[ WAYPOINT MANAGEMENT FUNCTIONS ]]--

-- Set a new waypoint
function GuideNavigation:SetWaypoint(coords, description)
    if not coords or not coords.x or not coords.y then
        return false
    end
    
    zoneName = GLV:GetZoneNameByID(coords.z)
    cont, zone = self:GetZoneInfo(zoneName)

    currentWaypoint = {
        c = cont,
        x = coords.x / 100,
        y = coords.y / 100,
        z = zone or GLV:GetCurrentZoneID(),
        description = description or "Guide Objective"
    }
    
    return true
end

-- Clear current waypoint
function GuideNavigation:ClearWaypoint()
    currentWaypoint = nil
end

-- Show navigation
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

-- Hide navigation
function GuideNavigation:Hide()
    if navigationFrame then
        navigationFrame:Hide()
    end
    isNavigationActive = false
end

-- Toggle navigation visibility
function GuideNavigation:Toggle()
    if isNavigationActive then
        self:Hide()
    else
        self:Show()
    end
end

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

--[[ PUBLIC INTERFACE FUNCTIONS ]]--

-- Check if navigation is available (always true now)
function GuideNavigation:IsAvailable()
    return true
end

-- Add a waypoint (replaces TomTom function)
function GuideNavigation:AddWaypoint(coords, description)
    -- Remove previous waypoint
    self:RemoveCurrentWaypoint()
    
    -- Set new waypoint
    if self:SetWaypoint(coords, description) then
        -- Auto-show navigation if enabled
        if GLV.Settings:GetOption({"Navigation", "AutoShow"}, true) then
            self:Show()
        end
    end
end

-- Remove current waypoint (replaces TomTom function)
function GuideNavigation:RemoveCurrentWaypoint()
    self:ClearWaypoint()
    self:Hide()
end

-- Clear all waypoints (replaces TomTom function)
function GuideNavigation:ClearAllWaypoints()
    self:RemoveCurrentWaypoint()
end

--[[ COORDINATE HANDLING FUNCTIONS ]]--

-- [Keep all your existing coordinate handling functions unchanged]
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
            if targetCoords and targetCoords.type == "objective" then
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

function GuideNavigation:UpdateWaypointForStep(stepData)
    self:RemoveCurrentWaypoint()
    
    local targetCoords = nil
    local stepType = self:GetStepType(stepData)
    
    -- Extract coordinates from [TAR] tags first
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

function GuideNavigation:OnStepChanged(stepData)
    self:UpdateWaypointForStep(stepData)
end

--[[ INITIALIZATION AND SETTINGS ]]--

function GuideNavigation:Init()
    -- Initialize settings - vous devrez peut-être créer une fonction SetOptionDefault dans Settings.lua
    -- ou utiliser une approche différente selon votre implémentation
    if not GLV.Settings:GetOption({"Navigation", "AutoShow"}) then
        GLV.Settings:SetOption(true, {"Navigation", "AutoShow"})
    end
    
    -- Try to update waypoint for current guide if available
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