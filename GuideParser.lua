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

--[[
guide = {
    group = "",
    name = "",
    description = "",
    faction = "",
    steps = {
        lines = {
            check = true|false,
            complete_with_next = true|false,
            text = "",
            coords = {
                x = "",
                y = "",
                z = ""
            }
        }
    },
    next = ""
}
]]

local codes = {
    N = "NAME",
    D = "DESCRIPTION",
    O = "OPTIONAL",
    OC = "OPTIONAL_COMPLETE_WITH_NEXT",
    GA = "GUIDE_APPLIES",
}

function SplitLinesPreserveEmpty(text)
    local lines = {}
    for line in string.gfind(text .. "\n", "([^\n]*)\n") do
        table.insert(lines, line)
    end
    return lines
end

function Parser:parseGuide(guide, group)
    local parsedGuide = {}
    local lines = SplitLinesPreserveEmpty(guide)

    for i, line in ipairs(lines) do
        if line == " " then
            DEFAULT_CHAT_FRAME:AddMessage("Ligne vide")
        end
    end

end

function Parser:_parseGuide(guide, group)
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