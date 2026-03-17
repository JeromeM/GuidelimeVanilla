--[[
Guidelime Vanilla

Author: Grommey

Description:
Settings manager
]]--
local GLV = LibStub("GuidelimeVanilla")

local Settings = {}
GLV.Settings = Settings

local defaults = {
    char = {
        Locale = "enUS",
        NavigationEnabled = true,
        UI = {
            Locked = false,
            Opacity = 1,
            Scale = 1,
            Layer = "HIGH",
            GuideTextScale = 1,
            NavigationScale = 1,
            GuideVisibleSteps = 0,  -- 0=Big (full), 3=Small, 6=Medium (guide frame size)
        },
        CharInfo = {
            Realm = "Unknown",
            Name = "Unknown",
            Faction = "Unknown",
            Race = "Unknown",
            Class = "Unknown",
        },
        Guide = {
            ActivePack = nil,
            CurrentGroup = "Unknown",
            CurrentGuide = "Unknown",
            CurrentStep = 0,
            Guides = {},
        },
        QuestTracker = {
            Accepted = {},
            Completed = {},
            AutoObjectiveTracking = true,
        },
        TaxiTracker = {
            KnownTaxiNodes = {},
        },
        Automation = {
            AutoAcceptQuests = false,
            AutoTurninQuests = false,
            AutoTakeFlight = false,
        },
        Talents = {
            Enabled = true,
            ActiveTemplate = {},  -- {[class] = templateName}
            ShowPopupOnLevelUp = true,
            HighlightInFrame = true,
            ShowEndgameAtSixty = true,
            ToastPositionX = nil,  -- nil = default centered position
            ToastPositionY = nil,
        },
    }
}


-- Global storage defaults (account-wide, shared across all characters)
local globalDefaults = {
    GuideEditor = {
        Guides = {},
        LastOpenGuide = nil,
    },
}


--[[ OBJECTS FUNCTIONS ]]--

-- Get default settings configuration
function Settings:GetDefaults()
    return defaults
end

-- Initialize database and apply default values
function Settings:InitializeDB()
    if not GLV.Ace or not GLV.Ace.db then
        if GLV.Ace and GLV.Ace.ScheduleEvent then
            GLV.Ace:ScheduleEvent(function()
                if GLV.Ace and GLV.Ace.db then
                    self:InitializeDB()
                end
            end, 0.1)
        end
        return
    end
    
    self.db = GLV.Ace.db
    
    if self.db.char then
        for key, value in pairs(defaults.char) do
            if self.db.char[key] == nil then
                if type(value) == "table" then
                    self.db.char[key] = {}
                    for subKey, subValue in pairs(value) do
                        self.db.char[key][subKey] = subValue
                    end
                else
                    self.db.char[key] = value
                end
            elseif type(value) == "table" and type(self.db.char[key]) == "table" then
                for subKey, subValue in pairs(value) do
                    if self.db.char[key][subKey] == nil then
                        self.db.char[key][subKey] = subValue
                    end
                end
            end
        end
    end
end

-- Initialize global (account-wide) database
function Settings:InitializeGlobalDB()
    -- GuidelimeVanillaGlobalDB is a SavedVariables global, persisted by WoW
    if not GuidelimeVanillaGlobalDB then
        GuidelimeVanillaGlobalDB = {}
    end

    -- Apply defaults
    for key, value in pairs(globalDefaults) do
        if GuidelimeVanillaGlobalDB[key] == nil then
            if type(value) == "table" then
                GuidelimeVanillaGlobalDB[key] = {}
                for subKey, subValue in pairs(value) do
                    GuidelimeVanillaGlobalDB[key][subKey] = subValue
                end
            else
                GuidelimeVanillaGlobalDB[key] = value
            end
        elseif type(value) == "table" and type(GuidelimeVanillaGlobalDB[key]) == "table" then
            for subKey, subValue in pairs(value) do
                if GuidelimeVanillaGlobalDB[key][subKey] == nil then
                    GuidelimeVanillaGlobalDB[key][subKey] = subValue
                end
            end
        end
    end

    self.globalDB = GuidelimeVanillaGlobalDB
end

-- Get global option value using nested key array
function Settings:GetGlobalOption(keys)
    if not self.globalDB then
        self:InitializeGlobalDB()
    end

    local node = self.globalDB
    if type(keys) ~= "table" then return nil end

    for i = 1, safe_tablelen(keys) do
        if node == nil then return nil end
        node = node[keys[i]]
    end

    return node
end

-- Set global option value using nested key array
function Settings:SetGlobalOption(value, keys)
    if not self.globalDB then
        self:InitializeGlobalDB()
    end

    local node = self.globalDB
    if type(keys) ~= "table" then return end

    local len = safe_tablelen(keys)
    local lastKey = keys[len]

    for i = 1, len - 1 do
        local key = keys[i]
        if node[key] == nil then
            node[key] = {}
        end
        node = node[key]
    end

    node[lastKey] = value
end

-- Migrate per-character GuideEditor data to global storage (one-time)
function Settings:MigrateEditorToGlobal()
    if not self.globalDB then
        self:InitializeGlobalDB()
    end

    -- Check if per-character has guides to migrate
    local charGuides = self:GetOption({"GuideEditor", "Guides"})
    if not charGuides then return end

    local hasEntries = false
    for _ in pairs(charGuides) do hasEntries = true; break end
    if not hasEntries then return end

    -- Merge into global (don't overwrite existing global entries)
    local globalGuides = self.globalDB.GuideEditor.Guides
    for name, entry in pairs(charGuides) do
        if not globalGuides[name] then
            globalGuides[name] = entry
        end
    end

    -- Migrate LastOpenGuide if global doesn't have one
    if not self.globalDB.GuideEditor.LastOpenGuide then
        local lastOpen = self:GetOption({"GuideEditor", "LastOpenGuide"})
        if lastOpen then
            self.globalDB.GuideEditor.LastOpenGuide = lastOpen
        end
    end

    -- Clear per-character data
    self:SetOption({}, {"GuideEditor", "Guides"})
    self:SetOption(nil, {"GuideEditor", "LastOpenGuide"})
end

-- Get current profile from database
function Settings:GetProfile()
    if not self.db then 
        self:InitializeDB()
        if not self.db then
            return nil
        end
    end
    return self.db.char
end

-- Get option value using nested key array
function Settings:GetOption(keys)
    if not self.db then 
        self:InitializeDB()
        if not self.db then
            return nil
        end
    end
    
    local profile = self.db.char
    if type(keys) ~= "table" then return nil end

    for i = 1, safe_tablelen(keys) do
        if profile == nil then return nil end
        profile = profile[keys[i]]
    end

    return profile
end

-- Set option value using nested key array
function Settings:SetOption(value, keys)
    if not self.db then 
        self:InitializeDB()
        if not self.db then
            return
        end
    end
    
    local profile = self.db.char
    if type(keys) ~= "table" then return end

    local len = safe_tablelen(keys)
    local lastKey = keys[len]

    for i = 1, len - 1 do
        local key = keys[i]
        if profile[key] == nil then
            profile[key] = {}
        end
        profile = profile[key]
    end

    profile[lastKey] = value
end
