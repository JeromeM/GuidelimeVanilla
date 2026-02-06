--[[
Guidelime Vanilla

Author: Grommey

Description:
Frames manipulation.
The left menu is only some FontString. The trick is to have
multiple Frames with the same dimensions but not the same content.
When we click on a menu "button", it will hide all the Frames except
the one linked to this "button".
]]--
local GLV = LibStub("GuidelimeVanilla")

-- Track if display settings have changed (requires reload)
local displaySettingsChanged = false

-- Mark display settings as changed
function GLV_MarkDisplaySettingsChanged()
    displaySettingsChanged = true
end

-- Check if display settings changed and prompt for reload
function GLV_CheckReloadOnClose()
    if displaySettingsChanged then
        displaySettingsChanged = false
        ReloadUI()
    end
end

-- Reset the changed flag (called when settings open)
function GLV_ResetDisplaySettingsChanged()
    displaySettingsChanged = false
end


-- Toggle settings frame visibility
function GLV_ToggleSettings()
    if GLV_Settings:IsVisible() then
        GLV_Settings:Hide()
    else
        GLV_Settings:Show()
    end
end

-- Hide the main guide frame and show reopen instructions
function GLV_HideGuideFrame()
    if GLV_Main then
        GLV_Main:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF6B8BD4[GuideLime]|r Guide window hidden. Type |cFFFFFF00/glv show|r to display it again.")
    end
end

-- Show the main guide frame
function GLV_ShowGuideFrame()
    if GLV_Main then
        GLV_Main:Show()
    end
end

-- Show specific guide page and hide all others
function GLV_ShowGuide(frame)
    local frames = {
        GLV_SettingsGuidesPage,
        GLV_SettingsDisplayPage,
        GLV_SettingsTalentsPage,
        GLV_SettingsAboutPage,
    }

    -- Hide all other frames first
    for _, f in pairs(frames) do
        if f:IsVisible() then
            f:Hide()
        end
    end

    -- Show the requested frame
    frame:Show()
end

-- Initialize the about page with description text
function GLV_SettingsAboutPage_OnLoad()
    local text = [[
Guidelime Vanilla is a total overhaul of the official Guidelime, which is not compatible with WoW 1.12.
The original project is a rewrite of the VanillaGuide from mrmr. But I wanted to have something more functionnal and with the possibility to use actual Guidelime's guide available on CurseForge.

I've tried to automatize a lot of things like auto-complete steps with Quest Accept or Quest Complete (as much as the WoW 1.12 API let me do it).
It's using it's own navigation system.

Thanks to :
- |cFFFF0000mrmr|r for the original addon
- |cFFFF0000Shagu|r for the PfQuest databases
- |cFFFF0000Laytya|r for the Spells DB


Original source for VanillaGuide :

My rewrite of VanillaGuide to VanillaGuideReloaded :
]]

    local content = GLV_SettingsAboutPageContent
    content:SetWidth(700)                -- Max width before line break
    content:SetNonSpaceWrap(true)        -- Allows cutting even without spaces
    content:SetJustifyH("LEFT")          -- Horizontal alignment
    content:SetJustifyV("TOP")           -- Vertical alignment
    content:SetText(text)
end

-- Function to restore saved position
local function GLV_RestoreFramePosition()
    if GLV and GLV.Settings then
        local posX = GLV.Settings:GetOption({"UI", "PositionX"})
        local posY = GLV.Settings:GetOption({"UI", "PositionY"})
        
        if posX and posY then
            GLV_Main:ClearAllPoints()
            GLV_Main:SetPoint("TOPLEFT", UIParent, "TOPLEFT", posX, posY)
        end
    end
end

-- Function to save current position
local function GLV_SaveFramePosition()
    if GLV and GLV.Settings then
        local left = GLV_Main:GetLeft()
        local top = GLV_Main:GetTop()
        
        if left and top then
            -- Calculate coordinates relative to top-left corner
            local screenHeight = GetScreenHeight()
            local relativeY = top - screenHeight
            
            GLV.Settings:SetOption(left, {"UI", "PositionX"})
            GLV.Settings:SetOption(relativeY, {"UI", "PositionY"})
        end
    end
end

