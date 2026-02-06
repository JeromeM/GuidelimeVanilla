--[[
Guidelime Vanilla

Author: Grommey

Description:
Item Tracker. Track when items are collected in bags and auto-complete "Collect Item" steps.
]]--
local _G = _G or getfenv(0)
local GLV = LibStub("GuidelimeVanilla")

local ItemTracker = {}
GLV.ItemTracker = ItemTracker

-- Initialize item tracking
function ItemTracker:Init()
    if GLV.Ace then
        GLV.Ace:RegisterEvent("BAG_UPDATE", function()
            self:OnBagUpdate()
        end)
    end

    -- Check after a delay to let guide load first
    GLV.Ace:ScheduleEvent("GLV_InitItemCheck", function()
        self:CheckCollectItems()
    end, 3)
end

-- Count how many of an item the player has in their bags
function ItemTracker:GetItemCount(itemId)
    if not itemId then return 0 end

    local itemIdNum = tonumber(itemId)
    if not itemIdNum then return 0 end

    local totalCount = 0

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    -- Extract item ID from link: |cff9d9d9d|Hitem:ITEMID:...|h[Name]|h|r
                    local bagItemId = tonumber(string.match(link, "item:(%d+)"))
                    if bagItemId and bagItemId == itemIdNum then
                        local _, count = GetContainerItemInfo(bag, slot)
                        totalCount = totalCount + (count or 1)
                    end
                end
            end
        end
    end

    return totalCount
end

-- Handle bag updates
function ItemTracker:OnBagUpdate()
    -- Small delay to let the bag update complete
    GLV.Ace:ScheduleEvent("GLV_CheckCollectItems", function()
        self:CheckCollectItems()
    end, 0.3)
end

-- Check collect item requirements for the current active step only
function ItemTracker:CheckCollectItems()
    if not GLV.CurrentDisplaySteps then return end

    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
    local stepState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepState"}) or {}
    local diToOrig = GLV.CurrentDisplayToOriginal or {}

    if currentStep <= 0 then return end

    local step = GLV.CurrentDisplaySteps[currentStep]
    local origIdx = diToOrig[currentStep]

    if not step or not origIdx or stepState[origIdx] then return end

    -- Check if this step has collect item requirements
    local allItemsCollected = true
    local hasCollectItems = false

    if step.lines then
        for _, line in ipairs(step.lines) do
            if line.collectItems then
                for _, collectItem in ipairs(line.collectItems) do
                    hasCollectItems = true
                    local currentCount = self:GetItemCount(collectItem.itemId)
                    if currentCount < collectItem.count then
                        allItemsCollected = false
                        break
                    end
                end
            end
            if not allItemsCollected then break end
        end
    end

    if hasCollectItems and allItemsCollected then
        stepState[origIdx] = true

        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Items]|r Auto-completed: Collect items step (step " .. currentStep .. ")")
        end

        GLV.Settings:SetOption(stepState, {"Guide", "Guides", currentGuideId, "StepState"})

        if GLV.QuestTracker then
            GLV.QuestTracker:UpdateStepNavigation(true, false)
        end
    end
end
