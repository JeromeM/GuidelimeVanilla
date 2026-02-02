--[[
Guidelime Vanilla

Author: Grommey

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
        GLV.Ace:RegisterEvent("SPELLCAST_STOP", function() self:OnSpellcastStop() end)
        -- Hook ConfirmBinder to detect when hearthstone is bound
        GLV.Ace:Hook("ConfirmBinder", function()
            GLV.Ace.hooks["ConfirmBinder"]()
            -- Check after a short delay to let the game update
            GLV.Ace:ScheduleEvent("GLV_CheckHearthBind", function()
                self:CheckHearthstoneBind()
            end, 0.5)
        end)
    end

    -- Check after a delay to let guide load first
    GLV.Ace:ScheduleEvent("GLV_InitHearthCheck", function()
        self:CheckHearthstoneBind()
    end, 3)

    self.hearthstoneCasting = false
end

-- Track when hearthstone cast starts
function GossipTracker:OnSpellcastStop()
    -- Check hearthstone arrival after a short delay to let teleport complete
    GLV.Ace:ScheduleEvent("GLV_CheckHearthArrival", function()
        self:CheckHearthstoneArrival()
    end, 1.0)
end

-- Check if player arrived at hearthstone destination
function GossipTracker:CheckHearthstoneArrival()
    if not GLV.CurrentDisplaySteps then return end

    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepState"}) or {}
    local bindLocation = GetBindLocation() or ""

    local hasCompleted = false

    for displayIndex, stepData in ipairs(GLV.CurrentDisplaySteps) do
        if stepData.hasCheckbox and stepData.lines then
            for _, line in ipairs(stepData.lines) do
                if line.stepType == "HEARTHSTONE" and line.hearthDestination then
                    local dest = string.lower(line.hearthDestination)
                    local bind = string.lower(bindLocation)

                    -- Check if destination matches bind location (where hearthstone takes you)
                    if string.find(bind, dest) or string.find(dest, bind) then
                        local originalIndex = GLV.CurrentDisplayToOriginal[displayIndex]
                        if originalIndex and not stepState[originalIndex] then
                            stepState[originalIndex] = true
                            GLV.Settings:SetOption(stepState, {"Guide", "Guides", currentGuideId, "StepState"})
                            hasCompleted = true

                            if GLV.Debug then
                                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime]|r Hearthstone arrived at " .. line.hearthDestination)
                            end
                        end
                    end
                end
            end
        end
    end

    if hasCompleted then
        self:UpdateActiveStep()
        GLV:RefreshGuide()
    end
end

-- Update active step to next uncompleted step
function GossipTracker:UpdateActiveStep()
    if not GLV.CurrentGuide or not GLV.CurrentDisplaySteps then return end

    local guide = GLV.CurrentGuide
    local currentGuideId = guide.id or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepState"}) or {}
    local currentActiveStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0

    -- Find the next uncompleted step
    local newActiveStep = currentActiveStep
    local totalSteps = table.getn(GLV.CurrentDisplaySteps)

    for i = 1, totalSteps do
        if GLV.CurrentDisplaySteps[i] and GLV.CurrentDisplaySteps[i].hasCheckbox then
            local originalIndex = GLV.CurrentDisplayToOriginal[i]
            if originalIndex and not stepState[originalIndex] then
                newActiveStep = i
                break
            end
        end
    end

    -- Update active step if changed
    if newActiveStep ~= currentActiveStep then
        GLV.Settings:SetOption(newActiveStep, {"Guide", "Guides", currentGuideId, "CurrentStep"})
        GLV_MainLoadedGuideCounter:SetText("(" .. tostring(newActiveStep) .. "/" .. tostring(totalSteps) .. ")")

        -- Update navigation
        if GLV.GuideNavigation and GLV.CurrentDisplaySteps[newActiveStep] then
            GLV.GuideNavigation:UpdateWaypointForStep(GLV.CurrentDisplaySteps[newActiveStep])
        end
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

-- Check if hearthstone is bound to the required location and mark step complete
function GossipTracker:CheckHearthstoneBind()
    if not GLV.CurrentDisplaySteps then return end

    local currentBindLocation = GetBindLocation()
    if not currentBindLocation then return end

    -- Also get current zone/subzone for matching (inn names often differ from zone names)
    local currentSubZone = GetSubZoneText() or ""
    local currentZone = GetZoneText() or ""

    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepState"}) or {}
    local diCount = GLV.CurrentDisplayStepsCount or 0
    local diToOrig = GLV.CurrentDisplayToOriginal or {}

    local stepCompleted = false

    for di = 1, diCount do
        local step = GLV.CurrentDisplaySteps[di]
        local origIdx = diToOrig[di]

        if step and origIdx and not stepState[origIdx] then
            for _, line in ipairs(step.lines or {}) do
                if line.bindLocation then
                    -- Check if bind location matches (case insensitive, partial match)
                    local requiredLocation = string.lower(line.bindLocation)
                    local actualBind = string.lower(currentBindLocation)
                    local actualSubZone = string.lower(currentSubZone)
                    local actualZone = string.lower(currentZone)

                    -- Match against: inn name, subzone, or zone
                    local isMatch = string.find(actualBind, requiredLocation) or string.find(requiredLocation, actualBind)
                        or string.find(actualSubZone, requiredLocation) or string.find(requiredLocation, actualSubZone)
                        or string.find(actualZone, requiredLocation) or string.find(requiredLocation, actualZone)

                    if isMatch then
                        stepState[origIdx] = true
                        GLV.Settings:SetOption(stepState, {"Guide", "Guides", currentGuideId, "StepState"})
                        stepCompleted = true

                        if GLV.Debug then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime]|r Hearthstone bound to " .. currentBindLocation .. " (zone: " .. currentSubZone .. ") - step completed!")
                        end
                        break
                    end
                end
            end
        end
        if stepCompleted then break end
    end

    if stepCompleted then
        if GLV.QuestTracker then
            GLV.QuestTracker:UpdateStepNavigation(true, false)
        end
    end
end

-- Automatically use hearthstone if current step requires binding
function GossipTracker:AutoUseHearthstone()
    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
    
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
