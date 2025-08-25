--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Trying to port Guidelime Guides to Vanilla (1.12).
This is the main file.
]]--
local _G = _G or getfenv()
local _ADDON_NAME = "GuidelimeVanilla"
local _VERSION = GetAddOnMetadata(_ADDON_NAME, "Version")

local GLV = LibStub("AceAddon-3.0"):NewAddon(_ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

local defaults = {
    char = {
        Locale = "enUS",
        TomTomEnabled = true,
        UI = {
            Locked = false,
            Opacity = 1,
            Scale = 1,
            Layer = "HIGH",
        },
        CharInfo = {
            Realm = "Unknown",
            Name = "Unknown",
            Faction = "Unknown",
            Race = "Unknown",
            Class = "Unknown",
        },
        Guide = {
            CurrentGroup = "Unknown",
            CurrentGuide = "Unknown",
            CurrentStep = 0,
            Guides = {},
        },
        QuestTracker = {
            Accepted = {},
            Completed = {},
            AutoObjectiveTracking = true,
        }
    }
}


--[[ DEFAULT ACE3 EVENTS ]]--

-- Initialize addon settings and database
function GLV:OnInitialize()
    DEFAULT_CHAT_FRAME:AddMessage(string.format("%s v%s", _ADDON_NAME, _VERSION))

    -- Set debug mode for testing
    GLV.Debug = true
    
    -- Initialize settings
    self.db = LibStub('AceDB-3.0'):New('GuidelimeVanillaDB', defaults)
    
    -- Set title after settings are initialized
    local mainTitle = _G["GLV_MainTitle"]
    if mainTitle then
        mainTitle:SetText(string.format("|cFF5B5FA4GuideLime|r |cFFA83E25Vanilla|r    |cFFFFFFFFv%s|r", _VERSION))
    end

end

-- Enable addon and initialize all modules
function GLV:OnEnable()
    local navigation = self:GetModule("Navigation")
    
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
        self.db.char.CharInfo[key] = val
    end

    self.db.char.Locale = GetLocale()

    -- Register events for proper timing
    self:RegisterEvent("VARIABLES_LOADED", "OnVariablesLoaded")
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
       
    -- Wait a bit for TomTom to load, then initialize
    self:ScheduleTimer(function()
        navigation:Init()
        
        -- Force update the waypoint for the current step after a delay
        self:ScheduleTimer(function()
            if GLV.CurrentGuide then
                local currentGuideId = self.db.char.Guide.CurrentGuide or "Unknown"
                local currentStep = self.db.char.Guide.Guides[currentGuideId].CurrentStep or 0
                
                if currentStep > 0 and GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[currentStep] then
                    local stepData = GLV.CurrentDisplaySteps[currentStep]
                    navigation:OnStepChanged(stepData)
                end
            end
        end, 1.0)
    end, 2.0) -- 2 seconds delay to ensure everything is loaded properly
end


--[[ EVENTS ]]--

-- Event handler for VARIABLES_LOADED
function GLV:OnVariablesLoaded()
    if GLV.loadedGuides then
        local totalGuides = 0
        for group, guides in pairs(GLV.loadedGuides) do
            if guides then
                for _ in pairs(guides) do totalGuides = totalGuides + 1 end
            end
        end
    end
end

-- Event handler for PLAYER_LOGIN
function GLV:OnPlayerLogin()
    local library = self:GetModule("Library")
    local defaultGroup = self.db.char.Guide.CurrentGroup or "Sage Guide"
    
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if scrollChild and GLV.loadedGuides then
        for group, guides in pairs(GLV.loadedGuides) do
            if guides and next(guides) then
                library:PopulateDropdown(group)
                
                local _, race = UnitRace("player")
                self:LoadDefaultGuideForRace(race)
                break
            end
        end
    else
        self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
    end
end

-- Event handler for ADDON_LOADED (one-time use)
function GLV:OnAddonLoaded(_, addonName)
    local library = self:GetModule("Library")
    if addonName == _ADDON_NAME then
        self:UnregisterEvent("ADDON_LOADED")
        
        local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
        if scrollChild and GLV.loadedGuides then
            for group, guides in pairs(GLV.loadedGuides) do
                if guides and next(guides) then
                    library:PopulateDropdown(group)
                    
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
function GLV:LoadDefaultGuideForRace(race)
    if not race then return end
    
    local library = self:GetModule("Library")
    local savedGuideId = self.db.char.Guide.CurrentGuide
    if savedGuideId and savedGuideId ~= "Unknown" then
        if GLV.loadedGuides and GLV.loadedGuides["Sage Guide"] then
            for guideId, guideData in pairs(GLV.loadedGuides["Sage Guide"]) do
                if guideId == savedGuideId then
                    library:LoadGuide("Sage Guide", guideId)
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
                library:LoadGuide("Sage Guide", guideId)
                break
            end
        end
    end
end
