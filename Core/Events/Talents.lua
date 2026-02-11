--[[
Guidelime Vanilla

Author: Grommey

Description:
Talent suggestion system with level-up popup and talent frame highlighting
]]--

local GLV = LibStub("GuidelimeVanilla")

local TalentTracker = {}
GLV.TalentTracker = TalentTracker

-- Storage for registered talent templates
GLV.TalentTemplates = {}  -- {class = {templateName = {type, talents}}}

-- Known talent frame variants (add new custom frames here)
local TALENT_FRAMES = {
    { frame = "TalentFrame",       tab = "TalentFrameTab",       button = "TalentFrameTalent" },
    { frame = "TWTalentFrame",     tab = "TWTalentFrameTab",     button = "TWTalentFrameTalent" },
    { frame = "PlayerTalentFrame", tab = "PlayerTalentFrameTab", button = "PlayerTalentFrameTalent" },
}

-- Default recommended templates per class
-- TODO: Fill when TurtleWoW templates are ready
GLV.DefaultTalentTemplates = {
    -- ["WARRIOR"] = "Arms",
    -- ["PALADIN"] = "Retribution",
    -- ["HUNTER"] = "Beast Mastery",
    -- ["ROGUE"] = "Combat Swords",
    -- ["PRIEST"] = "Shadow",
    -- ["SHAMAN"] = "Enhancement",
    -- ["MAGE"] = "Frost",
    -- ["WARLOCK"] = "Affliction",
    -- ["DRUID"] = "Feral",
}


--[[ TEMPLATE REGISTRATION API ]]--

-- Register a talent template for a class
-- class: "Mage", "Warrior", etc.
-- name: "Frost Leveling", "Fire Raiding"
-- templateType: "leveling" or "endgame"
-- talents: table {[level] = {tree, row, col}}
-- respec: optional table {respecAt = level, message = "string", talents = {[level] = {tree, row, col}}}
function GLV:RegisterTalentTemplate(class, name, templateType, talents, respec)
    if not class or not name or not talents then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r Invalid template registration: missing parameters")
        end
        return
    end

    if not self.TalentTemplates[class] then
        self.TalentTemplates[class] = {}
    end

    self.TalentTemplates[class][name] = {
        type = templateType or "leveling",
        talents = talents,
        respec = respec
    }

    if GLV.Debug then
        local respecInfo = respec and (" (respec at " .. respec.respecAt .. ")") or ""
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Talents]|r Registered template: " .. class .. " - " .. name .. respecInfo)
    end
end

-- Get all templates for a class, optionally filtered by type
function GLV:GetTalentTemplates(class, filterType)
    if not class or not self.TalentTemplates[class] then
        return {}
    end

    if not filterType then
        return self.TalentTemplates[class]
    end

    local filtered = {}
    for name, data in pairs(self.TalentTemplates[class]) do
        if data.type == filterType then
            filtered[name] = data
        end
    end
    return filtered
end

-- Get template names for dropdown
function GLV:GetTalentTemplateNames(class, filterType)
    local templates = self:GetTalentTemplates(class, filterType)
    local names = {}
    for name, _ in pairs(templates) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Get the correct talents table for a template, considering respec state
-- Returns phase 2 talents if respec is done, otherwise phase 1
function GLV:GetTemplateTalents(template, class)
    if not template then return nil end
    if template.respec and self.Settings:GetOption({"Talents", "RespecDone", class}) then
        return template.respec.talents
    end
    return template.talents
end

-- Get the active template for a class, with fallback to default
function GLV:GetActiveTemplate(class)
    -- First check if user has selected a template
    local templateName = self.Settings:GetOption({"Talents", "ActiveTemplate", class})

    -- If not, use the default recommendation
    if not templateName and self.DefaultTalentTemplates then
        templateName = self.DefaultTalentTemplates[class]
        -- Auto-save the default as active
        if templateName then
            self.Settings:SetOption(templateName, {"Talents", "ActiveTemplate", class})
        end
    end

    return templateName
