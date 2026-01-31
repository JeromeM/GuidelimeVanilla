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

    -- Set debug mode for testing
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
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() self:OnZoneChanged() end)
    
    -- Add Events Loading
    GLV.QuestTracker:Init()
    GLV.CharacterTracker:Init()
    GLV.TaxiTracker:Init()
    GLV.GossipTracker:Init()
    GLV.EquipmentTracker:Init()
    GLV.ItemTracker:Init()
    
    -- Initialize Guide Navigation integration AFTER the guide is loaded
    self:ScheduleEvent(function()
        if GLV.GuideNavigation then
            GLV.GuideNavigation:Init()
        end
    end, 2.0)
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
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if scrollChild and GLV and GLV.loadedGuides then
        local hasGuides = false
        for group, guides in pairs(GLV.loadedGuides) do
            if guides and next(guides) then
                hasGuides = true
                break
            end
        end

        local activePack = GLV:GetActiveGuidePack()
        if activePack then
            GLV:PopulateDropdown(activePack)
            local _, race = UnitRace("player")
            self:LoadDefaultGuideForRace(race)
        else
            -- No pack selected (or no packs installed)
            GLV:ShowNoGuideMessage()
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
            local hasGuides = false
            for group, guides in pairs(GLV.loadedGuides) do
                if guides and next(guides) then
                    hasGuides = true
                    break
                end
            end

            local activePack = GLV:GetActiveGuidePack()
            if activePack then
                GLV:PopulateDropdown(activePack)
                local _, race = UnitRace("player")
                self:LoadDefaultGuideForRace(race)
            else
                -- No pack selected (or no packs installed)
                GLV:ShowNoGuideMessage()
            end
        end
    end
end

-- Event handler for ZONE_CHANGED_NEW_AREA
function addon:OnZoneChanged()
    -- Delay the waypoint refresh to let Astrolabe update its position
    self:ScheduleEvent(function()
        -- Force map to update to current zone before getting position
        if not WorldMapFrame:IsVisible() then
            SetMapToCurrentZone()
        end
        self:RefreshNavigationForCurrentStep()
        -- Also check hearthstone arrival on zone change (in case player hearthed to different zone)
        if GLV.GossipTracker then
            GLV.GossipTracker:CheckHearthstoneArrival()
        end
    end, 0.5)
end

-- Refresh navigation waypoint for current step (called after zone change with delay)
function addon:RefreshNavigationForCurrentStep()
    if not GLV.GuideNavigation or not GLV.CurrentDisplaySteps then
        return
    end

    local currentGuideId = Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStep = Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0

    if currentStep > 0 and GLV.CurrentDisplaySteps[currentStep] then
        local stepData = GLV.CurrentDisplaySteps[currentStep]
        GLV.GuideNavigation:UpdateWaypointForStep(stepData)
    end
end


--[[ OBJECTS FUNCTIONS ]]--

-- Function to automatically load the appropriate guide based on player level and race
function addon:LoadDefaultGuideForRace(race)
    local activePack = GLV:GetActiveGuidePack()
    if not activePack then return end

    local guides = GLV.loadedGuides[activePack]
    if not guides then return end

    -- First, try to load saved guide
    local savedGuideId = Settings:GetOption({"Guide", "CurrentGuide"})
    if savedGuideId and savedGuideId ~= "Unknown" and guides[savedGuideId] then
        GLV:LoadGuide(activePack, savedGuideId)
        self:SyncQuestJournalWithGuide()
        return
    end

    -- Load guide based on player level and race
    local playerLevel = UnitLevel("player")
    local bestGuide = nil

    -- For low level players (1-11), use race-based starting guides
    if playerLevel <= 11 and race then
        bestGuide = self:FindStartingGuideForRace(race, activePack)
    end

    -- For higher level players, or if no race guide found, use level-based selection
    if not bestGuide then
        bestGuide = self:FindBestGuideForLevel(playerLevel, activePack)
    end

    if bestGuide then
        GLV:LoadGuide(activePack, bestGuide.id)
        self:SyncQuestJournalWithGuide()
    end
