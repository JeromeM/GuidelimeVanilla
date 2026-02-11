--[[
Guidelime Vanilla - Navigation System (Orchestrator)

Author: Grommey

Description:
Autonomous navigation system with custom arrow display.
Orchestrates NavigationModes (display modes, death nav) and
WaypointResolver (coordinate resolution) modules.

No longer depends on TomTom addon.

A lot of this code has been copied from TomTom, pfQuest !
Thanks to the authors of these addons !
]]--

local GLV = LibStub("GuidelimeVanilla")

local GuideNavigation = {}

-- Module references (loaded earlier in TOC, already available)
local NavigationModes = GLV.NavigationModes
local WaypointResolver = GLV.WaypointResolver

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
local hasTriggeredTransition = false  -- Prevent multiple recalculations


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

    -- XP Progress StatusBar (initially hidden)
    navigationFrame.xpBar = CreateFrame("StatusBar", "GLV_NavXPBar", navigationFrame)
    navigationFrame.xpBar:SetWidth(160)
    navigationFrame.xpBar:SetHeight(14)
    navigationFrame.xpBar:SetPoint("TOP", navigationFrame.questName, "BOTTOM", 0, -5)
    navigationFrame.xpBar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 4,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    navigationFrame.xpBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    navigationFrame.xpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    navigationFrame.xpBar:SetStatusBarColor(0.58, 0.0, 0.82)
    navigationFrame.xpBar:SetMinMaxValues(0, 100)
    navigationFrame.xpBar:SetValue(0)
    navigationFrame.xpBar:Hide()

    -- XP bar text overlay
    navigationFrame.xpBarText = navigationFrame.xpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navigationFrame.xpBarText:SetPoint("CENTER", navigationFrame.xpBar)
    navigationFrame.xpBarText:SetTextColor(1, 1, 1)
    navigationFrame.xpBarText:SetText("")

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

    -- Pass the frame reference to NavigationModes
    NavigationModes:SetNavigationFrame(navigationFrame)
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
    local cont, zone = WaypointResolver:GetZoneInfo(zoneName)

    currentWaypoint = {
        c = cont,
        x = coords.x / 100,
        y = coords.y / 100,
        z = zone,  -- May be nil if GetZoneInfo failed
        zoneName = zoneName,  -- Store zone name for later lookup
        zoneId = coords.z,  -- Store database zone ID
        description = description or "Guide Objective",
        -- Copy waypoint metadata for navigation logic
        type = coords.type,
        npcId = coords.npcId,
        questId = coords.questId,
        actionType = coords.actionType
    }

    return true
end

-- Sets a waypoint directly (already in Astrolabe format, used by death navigation)
function GuideNavigation:SetDeathWaypoint(waypointData)
    currentWaypoint = waypointData
end

-- Clears the current waypoint
function GuideNavigation:ClearWaypoint()
    currentWaypoint = nil
end

-- Returns whether the arrow navigation is actively running
function GuideNavigation:IsArrowNavigationActive()
    return isNavigationActive
end

-- Returns the current waypoint (for debugging and MinimapPath)
function GuideNavigation:GetCurrentWaypoint()
    return currentWaypoint
end

-- Sets isNavigationActive (used by NavigationModes)
function GuideNavigation:SetNavigationActive(active)
    isNavigationActive = active
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

-- Removes current waypoint and hides all special modes
function GuideNavigation:RemoveCurrentWaypoint()
    self:ClearAllWaypoints()
    NavigationModes:HideEquipItem()
    NavigationModes:HideUseItem()
    NavigationModes:HideHearthstone()
    NavigationModes:HideXPProgress()
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
        if navigationFrame.xpBar then
            navigationFrame.xpBar:Hide()
        end
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

--[[ NAVIGATION STATE SAVE/RESTORE (for death navigation) ]]--

