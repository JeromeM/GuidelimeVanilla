--[[
Guidelime Vanilla

Author: Grommey

Description:
Everything Taxi related. Get flypath, Take flypath, ..
]]--

local GLV = LibStub("GuidelimeVanilla")

local TaxiTracker = {}
GLV.TaxiTracker = TaxiTracker


-- Initialize character tracking and register event handlers
function TaxiTracker:Init()
    self.knownTaxiNodes = {}
    self.pendingCheck = false
    self.pendingFlyTo = nil  -- Track pending fly destination

    if GLV.Ace then
        GLV.Ace:RegisterEvent("TAXIMAP_OPENED", function() self:OnTaxiMapOpened() end)
        GLV.Ace:RegisterEvent("TAXIMAP_CLOSED", function() self:OnTaxiMapClosed() end)
    end

    -- Hook TakeTaxiNode to capture flight destination
    self:HookTakeTaxiNode()

    local knownTaxiNodes = GLV.Settings:GetOption({"TaxiTracker", "KnownTaxiNodes"}) or {}
    self.knownTaxiNodes = knownTaxiNodes

    -- Debug: display known flight paths on load
    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TaxiTracker]|r Loaded " .. self:CountKnownNodes() .. " known taxi nodes")
    end
end

-- Hook TakeTaxiNode to detect when player takes a flight
function TaxiTracker:HookTakeTaxiNode()
    if self.hookedTakeTaxiNode then return end

    local originalTakeTaxiNode = TakeTaxiNode
    TakeTaxiNode = function(nodeIndex)
        -- Get destination name before taking the taxi
        local destName = TaxiNodeName(nodeIndex)
        if destName then
            self.pendingFlyTo = destName
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TaxiTracker]|r Taking flight to: " .. destName)
            end
        end
        -- Call original function
        return originalTakeTaxiNode(nodeIndex)
    end

    self.hookedTakeTaxiNode = true
end

function TaxiTracker:OnTaxiMapClosed()
    -- If we have a pending fly destination, complete matching FLY_TO steps
    if self.pendingFlyTo then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TaxiTracker]|r Taxi map closed, checking FLY_TO steps for: " .. self.pendingFlyTo)
        end
        self:CheckAndCompleteFlyToSteps(self.pendingFlyTo)
        self.pendingFlyTo = nil
    end
end

function TaxiTracker:OnTaxiMapOpened()
    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TaxiTracker]|r Taxi map opened")
    end
    self:CheckForNewFlightPaths()
    self:CheckAutoFlight()
end

-- Check if current step is a FLY_TO and auto-take flight if enabled
function TaxiTracker:CheckAutoFlight()
    local autoFlight = GLV.Settings:GetOption({"Automation", "AutoTakeFlight"})
    if not autoFlight then return end

    if not GLV.CurrentDisplaySteps then return end

    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0

    if currentStepIndex <= 0 or currentStepIndex > table.getn(GLV.CurrentDisplaySteps) then
        return
    end

    local step = GLV.CurrentDisplaySteps[currentStepIndex]
    if not step or not step.lines then return end

    -- Find FLY_TO destination in current step
    local flyToDestination = nil
    for _, line in ipairs(step.lines) do
        if line.stepType == "FLY_TO" and line.destination then
            flyToDestination = line.destination
            break
        end
    end

    if not flyToDestination then return end

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TaxiTracker]|r Looking for flight to: " .. flyToDestination)
    end

    -- Search taxi nodes for matching destination
    local numNodes = NumTaxiNodes()
    for i = 1, numNodes do
        local nodeName = TaxiNodeName(i)
        local nodeType = TaxiNodeGetType(i)

        if nodeType == "REACHABLE" and nodeName then
            if self:IsFlightPathMatch(flyToDestination, nodeName) then
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TaxiTracker]|r Auto-taking flight to: " .. nodeName)
                end
                TakeTaxiNode(i)
                return
            end
        end
    end

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[TaxiTracker]|r No matching flight found for: " .. flyToDestination)
    end
end

function TaxiTracker:CheckForNewFlightPaths()   
    local newNodes = {}
    local discoveredNew = false
    
    local numNodes = NumTaxiNodes()
    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TaxiTracker]|r Scanning " .. numNodes .. " taxi nodes")
    end
    
    for i = 1, numNodes do
        local name = TaxiNodeName(i)
        local nodeType = TaxiNodeGetType(i)
        
        if name and (nodeType == "CURRENT" or nodeType == "REACHABLE") then
            newNodes[name] = true
            
            -- Check if this is a new node
            if not self.knownTaxiNodes[name] then
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TaxiTracker]|r New flight path discovered: " .. name)
                end
                self:OnFlightPathDiscovered(name, i)
                discoveredNew = true
            end
        end
    end
    
    for nodeName, _ in pairs(newNodes) do
        self.knownTaxiNodes[nodeName] = true
    end
    
    if discoveredNew then
        self:SaveKnownTaxiNodes()
    end

