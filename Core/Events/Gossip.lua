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
            -- Complete bind step immediately - if the player is on a [S] step and just
            -- confirmed binding, they're at the right inn (the guide sent them there).
            -- Location-based matching is unreliable inside buildings (subzone = inn name).
            GLV.Ace:ScheduleEvent("GLV_CheckHearthBind", function()
                self:CompleteBindStep()
            end, 0.5)
        end)
        -- Re-check on subzone change (e.g. exiting inn: "Stoutlager Inn" -> "Thelsamar")
        GLV.Ace:RegisterEvent("MINIMAP_ZONE_CHANGED", function()
            self:CheckHearthstoneBind()
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

-- Check if player arrived at hearthstone destination (current step only)
function GossipTracker:CheckHearthstoneArrival()
    if not GLV.CurrentDisplaySteps then return end

    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
    local stepState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepState"}) or {}
    local bindLocation = GetBindLocation() or ""

    if currentStep <= 0 then return end

    local stepData = GLV.CurrentDisplaySteps[currentStep]
    if not stepData or not stepData.hasCheckbox or not stepData.lines then return end

    local originalIndex = GLV.CurrentDisplayToOriginal[currentStep]
    if not originalIndex or stepState[originalIndex] then return end

    -- Get all zone texts for broader matching
    local currentSubZone = string.lower(GetSubZoneText() or "")
    local currentMinimapZone = string.lower(GetMinimapZoneText() or "")
    local currentZone = string.lower(GetZoneText() or "")

    for _, line in ipairs(stepData.lines) do
        if line.stepType == "HEARTHSTONE" and line.hearthDestination then
            local dest = string.lower(line.hearthDestination)
            local bind = string.lower(bindLocation)

            local isMatch = string.find(bind, dest) or string.find(dest, bind)
                or string.find(currentSubZone, dest) or string.find(dest, currentSubZone)
                or string.find(currentMinimapZone, dest) or string.find(dest, currentMinimapZone)
                or string.find(currentZone, dest) or string.find(dest, currentZone)

            if isMatch then
                stepState[originalIndex] = true
                GLV.Settings:SetOption(stepState, {"Guide", "Guides", currentGuideId, "StepState"})

                -- Cancel ALL pending hearthstone timers to prevent double-completion
                GLV.Ace:CancelScheduledEvent("GLV_HearthstoneComplete")  -- 12s click-handler timer
                GLV.Ace:CancelScheduledEvent("GLV_CheckHearthArrival")  -- SPELLCAST_STOP timer

                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime]|r Hearthstone arrived at " .. line.hearthDestination)
                end

                self:UpdateActiveStep()
                GLV:RefreshGuide()
                return
            end
        end
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

-- Complete current [S] bind step immediately when ConfirmBinder fires
-- No location check needed: the guide directed the player to this inn
function GossipTracker:CompleteBindStep()
    if not GLV.CurrentDisplaySteps then return end

    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
    local stepState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepState"}) or {}
    local diToOrig = GLV.CurrentDisplayToOriginal or {}

    if currentStep <= 0 then return end

    local step = GLV.CurrentDisplaySteps[currentStep]
    local origIdx = diToOrig[currentStep]

    if not step or not origIdx or stepState[origIdx] then return end

    for _, line in ipairs(step.lines or {}) do
        if line.bindLocation then
            stepState[origIdx] = true
            GLV.Settings:SetOption(stepState, {"Guide", "Guides", currentGuideId, "StepState"})

            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime]|r Hearthstone bound (ConfirmBinder) - step completed!")
            end

            if GLV.QuestTracker then
                GLV.QuestTracker:UpdateStepNavigation(true, false)
            end
            return
        end
    end
end

-- Check if hearthstone is bound to the required location and mark current step complete
-- Used for zone-change and /reload checks (location-based matching)
function GossipTracker:CheckHearthstoneBind()
    if not GLV.CurrentDisplaySteps then return end

    local currentBindLocation = GetBindLocation()
    if not currentBindLocation then return end

    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
    local stepState = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "StepState"}) or {}
    local diToOrig = GLV.CurrentDisplayToOriginal or {}

    if currentStep <= 0 then return end

    local step = GLV.CurrentDisplaySteps[currentStep]
    local origIdx = diToOrig[currentStep]

    if not step or not origIdx or stepState[origIdx] then return end

    for _, line in ipairs(step.lines or {}) do
        if line.bindLocation then
            -- Check if bind location matches (case insensitive, partial match)
            -- Only compare against GetBindLocation(), NOT zone/subzone texts
            -- (zone matching would false-positive when merely entering the area)
            local requiredLocation = string.lower(line.bindLocation)
            local actualBind = string.lower(currentBindLocation)

            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime]|r Bind check: required='" .. line.bindLocation .. "' bind='" .. currentBindLocation .. "'")
            end

            local isMatch = string.find(actualBind, requiredLocation) or string.find(requiredLocation, actualBind)

            if isMatch then
                stepState[origIdx] = true
                GLV.Settings:SetOption(stepState, {"Guide", "Guides", currentGuideId, "StepState"})

                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime]|r Hearthstone bound to " .. currentBindLocation .. " (zone: " .. currentSubZone .. ") - step completed!")
                end

                if GLV.QuestTracker then
                    GLV.QuestTracker:UpdateStepNavigation(true, false)
                end
                return
            end
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