-- Saves the current navigation state for later restoration
function GuideNavigation:SaveNavigationState()
    return {
        currentWaypoint = currentWaypoint,
        isNavigationActive = isNavigationActive,
        allWaypoints = allWaypoints,
        currentWaypointIndex = currentWaypointIndex,
        currentStepData = currentStepData,
        currentQuestId = self.currentQuestId,
        currentActionType = self.currentActionType,
        currentObjectiveIndex = self.currentObjectiveIndex,
        currentUseItemId = self.currentUseItemId,
        currentXPRequirement = NavigationModes.currentXPRequirement
    }
end

-- Restores a previously saved navigation state
function GuideNavigation:RestoreNavigationState(state)
    currentWaypoint = state.currentWaypoint
    allWaypoints = state.allWaypoints or {}
    currentWaypointIndex = state.currentWaypointIndex or 1
    currentStepData = state.currentStepData
    self.currentQuestId = state.currentQuestId
    self.currentActionType = state.currentActionType
    self.currentObjectiveIndex = state.currentObjectiveIndex
    self.currentUseItemId = state.currentUseItemId

    if state.isNavigationActive and currentWaypoint then
        -- Navigation was active before death, restore it
        navigationFrame:Show()
        isNavigationActive = true
    else
        -- Navigation was hidden before death
        self:Hide()
    end
end

-- Recalculates navigation from the current step (fallback when no saved state)
function GuideNavigation:RecalculateFromCurrentStep()
    if currentStepData then
        self:UpdateWaypointForStep(currentStepData)
    else
        self:Hide()
    end
end

--[[ UPDATE AND DISPLAY FUNCTIONS ]]--