end


--[[ TALENT INFO HELPERS ]]--

-- Get talent name and icon by tree/row/col position
function GLV:GetTalentNameByPosition(tree, row, col)
    local numTalents = GetNumTalents(tree)
    if not numTalents then return nil end

    for i = 1, numTalents do
        local name, iconTexture, tier, column, rank, maxRank = GetTalentInfo(tree, i)
        if tier == row and column == col then
            return name, iconTexture, maxRank, rank
        end
    end
    return nil
end

-- Get talent tree name by index
function GLV:GetTalentTreeName(treeIndex)
    local name, iconTexture, pointsSpent = GetTalentTabInfo(treeIndex)
    return name
end


--[[ TALENT TRACKER ]]--

-- Initialize talent tracking
function TalentTracker:Init()
    if not GLV.Ace then return end

    -- Register level up event
    GLV.Ace:RegisterEvent("PLAYER_LEVEL_UP", function(newLevel)
        self:OnLevelUp(newLevel)
    end)

    -- Hook talent frame when it opens
    self:HookTalentFrame()

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r TalentTracker initialized")
    end
end


--[[ LEVEL UP EVENT ]]--

-- Handle level up event
function TalentTracker:OnLevelUp(newLevel)
    -- Check if feature is enabled
    if not GLV.Settings:GetOption({"Talents", "Enabled"}) then return end
    if not GLV.Settings:GetOption({"Talents", "ShowPopupOnLevelUp"}) then return end
    if newLevel < 10 then return end  -- No talents before level 10

    local _, playerClass = UnitClass("player")
    local templateName = GLV:GetActiveTemplate(playerClass)

    if not templateName then return end

    local template = GLV.TalentTemplates[playerClass] and GLV.TalentTemplates[playerClass][templateName]
    if not template then return end

    -- Check for respec transition
    if template.respec and not GLV.Settings:GetOption({"Talents", "RespecDone", playerClass}) then
        if newLevel >= template.respec.respecAt then
            -- Mark respec as done
            GLV.Settings:SetOption(true, {"Talents", "RespecDone", playerClass})

            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Respec transition at level " .. newLevel .. " for " .. playerClass)
            end

            -- Show respec message toast
            local message = template.respec.message or "Reset your talents at a class trainer!"
            GLV.Ace:ScheduleEvent("GLV_TalentPopup", function()
                self:ShowTalentToast(nil, nil, nil, message)
            end, 0.5)

            -- Refresh highlights if talent frame is open
            local visibleFrame = self:GetVisibleTalentFrame()
            if visibleFrame then
                GLV.Ace:ScheduleEvent("GLV_UpdateHighlightsOnRespec", function()
                    self:UpdateTalentHighlights()
                end, 0.6)
            end
            return
        end
    end

    -- Normal talent suggestion
    local talents = GLV:GetTemplateTalents(template, playerClass)
    if not talents then return end

    local suggestion = talents[newLevel]
    if not suggestion then return end

    local tree, row, col = suggestion[1], suggestion[2], suggestion[3]

    -- Delay to ensure talent info is available
    GLV.Ace:ScheduleEvent("GLV_TalentPopup", function()
        local talentName, talentIcon = GLV:GetTalentNameByPosition(tree, row, col)
        if talentName then
            self:ShowTalentToast(talentName, talentIcon, tree)
        end
    end, 0.5)
end


--[[ TOAST NOTIFICATION ]]--

-- Toast animation state
TalentTracker.toastState = {
    alpha = 0,
    phase = "none",  -- "none", "fadein", "visible", "fadeout"
    elapsed = 0,
}

-- Toast timing constants
local TOAST_FADE_IN_TIME = 0.3
local TOAST_VISIBLE_TIME = 4.0
local TOAST_FADE_OUT_TIME = 0.5

