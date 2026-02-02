--[[
Guidelime Vanilla - Navigation System

Author: Grommey

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
local UPDATE_FREQUENCY = 0.02 -- 50 FPS for smooth arrow animation

--[[ STATE VARIABLES ]]--

local currentWaypoint = nil
local navigationFrame = nil
local updateTimer = 0
local isNavigationActive = false
local playerPos = nil

-- Multi-waypoint tracking
local allWaypoints = {}      -- All waypoints for current step
local currentWaypointIndex = 1  -- Index of current waypoint in allWaypoints
local currentStepData = nil  -- Current step data for description generation
local WAYPOINT_REACH_DISTANCE = 5  -- Distance in yards to consider waypoint reached


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

    -- Item icon button for EQUIP steps (initially hidden)
    navigationFrame.itemButton = CreateFrame("Button", nil, navigationFrame)
    navigationFrame.itemButton:SetWidth(48)
    navigationFrame.itemButton:SetHeight(48)
    navigationFrame.itemButton:SetAllPoints(navigationFrame)
    navigationFrame.itemButton:Hide()

    navigationFrame.itemIcon = navigationFrame.itemButton:CreateTexture(nil, "ARTWORK")
    navigationFrame.itemIcon:SetAllPoints(navigationFrame.itemButton)
    navigationFrame.itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    navigationFrame.itemButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Click to equip")
        GameTooltip:Show()
    end)
    navigationFrame.itemButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Next Guide button (initially hidden)
    navigationFrame.nextGuideButton = CreateFrame("Button", nil, navigationFrame)
    navigationFrame.nextGuideButton:SetWidth(48)
    navigationFrame.nextGuideButton:SetHeight(48)
    navigationFrame.nextGuideButton:SetAllPoints(navigationFrame)
    navigationFrame.nextGuideButton:Hide()

    navigationFrame.nextGuideIcon = navigationFrame.nextGuideButton:CreateTexture(nil, "ARTWORK")
    navigationFrame.nextGuideIcon:SetAllPoints(navigationFrame.nextGuideButton)
    navigationFrame.nextGuideIcon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")

    navigationFrame.nextGuideButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Click for next guide")
        GameTooltip:Show()
    end)
    navigationFrame.nextGuideButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Hearthstone button (initially hidden)
    navigationFrame.hearthButton = CreateFrame("Button", nil, navigationFrame)
    navigationFrame.hearthButton:SetWidth(48)
    navigationFrame.hearthButton:SetHeight(48)
    navigationFrame.hearthButton:SetAllPoints(navigationFrame)
    navigationFrame.hearthButton:Hide()

    navigationFrame.hearthIcon = navigationFrame.hearthButton:CreateTexture(nil, "ARTWORK")
    navigationFrame.hearthIcon:SetAllPoints(navigationFrame.hearthButton)
    navigationFrame.hearthIcon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")

    navigationFrame.hearthButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Click to use Hearthstone")
        GameTooltip:Show()
    end)
    navigationFrame.hearthButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    navigationFrame.questName = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    navigationFrame.questName:SetPoint("TOP", navigationFrame, "BOTTOM", 0, -8)
    navigationFrame.questName:SetTextColor(1, 0.8, 0)
    navigationFrame.questName:SetText("")
    navigationFrame.questName:SetJustifyH("CENTER")
    
    navigationFrame.objective = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.objective:SetPoint("TOP", navigationFrame.questName, "BOTTOM", 0, -5)
    navigationFrame.objective:SetTextColor(1, 1, 1)
    navigationFrame.objective:SetText("")
    navigationFrame.objective:SetJustifyH("CENTER")

    navigationFrame.questProgress = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.questProgress:SetPoint("TOP", navigationFrame.objective, "BOTTOM", 0, -3)
    navigationFrame.questProgress:SetTextColor(1, 1, 1)
    navigationFrame.questProgress:SetText("")
    navigationFrame.questProgress:SetJustifyH("CENTER")

    navigationFrame.distance = navigationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.distance:SetPoint("TOP", navigationFrame.questProgress, "BOTTOM", 0, -5)
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

    -- Apply saved scale
    local savedScale = GLV.Settings:GetOption({"UI", "NavigationScale"}) or 1
    if savedScale ~= 1 then
        navigationFrame:SetScale(savedScale)
    end