end

-- Find starting guide based on player race for new characters
function addon:FindStartingGuideForRace(race, packName)
    local guides = GLV.loadedGuides[packName]
    if not guides then return nil end

    -- Get the starting guide name from the pack's registered mapping
    local targetGuideName = GLV:GetStartingGuideForRace(packName, race)
    if not targetGuideName then return nil end

    for guideId, guideData in pairs(guides) do
        if guideData.name == targetGuideName then
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Guide Loading]|r Selected starting guide: " .. guideData.name .. " for " .. race)
            end
            return {id = guideId, data = guideData}
        end
    end

    return nil
end

-- Find the best guide for player's current level
function addon:FindBestGuideForLevel(playerLevel, packName)
    local guides = GLV.loadedGuides[packName]
    if not guides then return nil end

    local bestGuide = nil
    local bestMatch = 999

    for guideId, guideData in pairs(guides) do
        if guideData.minLevel and guideData.maxLevel then
            local minLevel = tonumber(guideData.minLevel)
            local maxLevel = tonumber(guideData.maxLevel)

            if minLevel and maxLevel then
                -- Check if player level fits in guide range
                if playerLevel >= minLevel and playerLevel <= maxLevel then
                    -- Perfect match - player level is in guide range
                    bestGuide = {id = guideId, data = guideData}
                    break
                elseif minLevel <= playerLevel then
                    -- Guide is below player level, but could be close
                    local levelDiff = playerLevel - maxLevel
                    if levelDiff < bestMatch then
                        bestMatch = levelDiff
                        bestGuide = {id = guideId, data = guideData}
                    end
                end
            end
        end
    end

    if GLV.Debug then
        if bestGuide then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Guide Loading]|r Selected guide: " .. bestGuide.data.name .. " for level " .. playerLevel)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Guide Loading]|r No suitable guide found for level " .. playerLevel)
        end
    end

    return bestGuide
end

-- Sync quest journal with loaded guide (auto-check [QA] steps for quests in journal)
function addon:SyncQuestJournalWithGuide()
    if not GLV.CurrentGuide or not GLV.CurrentGuide.steps then
        return
    end
    
    -- Get all quests currently in player's journal
    local questsInJournal = self:GetQuestsInJournal()
    
    -- Find [QA] steps that match quests in journal and mark them as completed
    local currentGuideId = GLV.CurrentGuide.id or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide","Guides", currentGuideId, "StepState"}) or {}
    local foundMatches = 0
    
    for stepIndex, step in ipairs(GLV.CurrentGuide.steps) do
        if step.questTags then
            for _, questTag in ipairs(step.questTags) do
                if questTag.tag == "ACCEPT" and questTag.questId then
                    -- Check if this quest is in player's journal
                    if questsInJournal[questTag.questId] then
                        stepState[stepIndex] = true
                        foundMatches = foundMatches + 1
                        
                        if GLV.Debug then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Quest Sync]|r Auto-checked: " .. (questTag.title or "Quest " .. questTag.questId))
                        end
                    end
                end
            end
        end
    end
    
    if foundMatches > 0 then
        GLV.Settings:SetOption(stepState, {"Guide","Guides", currentGuideId, "StepState"})
        
        -- Refresh the guide UI to show the checked boxes
        if GLV.RefreshGuide then
            GLV:RefreshGuide()
        end
        
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Quest Sync]|r Synchronized " .. foundMatches .. " quest accepts with journal")
        end
    end
end

-- Get all quests currently in player's journal
function addon:GetQuestsInJournal()
    local questsInJournal = {}
    local numEntries, numQuests = GetNumQuestLogEntries()
    
    for i = 1, numEntries do
        local title, level, tag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i)
        if title and not isHeader then
            -- Try to get quest ID from title
            local questId = GLV:GetQuestIDByName(title)
            if questId then
                local numId = tonumber(questId)
                if numId then
                    questsInJournal[numId] = {
                        title = title,
                        level = level,
                        isComplete = isComplete
                    }
                end
            end
        end
    end
    
    return questsInJournal
end
