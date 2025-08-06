--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Guide Parser.
This file is used to extract every steps in the guide and format it
]]--
local GLV = LibStub("GuidelimeVanilla")

Parser = {}

function Parser:parseGuide(guide, group)
    local parsedGuide = {}
    
    parsedGuide.name = self:getGuideName(guide)
    parsedGuide.description = self:getGuideDescription(guide)
    parsedGuide.group = group
    parsedGuide.text = guide

    return parsedGuide
end

function Parser:getGuideName(guide)
    for line in string.gfind(guide, "[^\r\n]+") do
        local _, _, guideName = string.find(line, "^%[N%s(.-)%]$")
        if guideName then
            return guideName
        end
    end
    return nil
end

function Parser:getGuideDescription(guide)
    for line in string.gfind(guide, "[^\r\n]+") do
        local _, _, guideDescription = string.find(line, "^%[D%s(.-)%]$")
        if guideDescription then
            guideDescription = string.gsub(guideDescription, "\\", "\n")
            return guideDescription
        end
    end
    return nil
end

GLV.Parser = Parser