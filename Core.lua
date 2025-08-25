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

local GLV = LibStub("AceAddon-3.0"):NewAddon(_ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

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
-- Initialize settings
GLV.db = LibStub('AceDB-3.0'):New('GuidelimeVanillaDB', defaults)

GLV.rawGuides = {}

--[[ DEFAULT ACE3 EVENTS ]]--

-- Initialize addon settings and database
function GLV:OnInitialize()
    DEFAULT_CHAT_FRAME:AddMessage(string.format("%s v%s", _ADDON_NAME, _VERSION))

    -- Set debug mode for testing
    GLV.Debug = true
    
    -- Set title after settings are initialized
    local mainTitle = _G["GLV_MainTitle"]
    if mainTitle then
        mainTitle:SetText(string.format("|cFF5B5FA4GuideLime|r |cFFA83E25Vanilla|r    |cFFFFFFFFv%s|r", _VERSION))
    end

    -- Register events for proper timing
    self:RegisterEvent("VARIABLES_LOADED", "OnVariablesLoaded")
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
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

    -- Wait a bit for TomTom to load, then initialize
    self:ScheduleTimer(function()
        -- navigation:Init()
        
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


-- Register a new guide with the system (only stores the raw data)
function GLV:RegisterGuide(guideText, group)
    if not self.rawGuides[group] then
        self.rawGuides[group] = {}
    end
    
    -- Generate a unique ID for the guide
    local guideId = "guide_" .. math.random(1000,9999)
    
    -- Store only the raw guide data
    self.rawGuides[group][guideId] = {
        text = guideText,
        group = group
    }
end


--[[ EVENTS ]]--

-- Event handler for VARIABLES_LOADED
function GLV:OnVariablesLoaded()
    local library = self:GetModule("Library")
    if library and library.loadedGuides then
        local totalGuides = 0
        for group, guides in pairs(library.loadedGuides) do
            if guides then
                for _ in pairs(guides) do totalGuides = totalGuides + 1 end
            end
        end
    end
end

-- Event handler for PLAYER_LOGIN
function GLV:OnPlayerLogin()
    local library = self:GetModule("Library")

    DumpTable(self.rawGuides)
    
    -- Activate all registered guides first
    library:ActivateGuides()
    
    local defaultGroup = self.db.char.Guide.CurrentGroup or "Sage Guide"
    
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if scrollChild and library.loadedGuides then
        for group, guides in pairs(library.loadedGuides) do
            if guides and next(guides) then
                library:PopulateDropdown(group)
                
                local _, race = UnitRace("player")
                self:LoadDefaultGuideForRace(race)
                break
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
        if library.loadedGuides and library.loadedGuides["Sage Guide"] then
            for guideId, guideData in pairs(library.loadedGuides["Sage Guide"]) do
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
    
    if library.loadedGuides and library.loadedGuides["Sage Guide"] then
        for guideId, guideData in pairs(library.loadedGuides["Sage Guide"]) do
            if guideData.name == defaultGuideName then
                library:LoadGuide("Sage Guide", guideId)
                break
            end
        end
    end
end