-- Show talent suggestion toast with fade animation
-- customMessage: optional string to show as a standalone message (no icon, gold text)
function TalentTracker:ShowTalentToast(talentName, talentIcon, treeIndex, customMessage)
    local toast = getglobal("GLV_TalentToast")
    if not toast then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r Toast frame not found")
        end
        return
    end

    local iconFrame = getglobal("GLV_TalentToastIcon")
    local toastText = getglobal("GLV_TalentToastText")
    local messageText = getglobal("GLV_TalentToastMessage")

    if customMessage then
        -- Message-only mode (respec notification)
        self.toastVisibleOverride = 6.0

        if iconFrame then iconFrame:Hide() end
        if toastText then toastText:Hide() end

        if messageText then
            messageText:SetText("|cFFFFD100" .. customMessage .. "|r")
            messageText:ClearAllPoints()
            messageText:SetPoint("CENTER", toast, "CENTER", 0, 0)
            messageText:Show()
        end

        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Showing respec toast: " .. customMessage)
        end
    else
        -- Normal talent mode
        self.toastVisibleOverride = nil

        if messageText then messageText:Hide() end
        if iconFrame then iconFrame:Show() end
        if toastText then toastText:Show() end

        -- Set text first to calculate width
        local text = "Put 1 point in |cFF00FF00" .. talentName .. "|r"
        if toastText then
            toastText:SetText(text)
        end

        -- Calculate positions to center icon + text together
        local textWidth = toastText and toastText:GetStringWidth() or 150
        local iconSize = 24
        local spacing = 8
        local totalWidth = iconSize + spacing + textWidth

        -- Position icon and text centered as a group
        if iconFrame then
            iconFrame:SetTexture(talentIcon)
            iconFrame:ClearAllPoints()
            iconFrame:SetPoint("CENTER", toast, "CENTER", -totalWidth/2 + iconSize/2, 0)
        end

        if toastText then
            toastText:ClearAllPoints()
            toastText:SetPoint("CENTER", toast, "CENTER", -totalWidth/2 + iconSize + spacing + textWidth/2, 0)
        end

        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Showing toast for: " .. talentName)
        end
    end

    -- Start fade in animation
    self.toastState.alpha = 0
    self.toastState.phase = "fadein"
    self.toastState.elapsed = 0

    toast:SetAlpha(0)
    toast:Show()

    -- Set up OnUpdate for animation
    toast:SetScript("OnUpdate", function()
        TalentTracker:UpdateToastAnimation(arg1)
    end)
end

-- Update toast animation
function TalentTracker:UpdateToastAnimation(elapsed)
    local toast = getglobal("GLV_TalentToast")
    if not toast then return end

    local state = self.toastState
    state.elapsed = state.elapsed + elapsed

    if state.phase == "fadein" then
        state.alpha = state.elapsed / TOAST_FADE_IN_TIME
        if state.alpha >= 1 then
            state.alpha = 1
            state.phase = "visible"
            state.elapsed = 0
        end
        toast:SetAlpha(state.alpha)

    elseif state.phase == "visible" then
        -- Toast stays visible until dismissed by click or talent spent
        return

    elseif state.phase == "fadeout" then
        state.alpha = 1 - (state.elapsed / TOAST_FADE_OUT_TIME)
        if state.alpha <= 0 then
            state.alpha = 0
            state.phase = "none"
            toast:Hide()
            toast:SetScript("OnUpdate", nil)
        end
        toast:SetAlpha(state.alpha)
    end
end

-- Hide talent toast immediately
function TalentTracker:HideTalentToast()
    local toast = getglobal("GLV_TalentToast")
    if toast then
        toast:Hide()
        toast:SetScript("OnUpdate", nil)
        self.toastState.phase = "none"
    end
end

-- Dismiss toast with fade out (triggered by click or talent spent)
function TalentTracker:DismissToast()
    local state = self.toastState
    if state.phase == "visible" or state.phase == "fadein" then
        state.phase = "fadeout"
        state.elapsed = 0
    end
end

