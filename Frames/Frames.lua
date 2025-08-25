--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Frames manipulation.
The left menu is only some FontString. The trick is to have
multiple Frames with the same dimensions but not the same content.
When we click on a menu "button", it will hide all the Frames except
the one linked to this "button".
]]--
local _G = _G or getfenv()

-- Toggle settings frame visibility
function GLV_ToggleSettings()
    local settingsFrame = _G["GLV_Settings"]
    if not settingsFrame then return end
    if settingsFrame:IsVisible() then
        settingsFrame:Hide()
    else
        settingsFrame:Show()
    end
end

-- Show specific guide page and hide all others
function GLV_ShowGuide(frame)
    local frames = {
        _G["GLV_SettingsGuidesPage"],
        _G["GLV_SettingsDisplayPage"],
        _G["GLV_SettingsAboutPage"],
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
It's using TomTom Vanilla for the moment, but I think of implementing my own navigation system. I can already find coordinates of quests, NPCs and a lot of other things, thanks to PfQuest DB.

Thanks to :
- |cFFFF0000mrmr|r for the original addon
- |cFFFF0000Shagu|r for the PfQuest databases
- |cFFFF0000Laytya|r for the backport of TomTom
- |cFFFF0000Laytya|r for the Spells DB


Original source for VanillaGuide :

My rewrite of VanillaGuide to VanillaGuideReloaded :
]]

    local content = _G["GLV_SettingsAboutPageContent"]
    if not content then return end
    content:SetWidth(700)                -- Max width before line break
    content:SetNonSpaceWrap(true)        -- Allows cutting even without spaces
    content:SetJustifyH("LEFT")          -- Horizontal alignment
    content:SetJustifyV("TOP")           -- Vertical alignment
    content:SetText(text)
end