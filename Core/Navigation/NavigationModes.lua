--[[
Guidelime Vanilla - Navigation Display Modes

Author: Grommey

Description:
Handles all alternative display modes for the navigation frame:
equip item, use item, hearthstone, next guide, XP progress,
and death/corpse navigation.

Split from GuideNavigation.lua for maintainability.
]]--

local GLV = LibStub("GuidelimeVanilla")

local NavigationModes = {}

--[[ STATE VARIABLES ]]--

-- Death/corpse navigation
local savedWaypointState = nil
local corpsePosition = nil
local isDeathNavigation = false

-- Reference to the navigation frame (set by GuideNavigation after creation)
local navFrame = nil

--[[ FRAME REFERENCE ]]--

-- Receives a reference to the navigation frame for UI manipulation
function NavigationModes:SetNavigationFrame(frame)
    navFrame = frame
end

-- Returns the navigation frame reference
function NavigationModes:GetNavigationFrame()
    return navFrame
end

--[[ EQUIP ITEM MODE ]]--

-- Shows item icon for equip steps instead of the arrow
function NavigationModes:ShowEquipItem(itemId, itemName)
    if not navFrame then return end

    -- Get item texture
    local _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    if not itemTexture then
        itemTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    -- Setup icon and click handler
    navFrame.itemIcon:SetTexture(itemTexture)
    navFrame.itemButton:SetScript("OnClick", function()
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
    navFrame.arrow:Hide()
    navFrame.itemButton:Show()
    navFrame.questName:SetText(itemName or "Equip item")
    navFrame.objective:SetText("")
    navFrame.questProgress:SetText("")
    navFrame.distance:SetText("Click to equip")
    navFrame:Show()

    return false  -- isNavigationActive = false (don't update arrow rotation)
end

-- Hides item icon and restores arrow mode
function NavigationModes:HideEquipItem()
    if not navFrame then return end
    navFrame.itemButton:Hide()
    navFrame.arrow:Show()
end

--[[ USE ITEM MODE ]]--

-- Shows use item icon when no navigation coordinates are available (e.g., tram/instance)
function NavigationModes:ShowUseItem(itemId, stepData, currentQuestId)
    if not navFrame then return end

    -- Get item texture
    local _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    if not itemTexture then
        itemTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    -- Setup icon and click handler
    navFrame.itemIcon:SetTexture(itemTexture)
    navFrame.itemButton:SetScript("OnClick", function()
        for bag = 0, 4 do
            local numSlots = GetContainerNumSlots(bag)
            if numSlots then
                for slot = 1, numSlots do
                    local link = GetContainerItemLink(bag, slot)
                    if link and string.find(link, "item:" .. itemId .. ":") then
                        UseContainerItem(bag, slot)
                        return
                    end
                end
            end
        end
    end)

    -- Show item button, hide arrow
    navFrame.arrow:Hide()
    navFrame.itemButton:Show()

    -- Show quest info
    local questName = currentQuestId and GLV:GetQuestNameByID(currentQuestId) or ""
    navFrame.questName:SetText(questName)
    navFrame.questName:SetTextColor(1, 0.8, 0)
    navFrame.objective:SetText("Use item")

    -- Show quest progress
    if currentQuestId and GLV.QuestTracker then
        local objectives, allComplete = GLV.QuestTracker:GetQuestProgress(currentQuestId)
        if objectives and table.getn(objectives) > 0 then
            local progressLines = {}
            for _, obj in ipairs(objectives) do
                local color = obj.completed and "|cFF00FF00" or "|cFFFFFF00"
                table.insert(progressLines, color .. obj.text .. "|r")
            end
            navFrame.questProgress:SetText(table.concat(progressLines, "\n"))
        else
            navFrame.questProgress:SetText("")
        end
    else
        navFrame.questProgress:SetText("")
    end

    navFrame.distance:SetText("Click to use")
    navFrame:Show()

    return true  -- isNavigationActive = true (keep OnUpdate running for progress updates)
end

-- Hides use item icon and restores arrow mode
function NavigationModes:HideUseItem()
    if not navFrame then return end
    navFrame.itemButton:Hide()
    navFrame.arrow:Show()
end

--[[ NEXT GUIDE MODE ]]--

-- Shows the next guide button for the last step
function NavigationModes:ShowNextGuide(nextGuideName)
    if not navFrame then return end

    -- Store next guide content for the click handler
    local nextGuideContent = nextGuideName

    navFrame.nextGuideButton:SetScript("OnClick", function()
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
    navFrame.arrow:Hide()
    navFrame.nextGuideButton:Show()
    navFrame.questName:SetText(nextGuideName or "Next Guide")
    navFrame.objective:SetText("")
    navFrame.questProgress:SetText("")
    navFrame.distance:SetText("Click for next guide")
    navFrame:Show()

    return false  -- isNavigationActive = false (don't update arrow rotation)
end

-- Hides next guide button and restores arrow mode
function NavigationModes:HideNextGuide()
    if not navFrame then return end
    navFrame.nextGuideButton:Hide()
    navFrame.arrow:Show()
end

--[[ HEARTHSTONE MODE ]]--

-- Shows hearthstone icon for [H] steps instead of the arrow
function NavigationModes:ShowHearthstone(destination)
    if not navFrame then return end

    -- Setup click handler to use hearthstone (item ID 6948)
    navFrame.hearthButton:SetScript("OnClick", function()
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
            navFrame.questName:SetText("Hearthing...")
            navFrame.distance:SetText("Please wait...")
            GLV.Ace:ScheduleEvent("GLV_HearthstoneComplete", function()
                GLV.GuideNavigation:CompleteCurrentStep()
            end, 12)
        end
    end)

    -- Show hearthstone button, hide arrow
    navFrame.arrow:Hide()
    navFrame.hearthButton:Show()
    navFrame.questName:SetText("Hearth to " .. (destination or "Inn"))
    navFrame.objective:SetText("")
    navFrame.questProgress:SetText("")
    navFrame.distance:SetText("Click to use Hearthstone")
    navFrame:Show()

    return false  -- isNavigationActive = false (don't update arrow rotation)
end

-- Hides hearthstone icon and restores arrow mode
function NavigationModes:HideHearthstone()
    if not navFrame then return end
    navFrame.hearthButton:Hide()
    navFrame.arrow:Show()
end

--[[ XP PROGRESS MODE ]]--

-- Get XP progress values for the navigation progress bar
-- Returns: current, max, text, isDone
function NavigationModes:GetXPProgressValues(req)
    if not req then return 0, 1, "", false end

    local playerLevel = UnitLevel("player")
    local playerXP = UnitXP("player")
    local playerMaxXP = UnitXPMax("player")

    if req.type == "level" then
        if playerLevel >= req.targetLevel then
            return 1, 1, "Done!", true
        end
        return playerXP, playerMaxXP, playerXP .. " / " .. playerMaxXP .. " XP", false

    elseif req.type == "level_minus" then
        if playerLevel >= req.targetLevel then
            return 1, 1, "Done!", true
        elseif playerLevel == (req.targetLevel - 1) then
            local target = playerMaxXP - req.xpMinus
            if playerXP >= target then
                return 1, 1, "Done!", true
            end
            return playerXP, target, playerXP .. " / " .. target .. " XP", false
        else
            return playerXP, playerMaxXP, "Lvl " .. playerLevel .. " / " .. (req.targetLevel - 1), false
        end

    elseif req.type == "level_plus" then
        if playerLevel > req.targetLevel then
            return 1, 1, "Done!", true
        elseif playerLevel == req.targetLevel then
            if playerXP >= req.xpPlus then
                return 1, 1, "Done!", true
            end
            return playerXP, req.xpPlus, playerXP .. " / " .. req.xpPlus .. " XP", false
        else
            return playerXP, playerMaxXP, "Lvl " .. playerLevel .. " / " .. req.targetLevel, false
        end

    elseif req.type == "level_percent" then
        if playerLevel > req.targetLevel then
            return 1, 1, "Done!", true
        elseif playerLevel == req.targetLevel then
            local targetXP = math.floor((req.targetPercent / 100) * playerMaxXP)
            if playerXP >= targetXP then
                return 1, 1, "Done!", true
            end
            local pct = math.floor((playerXP / targetXP) * 100)
            return playerXP, targetXP, playerXP .. " / " .. targetXP .. " XP (" .. pct .. "%)", false
        else
            return playerXP, playerMaxXP, "Lvl " .. playerLevel .. " / " .. req.targetLevel, false
        end
    end

    return 0, 1, "", false
end

-- Shows XP progress in navigation frame instead of the arrow
function NavigationModes:ShowXPProgress(experienceRequirement)
    if not navFrame then return end

    -- Store requirement for periodic updates
    self.currentXPRequirement = experienceRequirement

    -- Hide arrow, show XP elements
    navFrame.arrow:Hide()
    navFrame.xpBar:Show()
    navFrame.objective:SetText("")
    navFrame.questProgress:SetText("")
    navFrame.distance:SetText("")

    -- Set the requirement text as quest name
    navFrame.questName:SetText("|cFFBB99FF" .. (experienceRequirement.text or "XP Required") .. "|r")
    navFrame.questName:SetTextColor(1, 1, 1)

    -- Update bar values
    self:UpdateXPDisplay()

    navFrame:Show()
    return false  -- isNavigationActive = false (don't update arrow rotation)
end

-- Update XP display values (called when XP changes)
function NavigationModes:UpdateXPDisplay()
    if not navFrame or not self.currentXPRequirement then return end
    if not navFrame.xpBar or not navFrame.xpBar:IsShown() then return end

    local current, max, text, isDone = self:GetXPProgressValues(self.currentXPRequirement)

    navFrame.xpBar:SetMinMaxValues(0, max)
    navFrame.xpBar:SetValue(current)
    navFrame.xpBarText:SetText(text)

    if isDone then
        navFrame.xpBar:SetStatusBarColor(0.0, 0.8, 0.0) -- Green when done
        navFrame.questName:SetText("|cFF00FF00" .. (self.currentXPRequirement.text or "XP") .. " - Done!|r")
    else
        navFrame.xpBar:SetStatusBarColor(0.2, 0.4, 0.9) -- Blue XP color
        navFrame.questName:SetText("|cFFBB99FF" .. (self.currentXPRequirement.text or "XP Required") .. "|r")
    end
end

-- Hides XP progress and restores arrow mode
function NavigationModes:HideXPProgress()
    if not navFrame then return end
    if navFrame.xpBar then
        navFrame.xpBar:Hide()
    end
    navFrame.arrow:Show()
    self.currentXPRequirement = nil
end

--[[ SKILL PROGRESS MODE ]]--

-- Shows skill progress in navigation frame instead of the arrow
function NavigationModes:ShowSkillProgress(skillReq)
    if not navFrame then return end

    -- Store requirement for updates
    self.currentSkillRequirement = skillReq

    -- Hide arrow, show XP bar (reused for skill progress)
    navFrame.arrow:Hide()
    navFrame.xpBar:Show()
    navFrame.objective:SetText("")
    navFrame.questProgress:SetText("")
    navFrame.distance:SetText("")

    -- Set the skill name as quest name
    navFrame.questName:SetText("|c" .. (GLV.Colors["SKILL"] or "FF56c453") .. (skillReq.skillName or "Skill") .. "|r")
    navFrame.questName:SetTextColor(1, 1, 1)

    -- Update bar values
    self:UpdateSkillDisplay()

    navFrame:Show()
    return false  -- isNavigationActive = false (don't update arrow rotation)
end

-- Update skill display values (called when SKILL_LINES_CHANGED fires)
function NavigationModes:UpdateSkillDisplay()
    if not navFrame or not self.currentSkillRequirement then return end
    if not navFrame.xpBar or not navFrame.xpBar:IsShown() then return end

    local skillReq = self.currentSkillRequirement
    local currentLevel = 0
    if GLV.CharacterTracker and GLV.CharacterTracker.GetSkillLevel then
        currentLevel = GLV.CharacterTracker:GetSkillLevel(skillReq.skillName)
    end

    local target = skillReq.requiredLevel or 1
    navFrame.xpBar:SetMinMaxValues(0, target)
    navFrame.xpBar:SetValue(math.min(currentLevel, target))

    if currentLevel >= target then
        navFrame.xpBar:SetStatusBarColor(0.0, 0.8, 0.0)  -- Green when done
        navFrame.xpBarText:SetText("Done!")
        navFrame.questName:SetText("|cFF00FF00" .. (skillReq.skillName or "Skill") .. " - Done!|r")
    else
        navFrame.xpBar:SetStatusBarColor(0.33, 0.77, 0.33)  -- Skill green color
        navFrame.xpBarText:SetText(currentLevel .. " / " .. target)
    end
end

-- Hides skill progress and restores arrow mode
function NavigationModes:HideSkillProgress()
    if not navFrame then return end
    if navFrame.xpBar then
        navFrame.xpBar:Hide()
    end
    navFrame.arrow:Show()
    self.currentSkillRequirement = nil
end

--[[ DEATH / CORPSE NAVIGATION ]]--

-- Returns whether death navigation is currently active
function NavigationModes:IsDeathNavigationActive()
    return isDeathNavigation
end

-- Returns the current corpse position (for external access)
function NavigationModes:GetCorpsePosition()
    return corpsePosition
end

-- Activates corpse navigation mode (common helper for OnPlayerDead and Init reconnect)
function NavigationModes:ActivateCorpseNavigation()
    if not corpsePosition then return end
    if not navFrame then return end

    local GuideNavigation = GLV.GuideNavigation

    isDeathNavigation = true

    -- Hide all special modes
    self:HideEquipItem()
    self:HideUseItem()
    self:HideNextGuide()
    self:HideHearthstone()
    self:HideXPProgress()
    self:HideSkillProgress()

    -- Clear quest tracking so objectives don't display during death
    GuideNavigation.currentQuestId = nil
    GuideNavigation.currentActionType = nil
    GuideNavigation.currentObjectiveIndex = nil

    -- Set waypoint directly using saved corpse position (already in Astrolabe format)
    -- We need to set the waypoint through GuideNavigation since it owns currentWaypoint
    GuideNavigation:SetDeathWaypoint({
        c = corpsePosition[1],
        z = corpsePosition[2],
        x = corpsePosition[3],
        y = corpsePosition[4],
        description = "Your dead body"
    })

    -- Apply ghostly blue tint to arrow
    navFrame.arrow:Show()
    navFrame.arrow:SetVertexColor(0.7, 0.7, 0.9, 0.8)

    -- Show navigation frame
    navFrame.questName:SetText("")
    navFrame.objective:SetText("Your dead body")
    navFrame.objective:SetTextColor(0.7, 0.7, 0.9)
    navFrame.questProgress:SetText("")
    navFrame:Show()

    -- Signal GuideNavigation to activate
    GuideNavigation:SetNavigationActive(true)

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Death navigation activated - guiding to corpse")
    end
end

-- Called when the player dies
function NavigationModes:OnPlayerDead()
    local GuideNavigation = GLV.GuideNavigation

    -- Capture player position (this IS the corpse position at the moment of death)
    local pos = GuideNavigation:GetPlayerPosition()
    if not pos or not pos.c then return end

    -- Save corpse position as array {c, z, x, y}
    corpsePosition = {pos.c, pos.z, pos.x, pos.y}

    -- Persist corpse position to settings (survives disconnect)
    GLV.Settings:SetOption(corpsePosition, {"Navigation", "CorpsePosition"})

    -- Save current navigation state for restoration after resurrection
    savedWaypointState = GuideNavigation:SaveNavigationState()

    self:ActivateCorpseNavigation()
end

-- Called when the player resurrects (PLAYER_ALIVE or PLAYER_UNGHOST)
function NavigationModes:OnPlayerAlive()
    if not isDeathNavigation then return end

    local GuideNavigation = GLV.GuideNavigation

    isDeathNavigation = false
    corpsePosition = nil

    -- Clear persisted corpse position
    GLV.Settings:SetOption(nil, {"Navigation", "CorpsePosition"})

    -- Restore arrow to normal color
    if navFrame and navFrame.arrow then
        navFrame.arrow:SetVertexColor(1, 1, 1, 1)
    end
    if navFrame and navFrame.objective then
        navFrame.objective:SetTextColor(1, 1, 1)
    end

    savedWaypointState = nil

    -- Schedule recalculation after resurrection.
    -- Astrolabe needs SetMapToCurrentZone() to return correct zone data,
    -- and the game needs a moment to update the player's position/zone state.
    GLV.Ace:ScheduleEvent("GLV_PostResurrection", function()
        if not WorldMapFrame:IsVisible() then
            SetMapToCurrentZone()
        end
        GuideNavigation:RecalculateFromCurrentStep()
    end, 0.5)

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Nav]|r Player resurrected - navigation will restore in 0.5s")
    end
end

-- Register PLAYER_DEAD and PLAYER_UNGHOST events
function NavigationModes:RegisterDeathEvents()
    GLV.Ace:RegisterEvent("PLAYER_DEAD", function()
        NavigationModes:OnPlayerDead()
    end)
    GLV.Ace:RegisterEvent("PLAYER_UNGHOST", function()
        NavigationModes:OnPlayerAlive()
    end)
end

-- Check for ghost state on init (disconnected while dead)
function NavigationModes:CheckGhostState()
    if UnitIsGhost("player") then
        local savedCorpse = GLV.Settings:GetOption({"Navigation", "CorpsePosition"})
        if savedCorpse then
            corpsePosition = savedCorpse
            self:ActivateCorpseNavigation()
            self:RegisterDeathEvents()
            return true  -- Signal to skip normal init
        end
    end
    return false
end

-- Expose to GLV
GLV.NavigationModes = NavigationModes
