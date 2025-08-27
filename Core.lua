--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Trying to port Guidelime Guides to Vanilla (1.12).
This is the main file.
]]--
local _ADDON_NAME = "GuidelimeVanilla"
local _VERSION = GetAddOnMetadata(_ADDON_NAME, "Version")

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

    -- Set debug mode for testing
    GLV.Debug = true
    
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

    -- Register events for proper timing
    self:RegisterEvent("VARIABLES_LOADED", function() self:OnVariablesLoaded() end)
    self:RegisterEvent("PLAYER_LOGIN", function() self:OnPlayerLogin() end)
    
    if GLV.QuestTracker then
        GLV.QuestTracker:Init()
        GLV.CharacterTracker:Init()
    end
    
    if GLV.GossipTracker then
        GLV.GossipTracker:Init()
    end
    
    -- Initialize Guide Navigation integration AFTER the guide is loaded
    if GLV.GuideNavigation then
        self:ScheduleEvent(function()
            if GLV.GuideNavigation then
                GLV.GuideNavigation:Init()
            end
        end, 2.0)
    end
end


--[[ EVENTS ]]--

-- Event handler for VARIABLES_LOADED
function addon:OnVariablesLoaded()
    if GLV and GLV.loadedGuides then
        local totalGuides = 0
        for group, guides in pairs(GLV.loadedGuides) do
            if guides then
                for _ in pairs(guides) do totalGuides = totalGuides + 1 end
            end
        end
    end
end

-- Event handler for PLAYER_LOGIN
function addon:OnPlayerLogin()
    local defaultGroup = Settings:GetOption({"Guide", "CurrentGroup"}) or "Sage Guide"
    
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if scrollChild and GLV and GLV.loadedGuides then
        for group, guides in pairs(GLV.loadedGuides) do
            if guides and next(guides) then
                GLV:PopulateDropdown(group)
                
                local _, race = UnitRace("player")
                self:LoadDefaultGuideForRace(race)
                break
            end
        end
    else
        self:RegisterEvent("ADDON_LOADED", function() self:OnAddonLoaded() end)
    end
end

-- Event handler for ADDON_LOADED (one-time use)
function addon:OnAddonLoaded(addonName)
    if addonName == _ADDON_NAME then
        self:UnregisterEvent("ADDON_LOADED")
        
        local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
        if scrollChild and GLV and GLV.loadedGuides then
            for group, guides in pairs(GLV.loadedGuides) do
                if guides and next(guides) then
                    GLV:PopulateDropdown(group)
                    
                    local _, race = UnitRace("player")
                    self:LoadDefaultGuideForRace(race)
                    break
                end
            end
        end
    end
end


--[[ OBJECTS FUNCTIONS ]]--

-- Function to automatically load the appropriate guide based on player race
function addon:LoadDefaultGuideForRace(race)
    if not race then return end
    
    local savedGuideId = Settings:GetOption({"Guide", "CurrentGuide"})
    if savedGuideId and savedGuideId ~= "Unknown" then
        if GLV.loadedGuides and GLV.loadedGuides["Sage Guide"] then
            for guideId, guideData in pairs(GLV.loadedGuides["Sage Guide"]) do
                if guideId == savedGuideId then
                    GLV:LoadGuide("Sage Guide", guideId)
                    return
                end
            end
        end
    end
    
    local raceGuides = {
        ["Human"] = "Elwynn Forest",
        ["Dwarf"] = "Dun Morogh", 
        ["Gnome"] = "Dun Morogh",
        ["Night Elf"] = "Teldrassil"
    }
    
    local defaultGuideName = raceGuides[race]
    if not defaultGuideName then
        return
    end
    
    if GLV.loadedGuides and GLV.loadedGuides["Sage Guide"] then
        for guideId, guideData in pairs(GLV.loadedGuides["Sage Guide"]) do
            if guideData.name == defaultGuideName then
                GLV:LoadGuide("Sage Guide", guideId)
                break
            end
        end
    end
end