-- Legacy function names for compatibility
function TalentTracker:ShowTalentPopup(talentName, talentIcon, treeIndex, customMessage)
    self:ShowTalentToast(talentName, talentIcon, treeIndex, customMessage)
end

function TalentTracker:HideTalentPopup()
    self:HideTalentToast()
end


--[[ TALENT FRAME HIGHLIGHTING ]]--

-- Hook a single talent frame
function TalentTracker:HookSingleTalentFrame(talentFrame, frameName, tabPrefix)
    if not talentFrame then return false end

    -- Avoid hooking multiple times
    if talentFrame.glvHooked then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Talents]|r Already hooked " .. frameName)
        end
        return true
    end
    talentFrame.glvHooked = true

    -- Hook OnShow
    local oldOnShow = talentFrame:GetScript("OnShow")
    talentFrame:SetScript("OnShow", function()
        if oldOnShow then oldOnShow() end
        -- Small delay to ensure frame is fully rendered
        if GLV.Ace then
            GLV.Ace:ScheduleEvent("GLV_OnTalentFrameShow", function()
                TalentTracker:UpdateTalentHighlights()
            end, 0.1)
        else
            TalentTracker:UpdateTalentHighlights()
        end
    end)

    -- Hook OnHide to clean up
    local oldOnHide = talentFrame:GetScript("OnHide")
    talentFrame:SetScript("OnHide", function()
        if oldOnHide then oldOnHide() end
        TalentTracker:ClearTalentHighlights()
    end)

    -- Hook tab changes
    for i = 1, 3 do
        local tab = _G[tabPrefix .. i]
        if tab and not tab.glvHooked then
            tab.glvHooked = true
            local oldOnClick = tab:GetScript("OnClick")
            tab:SetScript("OnClick", function()
                if oldOnClick then oldOnClick() end
                -- Delay to let talents update after tab switch
                if GLV.Ace then
                    GLV.Ace:ScheduleEvent("GLV_UpdateHighlights", function()
                        TalentTracker:UpdateTalentHighlights()
                    end, 0.15)
                end
            end)
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Hooked " .. tabPrefix .. i)
            end
        end
    end

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Talents]|r Successfully hooked " .. frameName)
    end
    return true
end

-- Hook the talent frame for highlighting
function TalentTracker:HookTalentFrame()
    local hooked = false

    for _, info in ipairs(TALENT_FRAMES) do
        if _G[info.frame] then
            hooked = self:HookSingleTalentFrame(_G[info.frame], info.frame, info.tab) or hooked
        end
    end

    if not hooked then
        -- Frame not loaded yet, try again later
        if GLV.Ace then
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Talents]|r No talent frame found, retrying in 2s...")
            end
            GLV.Ace:ScheduleEvent("GLV_HookTalentFrame", function()
                self:HookTalentFrame()
            end, 2.0)
        end
        return
    end

    -- Hook CHARACTER_POINTS_CHANGED to update after spending a point
    if GLV.Ace and not self.characterPointsHooked then
        self.characterPointsHooked = true
        GLV.Ace:RegisterEvent("CHARACTER_POINTS_CHANGED", function()
            -- Hide toast when talent point is spent
            TalentTracker:DismissToast()

            -- Only update highlights if a talent frame is visible
            local visibleFrame = self:GetVisibleTalentFrame()
            if visibleFrame then
                GLV.Ace:ScheduleEvent("GLV_UpdateHighlightsOnPointSpent", function()
                    TalentTracker:UpdateTalentHighlights()
                end, 0.2)
            end
        end)
    end
end

-- Position the independent highlight frame over a talent button
function TalentTracker:PositionHighlightOnButton(talentButton)
    if not talentButton then return false end

    local highlight = getglobal("GLV_TalentHighlight")
    if not highlight then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r GLV_TalentHighlight frame not found!")
        end
        return false
    end

    -- Get button dimensions
    local width = talentButton:GetWidth()
    local height = talentButton:GetHeight()

    -- Resize highlight to match button
    highlight:SetWidth(width)
    highlight:SetHeight(height)

    -- Position highlight centered on the button
    highlight:ClearAllPoints()
    highlight:SetPoint("CENTER", talentButton, "CENTER", 0, 0)

    -- Make sure it's on top
    highlight:SetFrameStrata("FULLSCREEN_DIALOG")

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Talents]|r Positioned highlight on button (" .. width .. "x" .. height .. ")")
    end

    return true