function GLV_MainLock_OnLoad()
    -- Wait for addon to be completely initialized
    this:RegisterEvent("ADDON_LOADED");
    this:SetScript("OnEvent", function()
        if event == "ADDON_LOADED" and arg1 == "GuideLimeVanilla" then
            -- Now GLV is available
            local locked = GLV and GLV.Settings and GLV.Settings:GetOption({"UI", "Locked"}) or false;
            
            -- Restore saved position BEFORE applying lock
            GLV_RestoreFramePosition()
            
            if locked then
                -- Locked state
                GLV_MainLock:SetNormalTexture("Interface\\AddOns\\GuideLimeVanilla\\Textures\\closed_lock")
                GLV_MainLock:SetPushedTexture("Interface\\AddOns\\GuideLimeVanilla\\Textures\\closed_lock_down")
                GLV_Main:SetMovable(false)
                GLV_Main:RegisterForDrag()
            else
                -- Unlocked state
                GLV_MainLock:SetNormalTexture("Interface\\AddOns\\GuideLimeVanilla\\Textures\\opened_lock")
                GLV_MainLock:SetPushedTexture("Interface\\AddOns\\GuideLimeVanilla\\Textures\\opened_lock_down")
                GLV_Main:SetMovable(true)
                GLV_Main:RegisterForDrag("LeftButton")
            end
        end
    end);
end

-- Initialize automation checkbox from settings
function GLV_InitAutomationCheckbox(checkbox, settingKeys)
    local value = GLV.Settings:GetOption(settingKeys) or false
    checkbox:SetChecked(value)
end

-- Handle automation checkbox click
function GLV_OnAutomationCheckboxClick(checkbox, settingKeys)
    local isChecked = checkbox:GetChecked() == 1
    GLV.Settings:SetOption(isChecked, settingKeys)
end

-- Store selected pack name (not yet loaded)
GLV_SelectedGuidePack = nil

-- Factory function to create dropdown callback (avoids closure issue in Lua 5.0)
local function createPackDropdownCallback(dropdown, packName)
    return function()
        GLV_SelectedGuidePack = packName
        UIDropDownMenu_SetSelectedValue(dropdown, packName)
        UIDropDownMenu_SetText(packName, dropdown)
        -- Update notes display
        GLV_UpdateGuidePackNotes(packName)
    end
end

-- Initialize guide pack dropdown
function GLV_InitGuidePackDropdown(dropdown)
    local packs = GLV:GetAvailableGuidePacks()
    local activePack = GLV:GetActiveGuidePack()

    -- Initialize selected pack to active pack
    GLV_SelectedGuidePack = activePack

    UIDropDownMenu_Initialize(dropdown, function()
        if table.getn(packs) == 0 then
            local info = {}
            info.text = "No guide packs installed"
            info.disabled = 1
            UIDropDownMenu_AddButton(info)
            return
        end

        for _, packName in ipairs(packs) do
            local info = {}
            info.text = packName
            info.value = packName
            info.func = createPackDropdownCallback(dropdown, packName)
            UIDropDownMenu_AddButton(info)
        end
    end)

    if activePack then
        UIDropDownMenu_SetSelectedValue(dropdown, activePack)
        UIDropDownMenu_SetText(activePack, dropdown)
        GLV_UpdateGuidePackNotes(activePack)
    else
        UIDropDownMenu_SetText("Select a guide pack", dropdown)
        GLV_UpdateGuidePackNotes(nil)
    end
end

-- Update the notes display for a guide pack
function GLV_UpdateGuidePackNotes(packName)
    local notesText = _G["GLV_SettingsGuidesPageGuidePackNotesText"]
    if not notesText then return end

    if not packName then
        notesText:SetText("")
        return
    end

    -- Try to get addon name from pack metadata
    local addonName = GLV.guidePackAddons and GLV.guidePackAddons[packName]
    if addonName then
        local notes = GetAddOnMetadata(addonName, "Notes")
        if notes then
            notesText:SetText(notes)
            return
        end
    end

    -- Fallback: show number of guides
    local guides = GLV.loadedGuides[packName]
    local count = 0
    if guides then
        for _ in pairs(guides) do count = count + 1 end
    end
    notesText:SetText(count .. " guides available")
end

