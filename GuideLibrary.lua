--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
This is where Guides are registered.
A Guide is another Addon, and every lua (guides) file must begins with :
local GLV = LibStub("GuidelimeVanilla")
GLV:RegisterGuide(TEXT GUIDE, "Group Name")
]]--
local GLV = LibStub("GuidelimeVanilla")

loadedGuides = loadedGuides or {}

function GLV:RegisterGuide(guideText, group)
    guide = self.Parser:parseGuide(guideText, group)

    if not loadedGuides[guide.group] then
        loadedGuides[guide.group] = {}
    end

    if guide.name ~= nil then
        if not loadedGuides[guide.group][guide.name] then
            loadedGuides[guide.group][guide.name] = guide.text
        else
            self.Ace:Print("Guide déjà chargé : " .. guide.name)
        end
    end

end