-- Updates the navigation display
function GuideNavigation:UpdateNavigation()
    if not navigationFrame or not isNavigationActive then
        return
    end

    -- Use item fallback mode (no waypoint) - periodically refresh quest progress
    if not currentWaypoint then
        if self.currentUseItemId and self.currentQuestId and GLV.QuestTracker then
            self.useItemProgressTimer = (self.useItemProgressTimer or 0) + UPDATE_FREQUENCY
            if self.useItemProgressTimer >= 1.0 then
                self.useItemProgressTimer = 0
                local objectives = GLV.QuestTracker:GetQuestProgress(self.currentQuestId)
                if objectives and table.getn(objectives) > 0 then
                    local progressLines = {}
                    for _, obj in ipairs(objectives) do
                        local color = obj.completed and "|cFF00FF00" or "|cFFFFFF00"
                        table.insert(progressLines, color .. obj.text .. "|r")
                    end
                    navigationFrame.questProgress:SetText(table.concat(progressLines, "\n"))
                end
            end
        end
        return
    end

    playerPos = self:GetPlayerPosition()
    if not playerPos then
        return
    end

    -- If zone wasn't resolved earlier, try again now
    if not currentWaypoint.z and currentWaypoint.zoneName then
        local cont, zone = WaypointResolver:GetZoneInfo(currentWaypoint.zoneName)
        if zone then
            currentWaypoint.c = cont
            currentWaypoint.z = zone
        else
            -- Fallback: if player is currently in the waypoint's zone, inherit their Astrolabe IDs
            local currentZoneName = GetZoneText()
            if currentZoneName and string.lower(currentZoneName) == string.lower(currentWaypoint.zoneName) then
                currentWaypoint.c = playerPos.c
                currentWaypoint.z = playerPos.z
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Navigation]|r Zone resolved via player position: " .. currentWaypoint.zoneName)
                end
            elseif GLV.Debug and not currentWaypoint._debugZoneWarned then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[Navigation]|r Cannot resolve zone: " .. tostring(currentWaypoint.zoneName) .. " (will retry when player enters zone)")
                currentWaypoint._debugZoneWarned = true
            end
        end
    end

    local isZoneMismatch = not currentWaypoint.z or playerPos.z ~= currentWaypoint.z

    if isZoneMismatch then
        if currentWaypoint.type == "goto" then
            -- GOTO waypoints: don't fallback to use-item, just hide until player enters the zone
            navigationFrame:Hide()
            return
        elseif self.currentUseItemId then
            -- Show use item icon as fallback when arrow not available (e.g., in tram/instance)
            local _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(self.currentUseItemId)
            navigationFrame.itemIcon:SetTexture(itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
            navigationFrame.arrow:Hide()
            navigationFrame.itemButton:Show()

            -- Set click handler for using the item
            local useItemId = self.currentUseItemId
            navigationFrame.itemButton:SetScript("OnClick", function()
                for bag = 0, 4 do
                    local numSlots = GetContainerNumSlots(bag)
                    if numSlots then
                        for slot = 1, numSlots do
                            local link = GetContainerItemLink(bag, slot)
                            if link and string.find(link, "item:" .. useItemId .. ":") then
                                UseContainerItem(bag, slot)
                                return
                            end
                        end
                    end
                end
            end)
            navigationFrame.itemButton:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
                GameTooltip:SetText("Click to use item")
                GameTooltip:Show()
            end)

            if not navigationFrame:IsVisible() then
                navigationFrame:Show()
            end
        else
            -- No fallback available, hide navigation
            navigationFrame:Hide()
            return
        end
    else
        -- Same zone - restore arrow if item button was shown as fallback
        if navigationFrame.itemButton:IsShown() then
            navigationFrame.itemButton:Hide()
            navigationFrame.arrow:Show()
        end

        if not navigationFrame:IsVisible() then
            navigationFrame:Show()
        end
    end

    if currentWaypoint.description then
        local description = currentWaypoint.description
        if string.find(description, " | ") then
            local color_rgb = {}
            local part1, part2, part3 = strsplit(" | ", description, 3)

            -- Check if first part contains a level bracket [XX]
            if string.find(part1, "%[%d+%]") then
                -- Format: [level] | quest name | objective (3 parts with level)
                local questLevel = part1
                questLevel = string.gsub(questLevel, "%[(.-)%]", function(lvl)
                    local playerLevel = UnitLevel("player")
                    local diff = tonumber(lvl) - playerLevel

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

                    return "[" .. lvl .. "]"
                end)
                navigationFrame.questName:SetText(questLevel .. " " .. (part2 or ""))
                navigationFrame.questName:SetTextColor(color_rgb.r, color_rgb.g, color_rgb.b, 1)
                navigationFrame.objective:SetText(part3 or "")
            else
                -- Format: quest name | objective (2 parts without level)
                navigationFrame.questName:SetText(part1 or "")
                navigationFrame.questName:SetTextColor(1, 0.8, 0)  -- Default gold color
                navigationFrame.objective:SetText(part2 or "")
            end
        else
            navigationFrame.questName:SetText("")
            navigationFrame.objective:SetText(description)
        end
    else
        navigationFrame.questName:SetText("")
        navigationFrame.objective:SetText("Guide Objective")
    end

    -- Display quest progress objectives (only for COMPLETE actions, not for TAR/QT/QA)
    local showProgress = self.currentQuestId and self.currentActionType == "COMPLETE"
    -- Don't show progress when navigating to a standalone TAR (type == "target" without quest)
    if currentWaypoint.type == "target" and not currentWaypoint.questId then
        showProgress = false
    end
    if showProgress and GLV.QuestTracker then
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

    -- Skip distance/arrow calculations when in different zone (fallback mode)
    if isZoneMismatch then
        navigationFrame.distance:SetText("")
        return
    end

    local distance, xDelta, yDelta = self:CalculateDistance(playerPos, currentWaypoint)

    local distanceText = self:FormatDistance(distance)
    navigationFrame.distance:SetText("Distance: " .. distanceText)

    local r, g, b = self:GetDistanceColor(distance)
    if NavigationModes:IsDeathNavigationActive() then
        navigationFrame.arrow:SetVertexColor(0.7, 0.7, 0.9, 0.8)
    else
        navigationFrame.arrow:SetVertexColor(r, g, b, 1)
    end

    if distance < WAYPOINT_REACH_DISTANCE then
        navigationFrame.distance:SetTextColor(0, 1, 0)
        navigationFrame.arrow:SetAlpha(0.5)

        -- Only process waypoint arrival once
        if not hasTriggeredTransition then
            -- Mark current waypoint's NPC as visited (persistent)
            if currentWaypoint.npcId then
                WaypointResolver:SaveVisitedNPC(currentWaypoint.npcId)
            end

            -- Check if there's a next waypoint to advance to
            if table.getn(allWaypoints) > currentWaypointIndex then
                -- After reaching GOTO, show use-item if step has one
                if currentWaypoint.type == "goto" and self.currentUseItemId and not self.useItemShownAfterGoto then
                    self.useItemShownAfterGoto = true
                    hasTriggeredTransition = true
                    self:ClearWaypoint()
                    local navResult = NavigationModes:ShowUseItem(self.currentUseItemId, currentStepData, self.currentQuestId)
                    if navResult ~= nil then isNavigationActive = navResult end
                    self.useItemProgressTimer = 0
                    -- Override click handler: use item then advance to next waypoints
                    local useItemId = self.currentUseItemId
                    local nav = self
                    navigationFrame.itemButton:SetScript("OnClick", function()
                        -- Use the item
                        for bag = 0, 4 do
                            local numSlots = GetContainerNumSlots(bag)
                            if numSlots then
                                for slot = 1, numSlots do
                                    local link = GetContainerItemLink(bag, slot)
                                    if link and string.find(link, "item:" .. useItemId .. ":") then
                                        UseContainerItem(bag, slot)
                                        break
                                    end
                                end
                            end
                        end
                        -- Advance to next waypoints (skip GOTO coords)
                        nav:UpdateWaypointForStep(currentStepData)
                    end)
                    if GLV.Debug then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r GOTO reached, showing USE_ITEM " .. tostring(self.currentUseItemId) .. " before next waypoint")
                    end
                else
                    currentWaypointIndex = currentWaypointIndex + 1
                    local nextCoords = allWaypoints[currentWaypointIndex]
                    if nextCoords then
                        -- Use pre-computed description from waypoint if available
                        local description = nextCoords.description or WaypointResolver:GetStepDescription(currentStepData, nextCoords, nil)
                        self:SetWaypoint(nextCoords, description)
                        hasTriggeredTransition = false  -- Reset for next waypoint
                        if GLV.Debug then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Advanced to waypoint " .. currentWaypointIndex .. "/" .. table.getn(allWaypoints) .. ": " .. (description or "no desc"))
                        end
                    end
                end
            elseif currentWaypoint.type == "target" then
                -- Reached last ordered waypoint (TAR) - recalculate to find QC/other objectives
                hasTriggeredTransition = true  -- Prevent repeated recalculations
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r TAR " .. tostring(currentWaypoint.npcId) .. " reached, recalculating...")
                end
                self:UpdateWaypointForStep(currentStepData)
            end
        end
    else
        -- Reset transition flag when moving away from waypoint
        hasTriggeredTransition = false
        navigationFrame.distance:SetTextColor(0.8, 0.8, 0.8)
        navigationFrame.arrow:SetAlpha(1.0)
    end

    if not currentWaypoint then return end

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

