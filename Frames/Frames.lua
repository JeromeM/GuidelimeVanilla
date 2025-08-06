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

function GLV_ToggleSettings()
    if GLV_Settings:IsVisible() then
            GLV_Settings:Hide()
    else
            GLV_Settings:Show()
    end
end

function GLV_ShowGuide(frame)
    local frames = {
        GLV_SettingsGuidesPage,
        GLV_SettingsDisplayPage,
        GLV_SettingsAboutPage,
    }

    for _, f in pairs(frames) do
        if f:IsVisible() then
            f:Hide()
        end
    end

    frame:Show()
end

function GLV_SettingsAboutPage_OnLoad()
    local text = [[
Guidelime Vanilla is a total overhaul of the official Guidelime, which is not compatible with WoW 1.12.
The original project is a rewrite of the VanillaGuide from mrmr. But I wanted to have something more functionnal and with the possibility to use actual Guidelime's guide available on CurseForge.

I've tried to automatize a lot of things like auto-complete steps with Quest Accept or Quest Complete (as much as the WoW 1.12 API let me do it).
It's using TomTom Vanilla for the moment, but I think of implementing my own navigation system. I can already find coordinates of quests, NPCs and a lot of other things, thanks to PfQuest DB.

Thanks to :
- |cFFFF0000mrmr|r for the original addon
- |cFFFF0000Shagu|r for the PfQuest databases
- |cFFFF0000cladhaire|r for the backport of TomTom


Original source for VanillaGuide :

My rewrite of VanillaGuide to VanillaGuideReloaded :
]]

    local content = GLV_SettingsAboutPageContent
    content:SetWidth(700)                 -- Largeur max avant retour à la ligne
    content:SetNonSpaceWrap(true)        -- Permet de couper même sans espaces
    content:SetJustifyH("LEFT")          -- Alignement horizontal
    content:SetJustifyV("TOP")           -- Alignement vertical
    content:SetText(text)
end