end

function TaxiTracker:OnFlightPathDiscovered(flightPathName, nodeIndex)
    if GLV.Debug then
        GLV.Ace:Print("TaxiTracker", "Flight path discovered: " .. flightPathName .. " (index: " .. nodeIndex .. ")")
    end

    -- Trigger event with details
    self:TriggerEvent("GLV_FLIGHT_PATH_DISCOVERED", flightPathName, nodeIndex)

    -- Auto-complete guide steps for this flight path
    self:CheckAndCompleteGuideSteps(flightPathName)
end

-- Check and complete FLY_TO steps when player takes a flight
function TaxiTracker:CheckAndCompleteFlyToSteps(destinationName)
    if not GLV.CurrentGuide or not GLV.CurrentDisplaySteps then
        return
    end

    local guide = GLV.CurrentGuide
    local currentGuideId = guide.id or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide","Guides", currentGuideId, "StepState"}) or {}
    local hasCompletedStep = false

    if GLV.Debug then
        GLV.Ace:Print("TaxiTracker", "Checking FLY_TO steps for destination: " .. destinationName)
    end

    -- Iterate through all steps in the current guide
    for displayIndex, stepData in ipairs(GLV.CurrentDisplaySteps) do
        if stepData.hasCheckbox and stepData.lines then
            for _, line in ipairs(stepData.lines) do
                if line.stepType == "FLY_TO" and line.destination then
                    if self:IsFlightPathMatch(line.destination, destinationName) then
                        local originalIndex = GLV.CurrentDisplayToOriginal[displayIndex]

                        if originalIndex and not stepState[originalIndex] then
                            -- Don't auto-complete if step also has quest tags (QA/QC/QT)
                            -- The quest tracker will handle final completion
                            if stepData.questTags and table.getn(stepData.questTags) > 0 then
                                if GLV.Debug then
                                    GLV.Ace:Print("TaxiTracker", "FLY_TO matched but step has quest tags, skipping auto-complete for step " .. displayIndex)
                                end
                                break
                            end

                            stepState[originalIndex] = true
                            GLV.Settings:SetOption(stepState, {"Guide","Guides", currentGuideId, "StepState"})

                            -- Deactivate ongoing step if it was active
                            if GLV.OngoingStepsManager and GLV.OngoingStepsManager:IsActive(displayIndex) then
                                GLV.OngoingStepsManager:Deactivate(displayIndex)
                            end

                            hasCompletedStep = true

                            if GLV.Debug then
                                GLV.Ace:Print("TaxiTracker", "Auto-completed FLY_TO step " .. displayIndex .. " for: " .. destinationName)
                            end
                        end
                    end
                end
            end
        end
    end

    if hasCompletedStep then
        self:UpdateActiveStep()
        GLV:RefreshGuide()
    end
end

-- Check and complete GET_FP steps when a new flight path is discovered
function TaxiTracker:CheckAndCompleteGuideSteps(flightPathName)
    if not GLV.CurrentGuide or not GLV.CurrentDisplaySteps then
        return
    end

    local guide = GLV.CurrentGuide
    local currentGuideId = guide.id or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide","Guides", currentGuideId, "StepState"}) or {}
    local hasCompletedStep = false

    if GLV.Debug then
        GLV.Ace:Print("TaxiTracker", "Checking GET_FP steps for: " .. flightPathName)
    end

    -- Iterate through all steps in the current guide
    for displayIndex, stepData in ipairs(GLV.CurrentDisplaySteps) do
        if stepData.hasCheckbox and stepData.lines then
            for _, line in ipairs(stepData.lines) do
                if line.stepType == "GET_FP" and line.destination then
                    if self:IsFlightPathMatch(line.destination, flightPathName) then
                        local originalIndex = GLV.CurrentDisplayToOriginal[displayIndex]

                        if originalIndex and not stepState[originalIndex] then
                            stepState[originalIndex] = true
                            GLV.Settings:SetOption(stepState, {"Guide","Guides", currentGuideId, "StepState"})

                            -- Deactivate ongoing step if it was active
                            if GLV.OngoingStepsManager and GLV.OngoingStepsManager:IsActive(displayIndex) then
                                GLV.OngoingStepsManager:Deactivate(displayIndex)
                            end

                            hasCompletedStep = true

                            if GLV.Debug then
                                GLV.Ace:Print("TaxiTracker", "Auto-completed GET_FP step " .. displayIndex .. " for: " .. flightPathName)
                            end
                        end
                    end
                end
            end
        end
    end

    if hasCompletedStep then
        self:UpdateActiveStep()
        GLV:RefreshGuide()
    end
end