--[[ STEP COMPLETION ]]--

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

--[[ AUTO-SKIP IMPOSSIBLE TURNINS ]]--

-- Auto-skip steps where [QT] quest is not in the player's log
-- Marks impossible QT actions as done. If all actions are fulfilled, completes the step.
-- Returns true if the step was auto-completed (caller should return early).
function GuideNavigation:CheckAutoSkipTurnins(stepData)
    if not stepData or not stepData.questTags or table.getn(stepData.questTags) == 0 then
        return false
    end

    -- Check if any QT tag has a quest not in the player's log
    local hasImpossibleTurnin = false
    for _, questTag in ipairs(stepData.questTags) do
        if questTag.tag == "TURNIN" then
            local inLog, isComplete = WaypointResolver:GetQuestStatus(questTag.questId)
            if not inLog then
                hasImpossibleTurnin = true
                break
            end
        end
    end

    if not hasImpossibleTurnin then
        return false
    end

    -- Get current step state
    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
    if currentStepIndex <= 0 then return false end

    local origIdx = GLV.CurrentDisplayToOriginal and GLV.CurrentDisplayToOriginal[currentStepIndex]
    if not origIdx then return false end

    local stepState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepState"}) or {}
    if stepState[origIdx] then return false end  -- Already completed

    local stepQuestState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepQuestState"}) or {}
    if not stepQuestState[origIdx] then
        stepQuestState[origIdx] = {}
    end

    -- Mark impossible QT actions as done
    for _, questTag in ipairs(stepData.questTags) do
        if questTag.tag == "TURNIN" then
            local inLog, isComplete = WaypointResolver:GetQuestStatus(questTag.questId)
            if not inLog then
                stepQuestState[origIdx][GLV.BuildActionKey(questTag)] = true
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Auto-skip QT" .. tostring(questTag.questId) .. ": quest not in log")
                end
            end
        end
    end

    GLV.Settings:SetOption(stepQuestState, {"Guide", "Guides", currentGuideId, "StepQuestState"})

    -- Check if ALL quest actions on this step are now fulfilled
    local allDone = true
    for _, questTag in ipairs(stepData.questTags) do
        if not stepQuestState[origIdx][GLV.BuildActionKey(questTag)] then
            allDone = false
            break
        end
    end

    if allDone then
        stepState[origIdx] = true
        GLV.Settings:SetOption(stepState, {"Guide", "Guides", currentGuideId, "StepState"})

        DEFAULT_CHAT_FRAME:AddMessage("|cFF6B8BD4[GuideLime]|r Auto-skipped step " .. currentStepIndex .. ": turn-in quest not in log")

        if GLV.RefreshGuide then
            GLV:RefreshGuide()
        end
        return true
    end

    return false