end

-- Get the visible talent frame and button prefix
function TalentTracker:GetVisibleTalentFrame()
    for _, info in ipairs(TALENT_FRAMES) do
        local f = _G[info.frame]
        if f and f:IsVisible() then
            return f, info.button
        end
    end
    return nil, nil
end

-- Get talent button by tree/row/col position
function TalentTracker:GetTalentButtonByPosition(tree, row, col)
    local numTalents = GetNumTalents(tree)
    if not numTalents then return nil end

    -- Find the talent index for this position
    local talentIndex = nil
    for i = 1, numTalents do
        local name, icon, tier, column = GetTalentInfo(tree, i)
        if tier == row and column == col then
            talentIndex = i
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Found talent '" .. (name or "?") .. "' at index " .. i)
            end
            break
        end
    end

    if not talentIndex then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r No talent found at row " .. row .. ", col " .. col)
        end
        return nil
    end

    -- Get the visible talent frame's button prefix
    local talentFrame, prefix = self:GetVisibleTalentFrame()
    if not prefix then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r No visible talent frame found")
        end
        return nil
    end

    local buttonName = prefix .. talentIndex
    local button = _G[buttonName]

    if button and button:IsVisible() then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Talents]|r Found button: " .. buttonName)
        end
        return button
    end

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r Button " .. buttonName .. " not visible")
    end
    return nil
end

-- Get currently selected talent tab
function TalentTracker:GetCurrentTalentTab()
    -- Get the visible talent frame
    local talentFrame = self:GetVisibleTalentFrame()
    if not talentFrame then
        -- Fallback: first existing frame
        for _, info in ipairs(TALENT_FRAMES) do
            if _G[info.frame] then talentFrame = _G[info.frame]; break end
        end
    end

    if talentFrame then
        -- Try selectedTab property
        if talentFrame.selectedTab then
            return talentFrame.selectedTab
        end
        -- Try PanelTemplates
        if PanelTemplates_GetSelectedTab then
            local tab = PanelTemplates_GetSelectedTab(talentFrame)
            if tab then return tab end
        end
    end

    -- Default to 1
    return 1
end

-- Update talent highlights
function TalentTracker:UpdateTalentHighlights()
    self:ClearTalentHighlights()

    if not GLV.Settings:GetOption({"Talents", "Enabled"}) then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r Feature disabled")
        end
        return
    end
    if not GLV.Settings:GetOption({"Talents", "HighlightInFrame"}) then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r Highlight disabled")
        end
        return
    end

    local _, playerClass = UnitClass("player")
    local templateName = GLV:GetActiveTemplate(playerClass)
    if not templateName then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r No template for " .. (playerClass or "unknown"))
        end
        return
    end

    local template = GLV.TalentTemplates[playerClass] and GLV.TalentTemplates[playerClass][templateName]
    if not template then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r Template not found: " .. templateName)
        end
        return
    end

    local playerLevel = UnitLevel("player")
    local unspentPoints = UnitCharacterPoints("player")

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Level: " .. playerLevel .. ", Unspent: " .. (unspentPoints or 0))
    end

    if not unspentPoints or unspentPoints <= 0 then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r No unspent points")
        end
        return
    end

    -- Get the correct talents table (phase 1 or phase 2 if respec done)
    local talents = GLV:GetTemplateTalents(template, playerClass)
    if not talents then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r No talents table found")
        end
        return
    end

    -- Calculate which talent level we should be placing
    -- First talent at level 10, then every level after
    local talentLevel = playerLevel - unspentPoints + 1

    -- Make sure we don't go below level 10
    if talentLevel < 10 then talentLevel = 10 end

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Looking for talent at level " .. talentLevel)
    end

    local nextTalent = talents[talentLevel]
    if not nextTalent then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r No talent defined for level " .. talentLevel)
        end
        return
    end

    local tree, row, col = nextTalent[1], nextTalent[2], nextTalent[3]
    local talentName = GLV:GetTalentNameByPosition(tree, row, col)

    if GLV.Debug then
        local treeName = GLV:GetTalentTreeName(tree) or "Tree " .. tree
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Suggested: " .. (talentName or "unknown") .. " in " .. treeName .. " (row " .. row .. ", col " .. col .. ")")
    end

    -- Check if current tab matches the suggested tree
    local currentTab = self:GetCurrentTalentTab()
    if currentTab ~= tree then
        -- Highlight the tab that needs to be clicked
        local treeName = GLV:GetTalentTreeName(tree) or "Unknown"
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Talents]|r Switch to " .. treeName .. " tree (tab " .. tree .. "), currently on tab " .. currentTab)
        end
        -- Could add tab highlighting here in the future
        return
    end

    local talentButton = self:GetTalentButtonByPosition(tree, row, col)
    if talentButton then
        self:HighlightTalent(talentButton)
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Talents]|r Highlighting talent button")
        end
    else
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r Could not find talent button for tree " .. tree .. ", row " .. row .. ", col " .. col)
        end
    end