end

-- Apply scale to the navigation frame
function GuideNavigation:ApplyScale(scale)
    if not navigationFrame then
        self:CreateNavigationFrame()
    end
    if navigationFrame then
        navigationFrame:SetScale(scale or 1)
    end
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
    local distanceInMeters = distance
    
    if distanceInMeters < 1000 then
        return string.format("%.0fm", distanceInMeters)
    else
        return string.format("%.1fkm", distanceInMeters / 1000)
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
function GuideNavigation:CalculateAngle(targetPos)
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
        z = zone,  -- May be nil if GetZoneInfo failed
        zoneName = zoneName,  -- Store zone name for later lookup
        zoneId = coords.z,  -- Store database zone ID
        description = description or "Guide Objective"
    }

    return true
end

-- Clears the current waypoint
function GuideNavigation:ClearWaypoint()
    currentWaypoint = nil
end

-- Returns the current waypoint (for debugging)
function GuideNavigation:GetCurrentWaypoint()
    return currentWaypoint
end

-- Adds a waypoint (replaces TomTom function)
function GuideNavigation:AddWaypoint(coords, description)
    self:ClearAllWaypoints()
    
    if self:SetWaypoint(coords, description) then
        if GLV.Settings:GetOption({"Navigation", "AutoShow"}, true) then
            self:Show()
        end
    end
end

-- Clears all waypoints and hides navigation (replaces TomTom functions)
function GuideNavigation:ClearAllWaypoints()
    self:ClearWaypoint()
    self:Hide()
end