-- Load the selected guide pack
function GLV_LoadSelectedGuidePack()
    if not GLV_SelectedGuidePack then return end

    local packName = GLV_SelectedGuidePack
    GLV:SetActiveGuidePack(packName)

    -- Load appropriate guide
    local guides = GLV.loadedGuides[packName]
    if not guides then return end

    local currentGuide = GLV.Settings:GetOption({"Guide", "CurrentGuide"})
    if currentGuide and guides[currentGuide] then
        GLV:LoadGuide(packName, currentGuide)
    else
        -- Load based on race/level
        local _, race = UnitRace("player")
        GLV.Addon:LoadDefaultGuideForRace(race)
    end

    -- Close settings
    GLV_Settings:Hide()
end

-- Unload the current guide and reset selection
function GLV_UnloadCurrentGuide()
    -- Clear active pack
    GLV.Settings:SetOption(nil, {"Guide", "ActivePack"})
    GLV.Settings:SetOption("Unknown", {"Guide", "CurrentGuide"})

    -- Clear current guide data
    GLV.CurrentGuide = nil
    GLV.CurrentDisplaySteps = nil
    GLV.CurrentDisplayStepsCount = 0

    -- Clear navigation
    if GLV.GuideNavigation then
        GLV.GuideNavigation:ClearAllWaypoints()
        GLV.GuideNavigation:HideNextGuide()
    end

    -- Clear ongoing steps
    if GLV.OngoingStepsManager then
        GLV.OngoingStepsManager:Clear()
    end

    -- Disable main dropdown
    local dropdown = _G["GLV_MainDropdown"]
    if dropdown then
        UIDropDownMenu_ClearAll(dropdown)
        UIDropDownMenu_SetText("", dropdown)
        local button = _G[dropdown:GetName().."Button"]
        if button then button:Disable() end
    end

    -- Reset guide name and step counter
    local guideTitle = _G["GLV_MainLoadedGuideTitle"]
    if guideTitle then
        guideTitle:SetText("")
    end
    local stepCounter = _G["GLV_MainLoadedGuideCounter"]
    if stepCounter then
        stepCounter:SetText("")
    end

    -- Show the "no guide" message
    GLV:ShowNoGuideMessage()

    -- Reset dropdown selection
    GLV_SelectedGuidePack = nil

    -- Close settings
    GLV_Settings:Hide()
end

-- Initialize scale slider from settings
function GLV_InitScaleSlider(slider, settingKeys)
    local value = GLV.Settings:GetOption(settingKeys) or 1
    slider:SetValue(value)
    getglobal(slider:GetName().."Text"):SetText(string.format("%.1f", value))
end

-- Handle guide text scale slider change
function GLV_OnGuideScaleSliderChanged(slider, settingKeys)
    local value = slider:GetValue()
    -- Round to 1 decimal place
    value = math.floor(value * 10 + 0.5) / 10
    getglobal(slider:GetName().."Text"):SetText(string.format("%.1f", value))
    GLV.Settings:SetOption(value, settingKeys)
    -- Mark as changed for reload on close
    GLV_MarkDisplaySettingsChanged()
    -- Refresh guide to apply new scale
    if GLV.RefreshGuide then
        GLV:RefreshGuide()
    end
end

-- Handle navigation scale slider change
function GLV_OnNavScaleSliderChanged(slider, settingKeys)
    local value = slider:GetValue()
    -- Round to 1 decimal place
    value = math.floor(value * 10 + 0.5) / 10
    getglobal(slider:GetName().."Text"):SetText(string.format("%.1f", value))
    GLV.Settings:SetOption(value, settingKeys)
    -- Mark as changed for reload on close
    GLV_MarkDisplaySettingsChanged()
    -- Apply scale to navigation frame
    if GLV.GuideNavigation and GLV.GuideNavigation.ApplyScale then
        GLV.GuideNavigation:ApplyScale(value)
    end
end