end

--[[ WAYPOINT RESOLUTION AND STEP HANDLING ]]--

-- Updates waypoint for a specific guide step (orchestrator)
function GuideNavigation:UpdateWaypointForStep(stepData)
    -- Don't let guide step changes override corpse navigation while dead
    if NavigationModes:IsDeathNavigationActive() then return end

    -- Auto-skip QT steps where quest is not in player's log
    if self:CheckAutoSkipTurnins(stepData) then
        return  -- Step was auto-completed, RefreshGuide will handle next step
    end

    self:RemoveCurrentWaypoint()
    NavigationModes:HideNextGuide()

    -- Reset transition flag to allow new transitions
    hasTriggeredTransition = false

    -- If use-item was shown after GOTO, skip to remaining waypoints on recalculation
    local skipToOrderedWaypoints = self.useItemShownAfterGoto

    -- Reset multi-waypoint tracking
    allWaypoints = {}
    currentWaypointIndex = 1
    currentStepData = stepData
    self.useItemShownAfterGoto = nil

    -- Resolve waypoints using WaypointResolver
    local result = WaypointResolver:ResolveWaypoints(stepData)

    if GLV.Debug then
        local wpCount = result.waypoints and table.getn(result.waypoints) or 0
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r ResolveWaypoints: mode=" .. tostring(result.specialMode) .. " waypoints=" .. wpCount .. " questId=" .. tostring(result.questId) .. " action=" .. tostring(result.actionType))
    end

    -- Store quest tracking info
    self.currentQuestId = result.questId
    self.currentActionType = result.actionType
    self.currentObjectiveIndex = result.objectiveIndex
    self.currentUseItemId = result.useItemId

    -- Handle special modes
    if result.specialMode == "XP" then
        local navResult = NavigationModes:ShowXPProgress(result.specialModeData)
        if navResult == false then isNavigationActive = false end
        return
    elseif result.specialMode == "EQUIP" then
        local navResult = NavigationModes:ShowEquipItem(result.specialModeData.itemId, result.specialModeData.itemName)
        if navResult == false then isNavigationActive = false end
        return
    elseif result.specialMode == "HEARTHSTONE" then
        local navResult = NavigationModes:ShowHearthstone(result.specialModeData)
        if navResult == false then isNavigationActive = false end
        return
    elseif result.specialMode == "NEXT_GUIDE" then
        local navResult = NavigationModes:ShowNextGuide(result.specialModeData)
        if navResult == false then isNavigationActive = false end
        return
    elseif result.specialMode == "USE_ITEM" then
        local navResult = NavigationModes:ShowUseItem(result.specialModeData.itemId, stepData, self.currentQuestId)
        if navResult ~= nil then isNavigationActive = navResult end
        self.useItemProgressTimer = 0
        return
    end

    -- Normal arrow navigation
    if result.waypoints and table.getn(result.waypoints) > 0 then
        allWaypoints = result.waypoints
        currentWaypointIndex = 1

        -- After use-item was shown, skip past GOTO coords to ordered waypoints
        if skipToOrderedWaypoints then
            for i, wp in ipairs(result.waypoints) do
                if wp.type ~= "goto" then
                    currentWaypointIndex = i
                    break
                end
            end
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Post-useItem: skipping to waypoint " .. currentWaypointIndex .. "/" .. table.getn(allWaypoints))
            end
        end

        local wp = result.waypoints[currentWaypointIndex]
        local description = (currentWaypointIndex == 1 and result.description) or WaypointResolver:GetStepDescription(stepData, wp, nil)
        self:AddWaypoint(wp, description)
    end
