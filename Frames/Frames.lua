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

-- Show specific guide page and hide all others
function GLV_ShowGuide(frame)
    local frames = {
        GLV_SettingsGuidesPage,
        GLV_SettingsDisplayPage,
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