function GLV_MainLock_OnClick()
    local locked = GLV and GLV.Settings and GLV.Settings:GetOption({"UI", "Locked"}) or false

    if locked then
        -- Unlock
        GLV_MainLock:SetNormalTexture("Interface\\AddOns\\GuideLimeVanilla\\Textures\\opened_lock")
        GLV_MainLock:SetPushedTexture("Interface\\AddOns\\GuideLimeVanilla\\Textures\\opened_lock_down")
        GLV_Main:SetMovable(true)
        GLV_Main:RegisterForDrag("LeftButton")

        if GLV and GLV.Settings then
            GLV.Settings:SetOption(false, {"UI", "Locked"})
        end
    else
        -- Lock - Save current position BEFORE locking
        GLV_SaveFramePosition()

        GLV_MainLock:SetNormalTexture("Interface\\AddOns\\GuideLimeVanilla\\Textures\\closed_lock")
        GLV_MainLock:SetPushedTexture("Interface\\AddOns\\GuideLimeVanilla\\Textures\\closed_lock_down")
        GLV_Main:SetMovable(false)
        GLV_Main:RegisterForDrag("")

        if GLV and GLV.Settings then
            GLV.Settings:SetOption(true, {"UI", "Locked"})
        end
    end
end

-- ============================================================================
-- TALENT SETTINGS FUNCTIONS
-- ============================================================================

-- Initialize talent checkbox from settings
function GLV_InitTalentCheckbox(checkbox, settingKeys)
    local value = GLV.Settings:GetOption(settingKeys)
    if value == nil then value = true end  -- Default to true
    checkbox:SetChecked(value)
end

-- Handle talent checkbox click
function GLV_OnTalentCheckboxClick(checkbox, settingKeys)
    local isChecked = checkbox:GetChecked() == 1
    GLV.Settings:SetOption(isChecked, settingKeys)
end

-- Store selected template name
GLV_SelectedTalentTemplate = nil

-- Factory function to create dropdown callback for talent templates
local function createTalentTemplateCallback(dropdown, templateName)
    return function()
        GLV_SelectedTalentTemplate = templateName
        UIDropDownMenu_SetSelectedValue(dropdown, templateName)
        UIDropDownMenu_SetText(templateName, dropdown)
        -- Save to settings
        local _, playerClass = UnitClass("player")
        if playerClass then
            GLV.Settings:SetOption(templateName, {"Talents", "ActiveTemplate", playerClass})
            -- Reset respec state when changing template
            GLV.Settings:SetOption(nil, {"Talents", "RespecDone", playerClass})
        end
    end
end

-- Initialize talent template dropdown
function GLV_InitTalentTemplateDropdown(dropdown)
    local _, playerClass = UnitClass("player")
    if not playerClass then
        UIDropDownMenu_SetText("Unknown class", dropdown)
        return
    end

    -- Get templates for player's class
    local templates = GLV.TalentTemplates and GLV.TalentTemplates[playerClass]
    -- Use GetActiveTemplate which includes fallback to default
    local activeTemplate = GLV:GetActiveTemplate(playerClass)
    GLV_SelectedTalentTemplate = activeTemplate

    UIDropDownMenu_Initialize(dropdown, function()
        if not templates then
            local info = {}
            info.text = "No templates for " .. playerClass
            info.disabled = 1
            UIDropDownMenu_AddButton(info)
            return
        end

        -- Count templates
        local count = 0
        for _ in pairs(templates) do count = count + 1 end

        if count == 0 then
            local info = {}
            info.text = "No templates available"
            info.disabled = 1
            UIDropDownMenu_AddButton(info)
            return
        end

        -- Add templates to dropdown (leveling first, then endgame)
        local levelingTemplates = {}
        local endgameTemplates = {}

        for templateName, templateData in pairs(templates) do
            if templateData.type == "leveling" then
                table.insert(levelingTemplates, templateName)
            else
                table.insert(endgameTemplates, templateName)
            end
        end

        -- Sort alphabetically
        table.sort(levelingTemplates)
        table.sort(endgameTemplates)

        -- Add leveling templates
        for _, templateName in ipairs(levelingTemplates) do
            local info = {}
            info.text = templateName .. " (Leveling)"
            info.value = templateName
            info.func = createTalentTemplateCallback(dropdown, templateName)
            UIDropDownMenu_AddButton(info)
        end

        -- Add endgame templates
        for _, templateName in ipairs(endgameTemplates) do
            local info = {}
            info.text = templateName .. " (Endgame)"
            info.value = templateName
            info.func = createTalentTemplateCallback(dropdown, templateName)
            UIDropDownMenu_AddButton(info)
        end
    end)

    if activeTemplate then
        UIDropDownMenu_SetSelectedValue(dropdown, activeTemplate)
        UIDropDownMenu_SetText(activeTemplate, dropdown)
    else
        UIDropDownMenu_SetText("Select a template", dropdown)
    end