end

-- Handles step changes in the guide
function GuideNavigation:OnStepChanged(stepData)
    self:UpdateWaypointForStep(stepData)
end

--[[ DELEGATE METHODS (external API compatibility) ]]--

-- These methods delegate to sub-modules but keep the external API stable
-- so callers like Character.lua, Frames.lua, etc. don't need to change.

function GuideNavigation:GetQuestStatus(questId)
    return WaypointResolver:GetQuestStatus(questId)
end

function GuideNavigation:GetStepDescription(stepData, targetCoords, currentAction)
    return WaypointResolver:GetStepDescription(stepData, targetCoords, currentAction)
end

function GuideNavigation:GetZoneInfo(zone, cont)
    return WaypointResolver:GetZoneInfo(zone, cont)
end

function GuideNavigation:IsDeathNavigationActive()
    return NavigationModes:IsDeathNavigationActive()
end

function GuideNavigation:HideNextGuide()
    NavigationModes:HideNextGuide()
end

function GuideNavigation:UpdateXPDisplay()
    NavigationModes:UpdateXPDisplay()
end

function GuideNavigation:ShowXPProgress(req)
    local navResult = NavigationModes:ShowXPProgress(req)
    if navResult == false then isNavigationActive = false end
end

function GuideNavigation:HideXPProgress()
    NavigationModes:HideXPProgress()
end

--[[ INITIALIZATION ]]--

-- Initializes the navigation system
function GuideNavigation:Init()
    if not GLV.Settings:GetOption({"Navigation", "AutoShow"}) then
        GLV.Settings:SetOption(true, {"Navigation", "AutoShow"})
    end

    playerPos = self:GetPlayerPosition()

    -- Create the navigation frame early so NavigationModes can use it
    self:CreateNavigationFrame()

    -- Check if player is a ghost at login (disconnected while dead)
    if NavigationModes:CheckGhostState() then
        return  -- Skip normal guide nav init
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

    -- Register death/resurrection events
    NavigationModes:RegisterDeathEvents()
end

-- Expose to GLV
GLV.GuideNavigation = GuideNavigation