function TaxiTracker:IsFlightPathMatch(stepName, discoveredName)
    if not stepName or not discoveredName then return false end

    local stepLower = string.lower(stepName)
    local discoveredLower = string.lower(discoveredName)

    -- Exact match
    if stepLower == discoveredLower then
        return true
    end

    -- Partial match (one contains the other)
    if string.find(stepLower, discoveredLower) or string.find(discoveredLower, stepLower) then
        return true
    end

    -- Specific aliases to handle name variations
    local aliases = {
        ["stormwind"] = {"stormwind city", "stormwind keep"},
        ["ironforge"] = {"ironforge city"},
        ["orgrimmar"] = {"orgrimmar city"},
        ["undercity"] = {"undercity", "tirisfal"},
    }
    
    for canonical, variants in pairs(aliases) do
        if stepLower == canonical or discoveredLower == canonical then
            for _, variant in ipairs(variants) do
                if stepLower == variant or discoveredLower == variant then
                    return true
                end
            end
        end
    end
    
    return false
end

function TaxiTracker:UpdateActiveStep()
    if not GLV.CurrentGuide or not GLV.CurrentDisplaySteps then return end
    
    local guide = GLV.CurrentGuide
    local currentGuideId = guide.id or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide","Guides", currentGuideId, "StepState"}) or {}
    local currentActiveStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0

    -- Find the next uncompleted step
    local newActiveStep = currentActiveStep
    local totalSteps = table.getn(GLV.CurrentDisplaySteps)
    
    for i = currentActiveStep, totalSteps do
        if GLV.CurrentDisplaySteps[i] and GLV.CurrentDisplaySteps[i].hasCheckbox then
            local originalIndex = GLV.CurrentDisplayToOriginal[i]
            if originalIndex and not stepState[originalIndex] then
                newActiveStep = i
                break
            end
        end
    end
    
    -- If a new active step was found, update it
    if newActiveStep ~= currentActiveStep then
        GLV.Settings:SetOption(newActiveStep, {"Guide", "Guides", currentGuideId, "CurrentStep"})
        GLV_MainLoadedGuideCounter:SetText("("..tostring(newActiveStep).."/"..tostring(totalSteps)..")")

        -- Update visual colors using unified highlighting system
        local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
        if scrollChild and GLV.updateStepColors and GLV.CurrentDisplaySteps then
            GLV.updateStepColors(scrollChild, currentGuideId, GLV.CurrentDisplaySteps, newActiveStep)
        end

        -- Scroll to the new active step
        if GLV_MainScrollFrame and newActiveStep > 0 then
            GLV.Ace:ScheduleEvent(function()
                if GLV_MainScrollFrame then
                    local targetScroll = 0
                    local scrollChild = GLV_MainScrollFrameScrollChild
                    
                    for i = 1, newActiveStep - 1 do
                        local stepFrame = getglobal(scrollChild:GetName().."Step"..currentGuideId.."_"..i)
                        if stepFrame and stepFrame.GetHeight then
                            targetScroll = targetScroll + stepFrame:GetHeight()
                        end
                    end
                    
                    if newActiveStep > 1 then
                        targetScroll = targetScroll + (4 * (newActiveStep - 1)) -- spacing
                    end
                    
                    targetScroll = math.max(0, targetScroll)
                    local maxScroll = GLV_MainScrollFrame:GetVerticalScrollRange()
                    if maxScroll and maxScroll > 0 then
                        targetScroll = math.min(targetScroll, maxScroll)
                    end
                    GLV_MainScrollFrame:SetVerticalScroll(targetScroll)
                end
            end, 0.5)
        end
        
        if GLV.Debug then
            GLV.Ace:Print("TaxiTracker", "Updated active step to: " .. newActiveStep)
        end
    end
end

-- Utility functions
function TaxiTracker:SaveKnownTaxiNodes()
    GLV.Settings:SetOption(self.knownTaxiNodes, {"TaxiTracker", "KnownTaxiNodes"})
    if GLV.Debug then
        GLV.Ace:Print("TaxiTracker", "Saved " .. self:CountKnownNodes() .. " known taxi nodes")
    end
end

function TaxiTracker:CountKnownNodes()
    local count = 0
    for _ in pairs(self.knownTaxiNodes) do
        count = count + 1
    end
    return count
end

function TaxiTracker:IsFlightPathKnown(nodeName)
    return self.knownTaxiNodes[nodeName] == true
end

function TaxiTracker:GetKnownFlightPaths()
    local paths = {}
    for nodeName, _ in pairs(self.knownTaxiNodes) do
        table.insert(paths, nodeName)
    end
    return paths
end

function TaxiTracker:TriggerEvent(eventName, ...)
    if not self.eventCallbacks then
        self.eventCallbacks = {}
    end
    
    if self.eventCallbacks[eventName] then
        for _, callback in pairs(self.eventCallbacks[eventName]) do
            callback(unpack(arg))
        end
    end
end

function TaxiTracker:RegisterCallback(eventName, callback)
    if not self.eventCallbacks then
        self.eventCallbacks = {}
    end
    if not self.eventCallbacks[eventName] then
        self.eventCallbacks[eventName] = {}
    end
    table.insert(self.eventCallbacks[eventName], callback)
end