end

-- Highlight a talent button using the independent highlight frame
function TalentTracker:HighlightTalent(button)
    if not button then return end

    if self:PositionHighlightOnButton(button) then
        local highlight = getglobal("GLV_TalentHighlight")
        if highlight then
            highlight:Show()
            self.highlightedButton = button

            -- Set up OnUpdate to hide when talent frame closes
            if not highlight.onUpdateSet then
                highlight:SetScript("OnUpdate", function()
                    TalentTracker:CheckTalentFrameVisibility()
                end)
                highlight.onUpdateSet = true
            end

            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Talents]|r Highlight shown!")
            end
        end
    end
end

-- Check if talent frame is still visible, hide highlight if not
function TalentTracker:CheckTalentFrameVisibility()
    local talentFrame = self:GetVisibleTalentFrame()
    if not talentFrame then
        self:ClearTalentHighlights()
    end
end

-- Clear all talent highlights
function TalentTracker:ClearTalentHighlights()
    local highlight = getglobal("GLV_TalentHighlight")
    if highlight then
        highlight:Hide()
        -- Don't remove OnUpdate, just let it stop checking when hidden
    end
    self.highlightedButton = nil
end


--[[ DEBUG/TEST FUNCTIONS ]]--

-- Test function to simulate level up (for debugging)
function TalentTracker:TestLevelUp(level)
    level = level or (UnitLevel("player") + 1)
    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Testing level up to " .. level)
    end
    self:OnLevelUp(level)
end

