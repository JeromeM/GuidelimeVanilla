--[[
Guidelime Vanilla

Author: Grommey

Description:
Trying to port Guidelime Guides to Vanilla (1.12).
This is the main file.
]]--
local _ADDON_NAME = "GuidelimeVanilla"
local _VERSION = GetAddOnMetadata(_ADDON_NAME, "Version")
local _G = _G or getfenv(0)

local GLV = LibStub:NewLibrary(_ADDON_NAME, 1)
if not GLV then return end

local addon = AceLibrary("AceAddon-2.0"):new(
    "AceConsole-2.0",
    "AceEvent-2.0",
    "AceDB-2.0",
    "AceHook-2.1"
)
GLV.Addon = addon


--[[ DEFAULT ACE2 EVENTS ]]--

-- Initialize addon settings and database
function addon:OnInitialize()
    DEFAULT_CHAT_FRAME:AddMessage(string.format("%s v%s", _ADDON_NAME, _VERSION))

    -- Set AddonName
    GLV.AddonName = _ADDON_NAME

    -- Set debug mode for testing (e.g. /script GLV.Debug = true then accept/turn in a quest to see QuestTracker messages)
    GLV.Debug = false

    -- Set GLV.Ace first so other modules can access it
    GLV.Ace = self

    -- Initialize settings
    Settings = GLV.Settings
    self:RegisterDB(_ADDON_NAME .. "DB")
    self:RegisterDefaults("char", Settings:GetDefaults())
    Settings:InitializeDB()

    -- Set title after settings are initialized
    if GLV_MainTitle then
        GLV_MainTitle:SetText(string.format("|cFF5B5FA4GuideLime|r |cFFA83E25Vanilla|r    |cFFFFFFFFv%s|r", _VERSION))
    end

    -- Register slash commands
    self:RegisterChatCommand({"/glv", "/guidelime"}, {
        type = "group",
        args = {
            show = {
                type = "execute",
                name = "Show",
                desc = "Show the guide window",
                func = function() GLV_ShowGuideFrame() end,
            },
            hide = {
                type = "execute",
                name = "Hide",
                desc = "Hide the guide window",
                func = function() GLV_HideGuideFrame() end,
            },
            settings = {
                type = "execute",
                name = "Settings",
                desc = "Open settings window",
                func = function() GLV_ToggleSettings() end,
            },
            editor = {
                type = "execute",
                name = "Editor",
                desc = "Toggle guide editor",
                func = function()
                    if GLV.GuideEditor then
                        GLV.GuideEditor:Toggle()
                    end
                end,
            },
        },
    })

end

-- Enable addon and initialize all modules
function addon:OnEnable()
    local name = UnitName("player")
    local realm = GetRealmName()
    local _, class = UnitClass("player")
    local _, race = UnitRace("player")
    local faction = UnitFactionGroup("player")

    local charInfo = {
        Realm = realm or "Unknown",
        Name = name or "Unknown",
        Faction = faction or "Unknown",
        Race = race or "Unknown",
        Class = class or "Unknown",
    }

    for key, val in pairs(charInfo) do
        Settings:SetOption(val, {"CharInfo", key})
    end

    Settings:SetOption(GetLocale(), "Locale")

    -- Register guide loading event
    self:RegisterEvent("PLAYER_LOGIN", function() self:OnPlayerLogin() end)

    -- Add Events Loading
    GLV.QuestTracker:Init()
    GLV.CharacterTracker:Init()
    GLV.TaxiTracker:Init()
    GLV.GossipTracker:Init()
    GLV.EquipmentTracker:Init()
    GLV.ItemTracker:Init()
    if GLV.TalentTracker then
        GLV.TalentTracker:Init()
    end

    -- Apply saved frame strata to guide window
    local strata = Settings:GetOption({"UI", "FrameStrata"})
    if strata then
        GLV_ApplyFrameStrata(strata)
    end

    -- Restore guide window visibility
    local guideHidden = Settings:GetOption({"UI", "GuideHidden"})
    if guideHidden and GLV_Main then
        GLV_Main:Hide()
    end

    -- Initialize Guide Navigation integration AFTER the guide is loaded
    self:ScheduleEvent(function()
        if GLV.GuideNavigation then
            GLV.GuideNavigation:Init()
        end
    end, 2.0)

    -- Initialize Minimap Path after navigation is ready
    self:ScheduleEvent(function()
        if GLV.MinimapPath then
            GLV.MinimapPath:Init()
        end
    end, 2.5)

    -- Initialize global DB and migrate per-character editor data
    Settings:InitializeGlobalDB()
    Settings:MigrateEditorToGlobal()

    -- Initialize Guide Editor (re-registers saved custom guides)
    if GLV.GuideEditor then
        GLV.GuideEditor:Init()
    end
end


--[[ EVENTS ]]--

-- Try to load the guide (called at login and as ADDON_LOADED fallback)
function addon:TryLoadGuide()
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if not scrollChild or not GLV.loadedGuides then return false end

    local activePack = GLV:GetActiveGuidePack()
    if activePack then
        GLV:PopulateDropdown(activePack)
        local _, race = UnitRace("player")
        GLV:LoadDefaultGuideForRace(race)
    else
        GLV:ShowNoGuideMessage()
    end
    return true
end

-- Event handler for PLAYER_LOGIN
function addon:OnPlayerLogin()
    if not self:TryLoadGuide() then
        self:RegisterEvent("ADDON_LOADED", function(addonName)
            if addonName == _ADDON_NAME then
                self:UnregisterEvent("ADDON_LOADED")
                self:TryLoadGuide()
            end
        end)
    end
end
