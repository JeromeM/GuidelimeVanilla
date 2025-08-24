--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Gossip Event Handler. Handle gossip events like innkeeper conversations.
]]--

local GLV = LibStub("GuidelimeVanilla")

local GossipTracker = {}
GLV.GossipTracker = GossipTracker

-- Initialize gossip tracking and register event handlers
function GossipTracker:Init()
    if GLV.Ace then
        GLV.Ace:RegisterEvent("GOSSIP_SHOW", function() self:OnGossipShow() end)
    end
end


--[[ EVENTS ]]--

-- Handle gossip show events and check for innkeeper interactions
function GossipTracker:OnGossipShow()
    local gossipOptions = {GetGossipOptions()}
    for i = 1, table.getn(gossipOptions), 2 do
        if gossipOptions[i] and string.find(gossipOptions[i], "Make this inn your home") then
            self:AutoUseHearthstone()
            break
        end
    end
end


--[[ OBJECTS FUNCTIONS ]]--

-- Automatically use hearthstone if current step requires binding
function GossipTracker:AutoUseHearthstone()
    local currentGuideId = GLV.Ace.db.char.Guide.CurrentGuide or "Unknown"
    local currentStep = GLV.Ace.db.char.Guide.Guides[currentGuideId].CurrentStep or 0
    
    if currentStep > 0 and GLV.CurrentGuide and GLV.CurrentGuide.steps then
        local stepData = GLV.CurrentGuide.steps[currentStep]
        if stepData and stepData.bindHearthstone then
            for bag = 0, 4 do
                local numSlots = GetContainerNumSlots(bag)
                if numSlots then
                    for slot = 1, numSlots do
                        local link = GetContainerItemLink(bag, slot)
                        if link and string.find(link, "item:6948:") then
                            UseContainerItem(bag, slot)
                            if GLV.Debug then
                                DEFAULT_CHAT_FRAME:AddMessage("GuidelimeVanilla: Hearthstone used automatically!")
                            end
                            return
                        end
                    end
                end
            end
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("GuidelimeVanilla: Hearthstone not found in your bags!")
            end
        end
    end
end
