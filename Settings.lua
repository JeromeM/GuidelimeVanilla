--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Settings manager
]]--
local GLV = LibStub("GuidelimeVanilla")

local Settings = {}

local defaults = {
    profile = {
        Locale = "enUS",
        TomTomEnabled = false,
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
            CurrentGuide = "Unknown",
            CurrentStep = 0,
        },
        QuestTracker = {
            Accepted = {},
            Completed = {},
        }
    }
}

function Settings:GetDefaults()
    return defaults
end

function Settings:InitializeDB()
    if not GLV.Ace or not GLV.Ace.db then
        error("GLV.Ace.db is not initialized yet!")
    end
    self.db = GLV.Ace.db
end

function Settings:GetProfile()
    if not self.db then self:InitializeDB() end
    return self.db.profile
end

function Settings:GetOption(keys)
    if not self.db then self:InitializeDB() end
    local profile = self.db.profile
    if type(keys) ~= "table" then return nil end

    for i = 1, safe_tablelen(keys) do
        if profile == nil then return nil end
        profile = profile[keys[i]]
    end

    return profile
end

-- Value is the first parameter, as we're going into multi table
function Settings:SetOption(value, keys)
    if not self.db then self:InitializeDB() end
    local profile = self.db.profile
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

GLV.Settings = Settings