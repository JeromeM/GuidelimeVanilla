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
        }
    }
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