end

-- Update class label to show player's class
function GLV_UpdateTalentClassLabel()
    local labelText = _G["GLV_SettingsTalentsPageClassLabelText"]
    if not labelText then return end

    local localizedClass, playerClass = UnitClass("player")
    if localizedClass then
        labelText:SetText("(" .. localizedClass .. ")")
    else
        labelText:SetText("")
    end
end

-- ============================================================================
-- TOAST NOTIFICATION POSITION FUNCTIONS
-- ============================================================================

-- Start moving the toast notification
function GLV_StartMoveToastNotification()
    local toast = getglobal("GLV_TalentToast")
    if not toast then return end

    -- Enable mouse interaction and dragging
    toast.isMoving = true
    toast:EnableMouse(true)
    toast:RegisterForDrag("LeftButton")

    -- Show toast with instructions
    local toastText = getglobal("GLV_TalentToastText")
    local toastIcon = getglobal("GLV_TalentToastIcon")

    if toastIcon then
        toastIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    if toastText then
        toastText:SetText("|cFFFFFF00Drag to move, then click to confirm|r")
        toastText:ClearAllPoints()
        toastText:SetPoint("CENTER", toast, "CENTER", 15, 0)
    end

    if toastIcon then
        toastIcon:ClearAllPoints()
        toastIcon:SetPoint("CENTER", toast, "CENTER", -100, 0)
    end

    toast:SetAlpha(1)
    toast:Show()

    -- Add click handler to confirm position
    toast:SetScript("OnMouseUp", function()
        if arg1 == "LeftButton" and not toast.isDragging then
            GLV_ConfirmToastPosition()
        end
        toast.isDragging = false
    end)

    toast:SetScript("OnDragStart", function()
        toast.isDragging = true
        toast:StartMoving()
    end)

    toast:SetScript("OnDragStop", function()
        toast:StopMovingOrSizing()
        GLV_TalentToast_SavePosition()
    end)
end

-- Confirm and save toast position
function GLV_ConfirmToastPosition()
    local toast = getglobal("GLV_TalentToast")
    if not toast then return end

    -- Save position
    GLV_TalentToast_SavePosition()

    -- Disable moving mode
    toast.isMoving = false
    toast:EnableMouse(false)
    toast:RegisterForDrag()

    -- Remove click handler
    toast:SetScript("OnMouseUp", nil)

    -- Hide toast
    toast:Hide()

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[GuideLime]|r Notification position saved!")
end

-- Save toast position to settings
function GLV_TalentToast_SavePosition()
    local toast = getglobal("GLV_TalentToast")
    if not toast then return end
    if not GLV or not GLV.Settings then return end

    local point, relativeTo, relativePoint, xOfs, yOfs = toast:GetPoint(1)
    if point then
        -- Save absolute position from center of screen
        local left = toast:GetLeft()
        local top = toast:GetTop()
        local screenWidth = GetScreenWidth()
        local screenHeight = GetScreenHeight()

        if left and top then
            local centerX = left + (toast:GetWidth() / 2) - (screenWidth / 2)
            local centerY = top - (toast:GetHeight() / 2) - (screenHeight / 2)

            GLV.Settings:SetOption(centerX, {"Talents", "ToastPositionX"})
            GLV.Settings:SetOption(centerY, {"Talents", "ToastPositionY"})
        end
    end
end

-- Restore toast position from settings
function GLV_TalentToast_RestorePosition()
    local toast = getglobal("GLV_TalentToast")
    if not toast then return end

    -- Wait for GLV to be ready
    if not GLV or not GLV.Settings then
        -- Try again later
        if toast then
            toast:SetScript("OnUpdate", function()
                if GLV and GLV.Settings then
                    this:SetScript("OnUpdate", nil)
                    GLV_TalentToast_RestorePosition()
                end
            end)
        end
        return
    end

    local posX = GLV.Settings:GetOption({"Talents", "ToastPositionX"})
    local posY = GLV.Settings:GetOption({"Talents", "ToastPositionY"})

    if posX and posY then
        toast:ClearAllPoints()
        toast:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    end
end