-- Alias for backward compatibility
function GuideNavigation:RemoveCurrentWaypoint()
    self:ClearAllWaypoints()
    self:HideEquipItem()
    self:HideHearthstone()
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
        navigationFrame.questProgress:SetText("")
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
    
    playerPos = self:GetPlayerPosition()
    if not playerPos then
        return
    end
    
    -- If zone wasn't resolved earlier, try again now
    if not currentWaypoint.z and currentWaypoint.zoneName then
        local cont, zone = self:GetZoneInfo(currentWaypoint.zoneName)
        if zone then
            currentWaypoint.c = cont
            currentWaypoint.z = zone
        end
    end

    if not currentWaypoint.z or playerPos.z ~= currentWaypoint.z then
        -- Hide navigation when in different zone
        navigationFrame:Hide()
        return
    end

    -- Show navigation when in correct zone
    if not navigationFrame:IsVisible() then
        navigationFrame:Show()
    end
    
    if currentWaypoint.description then
        local description = currentWaypoint.description
        if string.find(description, " | ") then
            local color_rgb = {}
            local questLevel, questName, objective = strsplit(" | ", description, 3)
            questLevel = string.gsub(questLevel, "%[(.-)%]", function(questLevel)
                local playerLevel = UnitLevel("player")
                local diff = tonumber(questLevel) - playerLevel

                if diff >= 6 then
                    color_rgb = { r = 233/255, g = 54/255, b = 65/255 }
                elseif diff >= 3 and diff <= 5 then
                    color_rgb = { r = 255/255, g = 125/255, b = 10/255 }
                elseif diff >= -2 and diff <= 2 then
                    color_rgb = { r = 255/255, g = 235/255, b = 42/255 }
                elseif diff >= -5 and diff <= -3 then
                    color_rgb = { r = 144/255, g = 200/255, b = 54/255 }
                elseif diff <= -6 then
                    color_rgb = { r = 128/255, g = 128/255, b = 128/255 }
                else
                    color_rgb = { r = 1, g = 1, b = 1 }
                end

                return "[" .. questLevel .. "]"
            end)
            navigationFrame.questName:SetText(questLevel .. " " .. questName or "")
            navigationFrame.questName:SetTextColor(color_rgb.r, color_rgb.g, color_rgb.b, 1)
            navigationFrame.objective:SetText(objective or "")
        else
            navigationFrame.questName:SetText("")
            navigationFrame.objective:SetText(description)
        end
    else
        navigationFrame.questName:SetText("")
        navigationFrame.objective:SetText("Guide Objective")
    end

    -- Display quest progress objectives (only for QC/COMPLETE steps, not QT/QA)
    if self.currentQuestId and GLV.QuestTracker and self.currentActionType == "COMPLETE" then
        local objectives, allComplete = GLV.QuestTracker:GetQuestProgress(self.currentQuestId)
        if objectives and table.getn(objectives) > 0 then
            local progressLines = {}
            for _, obj in ipairs(objectives) do
                local color
                if obj.completed then
                    color = "|cFF00FF00"
                else
                    -- Parse progress like "0/8" to determine color
                    local current, total = string.match(obj.text, "(%d+)/(%d+)")
                    if current and total then
                        local pct = tonumber(current) / tonumber(total)
                        if pct == 0 then
                            color = "|cFFFF0000"
                        elseif pct < 0.33 then
                            color = "|cFFFF8000"
                        elseif pct < 0.66 then
                            color = "|cFFFFFF00"
                        else
                            color = "|cFF00FF00"
                        end
                    else
                        color = "|cFFFFFFFF"
                    end
                end
                table.insert(progressLines, color .. obj.text .. "|r")
            end
            navigationFrame.questProgress:SetText(table.concat(progressLines, "\n"))
        else
            navigationFrame.questProgress:SetText("")
        end
    else
        navigationFrame.questProgress:SetText("")
    end

    local distance, xDelta, yDelta = self:CalculateDistance(playerPos, currentWaypoint)
    
    local distanceText = self:FormatDistance(distance)
    navigationFrame.distance:SetText("Distance: " .. distanceText)
    
    local r, g, b = self:GetDistanceColor(distance)
    navigationFrame.arrow:SetVertexColor(r, g, b, 1)
    
    if distance < WAYPOINT_REACH_DISTANCE then
        navigationFrame.distance:SetTextColor(0, 1, 0)
        navigationFrame.arrow:SetAlpha(0.5)

        -- Check if there's a next waypoint to advance to
        if table.getn(allWaypoints) > currentWaypointIndex then
            currentWaypointIndex = currentWaypointIndex + 1
            local nextCoords = allWaypoints[currentWaypointIndex]
            if nextCoords then
                local description = self:GetStepDescription(currentStepData, nextCoords, nil)
                self:SetWaypoint(nextCoords, description)
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Advanced to waypoint " .. currentWaypointIndex .. "/" .. table.getn(allWaypoints))
                end
            end
        end
    else
        navigationFrame.distance:SetTextColor(0.8, 0.8, 0.8)
        navigationFrame.arrow:SetAlpha(1.0)
    end
    
    local angle = self:CalculateAngle(currentWaypoint)
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

--[[ COORDINATE FINDING FUNCTIONS ]]--

-- Extract TAR coordinates from step data
local function extractTARCoordinates(stepData)
    local tarCoords = {}
    if not stepData or not stepData.lines then
        return tarCoords
    end

    for _, line in ipairs(stepData.lines) do
        -- Use stored targetIds from parser
        if line.targetIds then
            for _, targetId in ipairs(line.targetIds) do
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

                        local distance = GuideNavigation:CalculateDistance(playerPos, coordPos)
                        if not closestDistance or distance < closestDistance then
                            closestDistance = distance
                            closestCoord = coord
                        end
                    end
                end

                if closestCoord then
                    return closestCoord
                else
                    return GuideNavigation:FindCoordinatesByType(questCoords, GuideNavigation:GetStepType(stepData))
                end
            end
        end
    end
    return nil
end

--[[ QUEST STATUS FUNCTIONS ]]--