-- Slash command for testing
SLASH_GLVTALENT1 = "/glvtalent"
SlashCmdList["GLVTALENT"] = function(msg)
    if msg == "debug" then
        GLV.Debug = not GLV.Debug
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime Talents]|r Debug mode: " .. (GLV.Debug and "ON" or "OFF"))
        return
    end

    if msg == "highlight" or msg == "hl" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime Talents]|r Forcing highlight update...")
        TalentTracker:UpdateTalentHighlights()
        return
    end

    if msg == "hook" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime Talents]|r Re-hooking talent frame...")
        for _, info in ipairs(TALENT_FRAMES) do
            local f = _G[info.frame]
            if f then f.glvHooked = nil end
        end
        TalentTracker:HookTalentFrame()
        return
    end

    if msg == "buttons" then
        -- List all talent-related frames/buttons
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Talents]|r Scanning for talent buttons...")
        for _, info in ipairs(TALENT_FRAMES) do
            local f = _G[info.frame]
            if f then
                DEFAULT_CHAT_FRAME:AddMessage("  Frame: " .. info.frame .. " (" .. (f:IsVisible() and "visible" or "hidden") .. ")")
            end
            for i = 1, 30 do
                local btn = _G[info.button .. i]
                if btn then
                    DEFAULT_CHAT_FRAME:AddMessage("  " .. info.button .. i .. " (" .. (btn:IsVisible() and "visible" or "hidden") .. ")")
                end
            end
        end
        -- Also check SpellBook talent buttons (non-standard)
        for i = 1, 30 do
            local btn = _G["SpellBookTalentButton" .. i]
            if btn then
                DEFAULT_CHAT_FRAME:AddMessage("  SpellBookTalentButton" .. i .. " (" .. (btn:IsVisible() and "visible" or "hidden") .. ")")
            end
        end
        return
    end

    if msg == "test" then
        -- Test the highlight frame directly
        local highlight = getglobal("GLV_TalentHighlight")
        if highlight then
            highlight:ClearAllPoints()
            highlight:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            highlight:SetWidth(50)
            highlight:SetHeight(50)
            highlight:Show()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Talents]|r Test highlight shown at screen center")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Talents]|r GLV_TalentHighlight frame not found!")
        end
        return
    end

    if msg == "toast" then
        -- Test the toast notification
        TalentTracker:ShowTalentToast("Test Talent", "Interface\\Icons\\Spell_Nature_Lightning", 1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Talents]|r Test toast shown")
        return
    end

    if msg == "info" then
        local _, playerClass = UnitClass("player")
        local templateName = GLV.Settings:GetOption({"Talents", "ActiveTemplate", playerClass})
        local playerLevel = UnitLevel("player")
        local unspentPoints = UnitCharacterPoints("player") or 0

        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime Talents]|r Info:")
        DEFAULT_CHAT_FRAME:AddMessage("  Class: " .. (playerClass or "unknown"))
        DEFAULT_CHAT_FRAME:AddMessage("  Level: " .. playerLevel)
        DEFAULT_CHAT_FRAME:AddMessage("  Unspent points: " .. unspentPoints)
        DEFAULT_CHAT_FRAME:AddMessage("  Template: " .. (templateName or "none"))
        DEFAULT_CHAT_FRAME:AddMessage("  Enabled: " .. tostring(GLV.Settings:GetOption({"Talents", "Enabled"})))
        DEFAULT_CHAT_FRAME:AddMessage("  Highlight: " .. tostring(GLV.Settings:GetOption({"Talents", "HighlightInFrame"})))

        -- Show respec phase info
        if templateName and GLV.TalentTemplates[playerClass] then
            local template = GLV.TalentTemplates[playerClass][templateName]
            if template and template.respec then
                local respecDone = GLV.Settings:GetOption({"Talents", "RespecDone", playerClass})
                local phase = respecDone and "Phase 2 (post-respec)" or "Phase 1 (pre-respec)"
                DEFAULT_CHAT_FRAME:AddMessage("  Respec: at level " .. template.respec.respecAt .. " - " .. phase)
            end
        end

        for _, info in ipairs(TALENT_FRAMES) do
            local f = _G[info.frame]
            if f then
                DEFAULT_CHAT_FRAME:AddMessage("  " .. info.frame .. ": hooked=" .. tostring(f.glvHooked or false) .. " visible=" .. tostring(f:IsVisible()))
            end
        end
        return
    end

    local level = tonumber(msg)
    if level then
        TalentTracker:TestLevelUp(level)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime Talents]|r Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /glvtalent <level> - Test level up popup")
        DEFAULT_CHAT_FRAME:AddMessage("  /glvtalent debug - Toggle debug mode")
        DEFAULT_CHAT_FRAME:AddMessage("  /glvtalent highlight - Force highlight update")
        DEFAULT_CHAT_FRAME:AddMessage("  /glvtalent hook - Re-hook talent frame")
        DEFAULT_CHAT_FRAME:AddMessage("  /glvtalent info - Show current settings")
    end
end