-- Check if a quest is in the player's quest log and its completion status
-- Returns: inLog (boolean), isComplete (boolean)
-- Uses QuestTracker's tracked data ONLY for reliable ID matching (avoids same-name quest issues)
function GuideNavigation:GetQuestStatus(questId)
    if not questId then return false, false end

    local numId = tonumber(questId)

    -- Use QuestTracker's data exclusively (reliable by exact ID)
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
                    if title and not isHeader and title == expectedName then
                        return true, (isComplete == 1 or isComplete == true)
                    end
                end
            end
            -- Quest was accepted but not in log anymore = turned in (remove from Accepted)
            store.Accepted[numId] = nil
            GLV.Settings:SetOption(store, {"QuestTracker"})
            return false, false
        end
    end

    -- Quest not tracked = not in log (don't use name fallback to avoid same-name issues)
    return false, false
end

-- Get the first uncompleted quest action from step (QT before QA)
-- Returns: questTag, questId, actionType, objectiveIndex
function GuideNavigation:GetCurrentQuestAction(stepData)
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
function GuideNavigation:GetStepDescription(stepData, targetCoords, currentAction)
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

    -- Store questId for progress display
    self.currentQuestId = questId

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
                -- Turn in quest - show turn in destination
                if targetCoords and targetCoords.npcId then
                    local npcName = GLV:getTargetName(targetCoords.npcId)
                    if npcName then
                        description = questName .. " | Turn in to " .. npcName
                    else
                        description = questName .. " | Turn in"
                    end
                else
                    description = questName .. " | Turn in"
                end
            elseif actionType == "ACCEPT" then
                -- Accept quest - show where to accept
                if targetCoords and targetCoords.npcId then
                    local npcName = GLV:getTargetName(targetCoords.npcId)
                    if npcName then
                        description = questName .. " | Accept from " .. npcName
                    else
                        description = questName .. " | Accept"
                    end
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

-- Shows item icon for equip steps instead of the arrow
function GuideNavigation:ShowEquipItem(itemId, itemName)
    if not navigationFrame then
        self:CreateNavigationFrame()
    end
    if not navigationFrame then return end

    -- Get item texture
    local _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    if not itemTexture then
        itemTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    -- Setup icon and click handler
    navigationFrame.itemIcon:SetTexture(itemTexture)
    navigationFrame.itemButton:SetScript("OnClick", function()
        -- Find and equip the item from bags
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local link = GetContainerItemLink(bag, slot)
                if link and string.find(link, itemId) then
                    UseContainerItem(bag, slot)
                    return
                end
            end
        end
    end)

    -- Show item button, hide arrow
    navigationFrame.arrow:Hide()
    navigationFrame.itemButton:Show()
    navigationFrame.questName:SetText(itemName or "Equip item")
    navigationFrame.objective:SetText("")
    navigationFrame.questProgress:SetText("")
    navigationFrame.distance:SetText("Click to equip")
    navigationFrame:Show()

    isNavigationActive = false  -- Don't update arrow rotation
end

-- Hides item icon and restores arrow mode
function GuideNavigation:HideEquipItem()
    if not navigationFrame then return end
    navigationFrame.itemButton:Hide()
    navigationFrame.arrow:Show()
end

-- Shows the next guide button for the last step
function GuideNavigation:ShowNextGuide(nextGuideName)
    if not navigationFrame then
        self:CreateNavigationFrame()
    end

    -- Store next guide content for the click handler
    local nextGuideContent = nextGuideName

    navigationFrame.nextGuideButton:SetScript("OnClick", function()
        if not nextGuideContent then return end

        -- Parse the next guide content: "XX-XX Name" format
        local nextMinLevel, nextMaxLevel, guideName = string.match(nextGuideContent, "(%d+)-(%d+)%s+(.+)")
        if not guideName then
            guideName = nextGuideContent
        end

        -- Generate the expected guide ID
        local expectedGuideId = string.gsub(guideName, "%s+", "_")
        if nextMinLevel and nextMinLevel ~= "" then
            expectedGuideId = expectedGuideId .. "_" .. nextMinLevel
        end
        if nextMaxLevel and nextMaxLevel ~= "" then
            expectedGuideId = expectedGuideId .. "_" .. nextMaxLevel
        end

        -- Look for the guide and load it
        for groupName, groupGuides in pairs(GLV.loadedGuides) do
            if groupGuides then
                for guideId, guideData in pairs(groupGuides) do
                    if guideId == expectedGuideId then
                        GLV:LoadGuide(groupName, guideId)
                        return
                    end
                end
            end
        end
    end)

    -- Show next guide button, hide arrow
    navigationFrame.arrow:Hide()
    navigationFrame.nextGuideButton:Show()
    navigationFrame.questName:SetText(nextGuideName or "Next Guide")
    navigationFrame.objective:SetText("")
    navigationFrame.questProgress:SetText("")
    navigationFrame.distance:SetText("Click for next guide")
    navigationFrame:Show()

    isNavigationActive = false  -- Don't update arrow rotation
end

-- Hides next guide button and restores arrow mode
function GuideNavigation:HideNextGuide()
    if not navigationFrame then return end
    navigationFrame.nextGuideButton:Hide()
    navigationFrame.arrow:Show()
end

-- Shows hearthstone icon for [H] steps instead of the arrow
function GuideNavigation:ShowHearthstone(destination)
    if not navigationFrame then
        self:CreateNavigationFrame()
    end
    if not navigationFrame then return end

    -- Setup click handler to use hearthstone (item ID 6948)
    navigationFrame.hearthButton:SetScript("OnClick", function()
        -- Find and use hearthstone from bags
        local hearthUsed = false
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local link = GetContainerItemLink(bag, slot)
                if link and string.find(link, "item:6948:") then
                    UseContainerItem(bag, slot)
                    hearthUsed = true
                    break
                end
            end
            if hearthUsed then break end
        end

        -- Schedule step completion after hearthstone cast time (~10s + buffer)
        if hearthUsed then
            navigationFrame.questName:SetText("Hearthing...")
            navigationFrame.distance:SetText("Please wait...")
            GLV.Ace:ScheduleEvent("GLV_HearthstoneComplete", function()
                GuideNavigation:CompleteCurrentStep()
            end, 12)
        end
    end)

    -- Show hearthstone button, hide arrow
    navigationFrame.arrow:Hide()
    navigationFrame.hearthButton:Show()
    navigationFrame.questName:SetText("Hearth to " .. (destination or "Inn"))
    navigationFrame.objective:SetText("")
    navigationFrame.questProgress:SetText("")
    navigationFrame.distance:SetText("Click to use Hearthstone")
    navigationFrame:Show()

    isNavigationActive = false  -- Don't update arrow rotation
end

-- Complete the current step and advance to the next one
function GuideNavigation:CompleteCurrentStep()
    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
    local stepState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepState"}) or {}

    if currentStepIndex <= 0 then return end

    -- Get the original index for this display step
    local origIdx = GLV.CurrentDisplayToOriginal and GLV.CurrentDisplayToOriginal[currentStepIndex]
    if origIdx then
        stepState[origIdx] = true
        GLV.Settings:SetOption(stepState, {"Guide", "Guides", currentGuideId, "StepState"})
    end

    -- Refresh the guide to update UI and advance to next step
    if GLV.RefreshGuide then
        GLV:RefreshGuide()
    end
end

-- Hides hearthstone icon and restores arrow mode
function GuideNavigation:HideHearthstone()
    if not navigationFrame then return end
    navigationFrame.hearthButton:Hide()
    navigationFrame.arrow:Show()
end

-- Updates waypoint for a specific guide step
function GuideNavigation:UpdateWaypointForStep(stepData)
    self:RemoveCurrentWaypoint()
    self:HideEquipItem()
    self:HideNextGuide()
    self:HideHearthstone()

    -- Reset multi-waypoint tracking
    allWaypoints = {}
    currentWaypointIndex = 1
    currentStepData = stepData

    -- Check for EQUIP step
    if stepData and stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.stepType == "EQUIP" and line.equipItemId then
                local itemName = GLV:GetItemNameById(line.equipItemId)
                self:ShowEquipItem(line.equipItemId, itemName)
                return
            end
        end
    end

    -- Check for HEARTHSTONE step
    if stepData and stepData.lines then
        for _, line in ipairs(stepData.lines) do
            if line.stepType == "HEARTHSTONE" and line.hearthDestination then
                self:ShowHearthstone(line.hearthDestination)
                return
            end
        end
    end

    -- Check for NEXT_GUIDE step (last step with clickToNext flag)
    if GLV.CurrentGuide and GLV.CurrentGuide.clickToNext and GLV.CurrentGuide.next then
        local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
        local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
        local totalSteps = GLV.CurrentDisplayStepsCount or 0

        if currentStepIndex == totalSteps then
            self:ShowNextGuide(GLV.CurrentGuide.next)
            return
        end
    end

    -- Get current player position
    playerPos = self:GetPlayerPosition()
    if not playerPos then
        return
    end

    -- Get the current quest action (first uncompleted: QT > QA > QC)
    local currentAction, currentQuestId, actionType, currentObjectiveIndex = self:GetCurrentQuestAction(stepData)

    -- Use the current action's type, or fallback to step's type
    local stepType = actionType or self:GetStepType(stepData)

    -- Store current quest and action type for progress display
    self.currentQuestId = currentQuestId
    self.currentActionType = actionType or stepType
    self.currentObjectiveIndex = currentObjectiveIndex

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Stored: currentQuestId=" .. tostring(self.currentQuestId) .. " currentActionType=" .. tostring(self.currentActionType) .. " objIdx=" .. tostring(currentObjectiveIndex))
    end

    local targetCoords = nil

    -- Priority 1: Explicit GOTO coordinates from lines (highest priority)
    -- These are manually specified [G x,y Zone] coordinates and should NEVER be overridden
    local allCoords = collectAllStepCoordinates(stepData)
    local gotoCoords = {}

    for _, coord in ipairs(allCoords) do
        if coord.type == "goto" then
            table.insert(gotoCoords, coord)
        end
    end

    -- If we have explicit GOTO coords, use them (supporting multiple waypoints)
    if table.getn(gotoCoords) > 0 then
        -- Store all GOTO coords for multi-waypoint navigation
        allWaypoints = gotoCoords
        currentWaypointIndex = 1
        targetCoords = gotoCoords[1]
        local description = self:GetStepDescription(stepData, targetCoords, currentAction)
        self:AddWaypoint(targetCoords, description)
        if GLV.Debug and table.getn(gotoCoords) > 1 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Multi-waypoint: " .. table.getn(gotoCoords) .. " waypoints loaded")
        end
        return
    end

    -- Priority 2: TAR coordinates (also supports multiple)
    if not targetCoords then
        local tarCoords = extractTARCoordinates(stepData)
        if table.getn(tarCoords) > 0 then
            allWaypoints = tarCoords
            currentWaypointIndex = 1
            targetCoords = tarCoords[1]
            if GLV.Debug and table.getn(tarCoords) > 1 then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Multi-waypoint (TAR): " .. table.getn(tarCoords) .. " waypoints loaded")
            end
        end
    end

    -- Priority 3: Quest-specific coordinates for the current action (QT/QA/QC)
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
    if not targetCoords and stepData and stepData.coords and table.getn(stepData.coords) > 0 then
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
        local description = self:GetStepDescription(stepData, targetCoords, currentAction)
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

-- FindClosestUnit moved to DBTools.lua where it belongs


--[[ INITIALIZATION ]]--

-- Initializes the navigation system
function GuideNavigation:Init()
    if not GLV.Settings:GetOption({"Navigation", "AutoShow"}) then
        GLV.Settings:SetOption(true, {"Navigation", "AutoShow"})
    end

    playerPos = self:GetPlayerPosition()
    
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