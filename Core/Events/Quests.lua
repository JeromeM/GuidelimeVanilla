--[[
Guidelime Vanilla

Author: Grommey

Description:
Quest Tracker. Track when quests are accepted / completed
]]--
local _G = _G or getfenv(0)
local GLV = LibStub("GuidelimeVanilla")

local QuestTracker = {}
GLV.QuestTracker = QuestTracker

local CONFIG = {
    colors = {
        even = {0.2,0.2,0.2,0.8},
        odd = {0.1,0.1,0.1,0.8},
        active = {0.8,0.8,0.2,0.9}
    }
}

-- Throttle control for quest log updates
local lastQuestLogUpdate = 0
local QUEST_LOG_UPDATE_THROTTLE = 0.5 -- Only process once per 0.5 seconds

-- Check if a quest tag matches a given quest action (accept/complete/turnin)
-- Returns true if the tag matches the action type, quest ID (or name for COMPLETE), and objective index
local function DoesQuestActionMatch(questTag, questId, title, actionType, objectiveIndex)
    if questTag.tag ~= actionType then return false end

    local questIdMatches = tonumber(questTag.questId) == tonumber(questId)
    local nameMatches = false
    if actionType == "COMPLETE" and title then
        local tagQuestName = GLV:GetQuestNameByID(questTag.questId)
        nameMatches = tagQuestName and GLV.QuestTracker:QuestNamesMatch(tagQuestName, title)
    end
    if not questIdMatches and not nameMatches then return false end

    if questTag.objectiveIndex then
        return objectiveIndex and questTag.objectiveIndex == objectiveIndex
    else
        return not objectiveIndex
    end
end

-- Check if all quest actions for a step are marked as done in stepQuestState
local function AreAllActionsDone(stepQuestState, origIdx, questTags)
    if not stepQuestState[origIdx] then return false end
    for _, questTag in ipairs(questTags) do
        if not stepQuestState[origIdx][GLV.BuildActionKey(questTag)] then
            return false
        end
    end
    return true
end

-- Initialize quest tracking, hook original functions and register event handlers
function QuestTracker:Init()
    local store = GLV.Settings:GetOption({"QuestTracker"}) or {}
    self.store = store

    if GLV.Ace then
        GLV.Ace:Hook("QuestDetailAcceptButton_OnClick", HookQuestAccept)
        GLV.Ace:Hook("QuestRewardCompleteButton_OnClick", HookQuestComplete)
        GLV.Ace:Hook("AbandonQuest", HookQuestAbandon)

        GLV.Ace:RegisterEvent("QUEST_LOG_UPDATE", function() self:OnQuestLogUpdate() end)
        GLV.Ace:RegisterEvent("UNIT_QUEST_LOG_CHANGED", function(unit)
            if unit == "player" then self:OnQuestLogUpdate() end
        end)
        GLV.Ace:RegisterEvent("BAG_UPDATE", function() self:OnQuestLogUpdate() end)
        -- Delayed check after looting to give game time to update quest log
        GLV.Ace:RegisterEvent("CHAT_MSG_LOOT", function()
            GLV.Ace:ScheduleEvent("GLV_LootQuestCheck", function()
                self:OnQuestLogUpdate(true)  -- Force check, bypass throttle
            end, 0.5)
        end)

        -- Auto accept/turnin events
        GLV.Ace:RegisterEvent("QUEST_DETAIL", function() self:OnQuestDetail() end)
        GLV.Ace:RegisterEvent("QUEST_COMPLETE", function() self:OnQuestComplete() end)
    end
    
    self.previousQuestStates = {}
end


--[[ LOCAL FUNCTIONS ]]--

-- Old applyHighlighting function removed - now using unified system from GuideWriter


--[[ EVENTS ]]--

-- Handle quest log updates and check for completed objectives
function QuestTracker:OnQuestLogUpdate(forceCheck)
    -- Throttle: only process once per QUEST_LOG_UPDATE_THROTTLE seconds
    local currentTime = GetTime()
    if not forceCheck and currentTime - lastQuestLogUpdate < QUEST_LOG_UPDATE_THROTTLE then
        return
    end
    lastQuestLogUpdate = currentTime

    if not GLV.CurrentDisplaySteps then
        return
    end

    local autoObjectiveTracking = GLV.Settings:GetOption({"QuestTracker", "AutoObjectiveTracking"}) or true
    if autoObjectiveTracking == false then
        return
    end

    local numEntries, numQuests = GetNumQuestLogEntries()
    
    for questIndex = 1, numEntries do
        local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(questIndex)

        if questLogTitleText and not isHeader then
            local questId = GLV:GetQuestIDByName(questLogTitleText)
            local numId = tonumber(questId)

            if numId then
                self:CheckQuestObjectives(questIndex, numId, questLogTitleText, isComplete)
            end
        end
    end

    -- Update ongoing objectives display in pinned section
    if GLV.UpdateOngoingObjectivesDisplay then
        GLV:UpdateOngoingObjectivesDisplay()
    end
end


--[[ OBJECTS FUNCTIONS ]]--

-- Get quest progress text for display (full objectives on separate lines)
function QuestTracker:GetQuestProgress(questId)
    if not questId then return nil end

    -- Get the quest name we're looking for from the database
    local expectedName = GLV:GetQuestNameByID(questId)

    local numEntries = GetNumQuestLogEntries()

    for questIndex = 1, numEntries do
        local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(questIndex)

        if questLogTitleText and not isHeader then
            local logQuestId = GLV:GetQuestIDByName(questLogTitleText)
            -- Match by exact ID or by name (for multi-part quests with same name but different IDs)
            if tonumber(logQuestId) == tonumber(questId) or (expectedName and questLogTitleText == expectedName) then
                SelectQuestLogEntry(questIndex)
                local numObjectives = GetNumQuestLeaderBoards()

                if numObjectives == 0 then
                    return nil, true, 0
                end

                local objectives = {}
                local allComplete = true

                for i = 1, numObjectives do
                    local description, objectiveType, isCompleted = GetQuestLogLeaderBoard(i)
                    if description then
                        table.insert(objectives, {
                            text = description,
                            completed = isCompleted
                        })
                        if not isCompleted then
                            allComplete = false
                        end
                    end
                end

                return objectives, allComplete, numObjectives
            end
        end
    end

    return nil, false, 0
end

-- Check objectives for a specific quest and handle completion
function QuestTracker:CheckQuestObjectives(questIndex, questId, questTitle, isComplete)
    SelectQuestLogEntry(questIndex)

    local questDescription, questObjectives = GetQuestLogQuestText()

    local currentObjectivesState = {}
    local numObjectives = GetNumQuestLeaderBoards()

    for i = 1, numObjectives do
        local description, objectiveType, isCompleted = GetQuestLogLeaderBoard(i)
        if description then
            currentObjectivesState[i] = {
                description = description,
                isCompleted = isCompleted
            }
        end
    end

    -- Get previous state for comparison
    local previousState = self.previousQuestStates[questId]

    -- Check for individual objective completion (for [QC questId,objectiveIndex] steps)
    for i = 1, numObjectives do
        local prevObj = previousState and previousState.objectivesState and previousState.objectivesState[i]
        local currObj = currentObjectivesState[i]

        if currObj and currObj.isCompleted then
            -- Objective is now complete - check if it just became complete
            local wasCompleted = prevObj and prevObj.isCompleted
            if not wasCompleted then
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QuestTracker]|r Objective " .. i .. " complete: " .. questTitle .. " (ID: " .. tostring(questId) .. ")")
                end
                self:HandleQuestAction(questId, questTitle, "COMPLETE", i)
            end
        end
    end

    -- isComplete can be 1, true, or any truthy value depending on WoW version
    if isComplete and (isComplete == 1 or isComplete == true) then
        local wasComplete = previousState and previousState.wasComplete
        if not wasComplete then
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QuestTracker]|r Quest complete detected: " .. questTitle .. " (ID: " .. tostring(questId) .. ")")
            end
            -- Fire for whole quest completion (no objectiveIndex)
            self:HandleQuestAction(questId, questTitle, "COMPLETE", nil)

            self.previousQuestStates[questId] = {
                wasComplete = true,
                lastObjectives = questObjectives,
                objectivesState = currentObjectivesState
            }
        end
    else
        self.previousQuestStates[questId] = {
            wasComplete = false,
            lastObjectives = questObjectives,
            objectivesState = currentObjectivesState
        }
    end
end


-- Track when a quest is accepted and handle related actions
function QuestTracker:TrackAccepted(id, title)
    if not id or type(id) ~= "number" then
        return
    end

    local store = self.store or GLV.Settings:GetOption({"QuestTracker"}) or {}
    if not store.Accepted then store.Accepted = {} end

    if id and not store.Accepted[id] then
        store.Accepted[id] = {
            title = title,
            timestamp = time()
        }
        GLV.Settings:SetOption(store, {"QuestTracker"})
        
        self:HandleQuestAction(id, title, "ACCEPT")
    end
end

-- Centralized function to handle quest actions (accept, complete, turnin)
-- objectiveIndex is optional: nil = whole quest, 1/2/3 = specific objective
function QuestTracker:HandleQuestAction(questId, title, actionType, objectiveIndex)
    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QuestTracker]|r HandleQuestAction: " .. tostring(actionType) .. " q" .. tostring(questId) .. " objIdx=" .. tostring(objectiveIndex))
    end

    local currentGuideId = GLV.Settings:GetOption({"Guide","CurrentGuide"}) or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide","Guides", currentGuideId, "StepState"}) or {}
    local stepQuestState = GLV.Settings:GetOption({"Guide","Guides", currentGuideId, "StepQuestState"}) or {}

    local stepMarked = false
    local multiActionStepFound = false

    if not GLV.CurrentDisplaySteps then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[QuestTracker]|r CurrentDisplaySteps is nil!")
        end
        return
    end

    local diCount = GLV.CurrentDisplayStepsCount or 0
    local diToOrig = GLV.CurrentDisplayToOriginal or {}

    for di = 1, diCount do
        local step = GLV.CurrentDisplaySteps[di]
        local origIdx = diToOrig[di]

        if step and origIdx and step.questTags and table.getn(step.questTags) > 0 then
            if not stepQuestState[origIdx] then
                stepQuestState[origIdx] = {}
            end

            local hasMatchingAction = false
            for _, questTag in ipairs(step.questTags) do
                if DoesQuestActionMatch(questTag, questId, title, actionType, objectiveIndex) then
                    local actionKey = GLV.BuildActionKey(questTag)
                    stepQuestState[origIdx][actionKey] = true
                    hasMatchingAction = true
                    multiActionStepFound = true
                    if GLV.Debug then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QuestTracker]|r MATCH: " .. actionKey .. " on step " .. tostring(di))
                    end
                end
            end

            if hasMatchingAction then
                GLV.Settings:SetOption(stepQuestState, {"Guide","Guides", currentGuideId, "StepQuestState"})
                local allDone = AreAllActionsDone(stepQuestState, origIdx, step.questTags)

                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[QuestTracker]|r allActionsDone=" .. tostring(allDone) .. " for step " .. tostring(di))
                end

                if allDone then
                    stepState[origIdx] = true
                    stepMarked = true

                    -- Deactivate ongoing step if it was active
                    if GLV.OngoingStepsManager and GLV.OngoingStepsManager:IsActive(di) then
                        GLV.OngoingStepsManager:Deactivate(di)
                    end
                end
                -- Don't break - continue to mark ALL steps with the same quest action
            end
        end
    end

    if stepMarked then
        GLV.Settings:SetOption(stepState, {"Guide","Guides", currentGuideId, "StepState"})
    end

    self:UpdateStepNavigation(stepMarked, multiActionStepFound, actionType)

    if GLV.CharacterTracker then
        GLV.CharacterTracker:CheckCurrentStepXPRequirements()
    end
end

-- Force navigation update based on current step (used after rapid quest actions)
function QuestTracker:ForceNavigationUpdate()
    if not GLV.GuideNavigation or not GLV.CurrentDisplaySteps then return end

    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0

    if currentStepIndex > 0 and currentStepIndex <= table.getn(GLV.CurrentDisplaySteps) then
        local stepData = GLV.CurrentDisplaySteps[currentStepIndex]
        if stepData then
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[QuestTracker]|r Forcing navigation update for step " .. currentStepIndex)
            end
            GLV.GuideNavigation:OnStepChanged(stepData)
        end
    end
end

-- Handle navigation between steps and update UI highlighting
function QuestTracker:UpdateStepNavigation(stepMarked, multiActionStepFound, actionType)
    local currentGuideId = GLV.Settings:GetOption({"Guide","CurrentGuide"}) or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide","Guides", currentGuideId, "StepState"}) or {}
    local stepQuestState = GLV.Settings:GetOption({"Guide","Guides", currentGuideId, "StepQuestState"}) or {}

    local diCount = GLV.CurrentDisplayStepsCount or 0
    local hasCb = GLV.CurrentDisplayHasCheckbox or {}
    local diToOrig = GLV.CurrentDisplayToOriginal or {}

    local firstUnchecked = 0

    for di = 1, diCount do
        if hasCb[di] then
            local origIdx = diToOrig[di]
            if origIdx then
                local stepCompleted = stepState[origIdx]

                if not stepCompleted then
                    local step = GLV.CurrentDisplaySteps[di]
                    if step and step.questTags and table.getn(step.questTags) > 1 then
                        if AreAllActionsDone(stepQuestState, origIdx, step.questTags) then
                            stepCompleted = true
                        end
                    end
                end

                if not stepCompleted then
                    firstUnchecked = di
                    break
                end
            end
        end
    end

    GLV.Settings:SetOption(firstUnchecked, {"Guide", "Guides", currentGuideId, "CurrentStep"})

    -- Use RefreshGuide to rebuild UI with correct checkbox states
    -- This is more reliable than trying to update checkboxes manually
    -- RefreshGuide has built-in debounce to prevent multiple rapid rebuilds
    if stepMarked and GLV.RefreshGuide then
        GLV:RefreshGuide()
        -- Force navigation update after RefreshGuide completes
        GLV.Ace:ScheduleEvent("GLV_PostRefreshNavUpdate", function()
            self:ForceNavigationUpdate()
        end, 0.2)
    else
        -- Just update highlighting if no step was marked
        local scrollChild = GLV_MainScrollFrameScrollChild
        if scrollChild and firstUnchecked > 0 then
            if GLV.CurrentDisplaySteps and GLV.updateStepColors then
                GLV.updateStepColors(scrollChild, currentGuideId, GLV.CurrentDisplaySteps, firstUnchecked)
            end

            -- Update navigation arrow
            -- For TURNIN actions, delay the update to allow quest log to be updated
            if GLV.GuideNavigation and GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[firstUnchecked] then
                local stepData = GLV.CurrentDisplaySteps[firstUnchecked]

                if actionType == "TURNIN" then
                    -- Delay navigation update for turnin to allow quest to be removed from log
                    GLV.Ace:ScheduleEvent("GLV_NavigationUpdate", function()
                        if GLV.GuideNavigation then
                            GLV.GuideNavigation:OnStepChanged(stepData)
                        end
                    end, 0.5)
                else
                    GLV.GuideNavigation:OnStepChanged(stepData)
                end
            end
        end
    end
end

-- Public function to refresh highlighting (can be called from GuideWriter)
function QuestTracker:RefreshHighlighting()
    
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if not scrollChild then
        return
    end
        
    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentGroup = GLV.Settings:GetOption({"Guide", "CurrentGroup"}) or "Unknown"
    local currentStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0    
    -- Force activeStep to be valid
    local activeStep = currentStep
    if not activeStep or activeStep == 0 then
        activeStep = 1
    end
        
    -- Count total steps
    local totalSteps = 0
    for i = 1, 200 do -- arbitrary limit
        local frameName = scrollChild:GetName().."Step"..currentGuideId.."_"..i
        local frame = getglobal(frameName)
        if frame then
            totalSteps = totalSteps + 1
        else
            break
        end
    end
    
    if totalSteps == 0 then
        return
    end
    
    if activeStep > totalSteps then
        activeStep = totalSteps
    end
    
    -- Use the unified highlighting system from GuideWriter
    if GLV.CurrentDisplaySteps and GLV.updateStepColors then
        GLV.updateStepColors(scrollChild, currentGuideId, GLV.CurrentDisplaySteps, activeStep)
    else
        -- Fallback: Use local highlighting if GuideWriter not loaded yet
        for di = 1, totalSteps do
            local frameName = scrollChild:GetName().."Step"..currentGuideId.."_"..di
            local frame = getglobal(frameName)
            
            if frame and frame.SetBackdropColor then
                local col = (di == activeStep) and {0.8,0.8,0.2,0.9} or (isEven(di) and {0.2,0.2,0.2,0.8} or {0.1,0.1,0.1,0.8})
                frame:SetBackdropColor(unpack(col))
            end
        end
    end
    
end

function QuestTracker:GetExpectedQuestIdFromCurrentStep(questTitle)
    if not GLV.CurrentDisplaySteps then
        return nil
    end
    
    local currentGuideId = GLV.Settings:GetOption({"Guide","CurrentGuide"}) or "Unknown"
    local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0

    -- Search in current step and a few steps ahead
    for offset = 0, 2 do
        local stepIndex = currentStepIndex + offset
        if stepIndex > 0 and stepIndex <= table.getn(GLV.CurrentDisplaySteps) then
            local step = GLV.CurrentDisplaySteps[stepIndex]
            
            if step and step.questTags and table.getn(step.questTags) > 0 then
                for _, questTag in ipairs(step.questTags) do
                    if questTag.tag == "ACCEPT" or questTag.tag == "TURNIN" then
                        -- Check if name matches (flexible comparison)
                        local questName = GLV:GetQuestNameByID(questTag.questId)
                        if questName and self:QuestNamesMatch(questTitle, questName) then
                            -- For same-name quest chains: skip IDs already accepted
                            if questTag.tag == "ACCEPT" and self.store and self.store.Accepted
                               and self.store.Accepted[tonumber(questTag.questId)] then
                                -- Quest already in log, likely a chain — check next match
                            else
                                return questTag.questId
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

function QuestTracker:QuestNamesMatch(title1, title2)
    if not title1 or not title2 then return false end

    -- Direct comparison
    if title1 == title2 then return true end

    -- Case-insensitive comparison
    if string.lower(title1) == string.lower(title2) then return true end

    -- Normalized comparison: trim trailing dots (WoW ellipsis) and whitespace
    -- This handles "Quest Name..." vs "Quest Name" without false positives
    -- from stripping all punctuation (which would match "A: Gold" with "A - Gold")
    local function normalize(s)
        s = string.lower(s)
        s = string.gsub(s, "%.+$", "")   -- Remove trailing dots (ellipsis)
        s = string.gsub(s, "%s+$", "")    -- Trim trailing whitespace
        s = string.gsub(s, "^%s+", "")    -- Trim leading whitespace
        return s
    end
    if normalize(title1) == normalize(title2) then return true end

    return false
end

function QuestTracker:VerifyQuestAfterAccept(expectedTitle, expectedId)
    -- Verify that the quest is in the journal with the correct ID
    GLV.Ace:ScheduleEvent("VerifyQuest", function()
        local numEntries, numQuests = GetNumQuestLogEntries()

        for i = 1, numEntries do
            local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i)

            if questLogTitleText and not isHeader and self:QuestNamesMatch(questLogTitleText, expectedTitle) then
                -- Quest is in the journal
                return true
            end
        end

        return false
    end, 0.5)
end


--[[ AUTO ACCEPT/TURNIN ]]--

-- Called when quest detail frame is shown (NPC offers a quest)
function QuestTracker:OnQuestDetail()
    local autoAccept = GLV.Settings:GetOption({"Automation", "AutoAcceptQuests"})
    if not autoAccept then return end

    local questTitle = GetTitleText()
    if not questTitle then return end

    -- Check if the current step has a [QA] tag for this quest
    local questId = self:GetQuestIdInCurrentStep(questTitle, "ACCEPT")
    if questId then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QuestTracker]|r Auto-accepting quest: " .. questTitle)
        end
        AcceptQuest()
        -- Track the quest acceptance to update guide step
        self:TrackAccepted(questId, questTitle)

        -- Force navigation update after a delay (handles rapid QT+QA sequences)
        GLV.Ace:ScheduleEvent("GLV_PostAcceptNavUpdate", function()
            self:ForceNavigationUpdate()
        end, 0.3)
    end
end

-- Called when quest complete frame is shown (NPC ready to turn in)
function QuestTracker:OnQuestComplete()
    local autoTurnin = GLV.Settings:GetOption({"Automation", "AutoTurninQuests"})
    if not autoTurnin then return end

    local questTitle = GetTitleText()
    if not questTitle then return end

    -- Don't auto-turnin if there are multiple reward choices
    local numChoices = GetNumQuestChoices()
    if numChoices and numChoices > 1 then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[QuestTracker]|r Skipping auto-turnin (reward choice required): " .. questTitle)
        end
        return
    end

    -- Check if the current step has a [QT] tag for this quest
    local questId = self:GetQuestIdInCurrentStep(questTitle, "TURNIN")
    if questId then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QuestTracker]|r Auto-turning in quest: " .. questTitle)
        end
        GetQuestReward()
        -- Track the quest turnin to update guide step
        self:HandleQuestAction(questId, questTitle, "TURNIN")

        -- Force navigation update after a delay (handles rapid QT+QA sequences)
        GLV.Ace:ScheduleEvent("GLV_PostTurninNavUpdate", function()
            self:ForceNavigationUpdate()
        end, 0.5)
    end
end

-- Get quest ID if quest is in the current step with a specific action tag
-- Returns questId if found, nil otherwise
-- Only checks the current active step (not future steps)
function QuestTracker:GetQuestIdInCurrentStep(questTitle, actionType)
    if not GLV.CurrentDisplaySteps then return nil end

    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local currentStepIndex = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0

    -- Only check the current step
    if currentStepIndex <= 0 or currentStepIndex > table.getn(GLV.CurrentDisplaySteps) then
        return nil
    end

    local step = GLV.CurrentDisplaySteps[currentStepIndex]
    if not step or not step.questTags or table.getn(step.questTags) == 0 then
        return nil
    end

    for _, questTag in ipairs(step.questTags) do
        if questTag.tag == actionType then
            -- Get quest name from database
            local questName = GLV:GetQuestNameByID(questTag.questId)
            if questName and self:QuestNamesMatch(questTitle, questName) then
                -- For same-name quest chains: skip IDs already accepted
                if actionType == "ACCEPT" and self.store and self.store.Accepted
                   and self.store.Accepted[tonumber(questTag.questId)] then
                    -- Quest already in log, likely a chain — check next match
                else
                    return questTag.questId
                end
            end
        end
    end

    return nil
end


--[[ HOOKS ]]--

-- Hook function for quest accept button
function HookQuestAccept()
    local title = GetTitleText()

    -- Find quest ID based on current guide step
    local correctQuestId = GLV.QuestTracker:GetExpectedQuestIdFromCurrentStep(title)

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QuestTracker]|r HookQuestAccept: '" .. tostring(title) .. "' correctId=" .. tostring(correctQuestId))
    end

    if correctQuestId then
        GLV.QuestTracker:TrackAccepted(correctQuestId, title)
    else
        -- Fallback to legacy method
        local id = GLV:GetQuestIDByName(title)
        local numId = tonumber(id)
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[QuestTracker]|r Fallback to GetQuestIDByName: " .. tostring(numId))
        end
        if numId then
            GLV.QuestTracker:TrackAccepted(numId, title)
        end
    end

    GLV.Ace.hooks["QuestDetailAcceptButton_OnClick"]()
end

-- Hook function for quest complete button
function HookQuestComplete()
    local title = GetTitleText()

    -- Find quest ID based on current guide step
    local id = GLV.QuestTracker:GetExpectedQuestIdFromCurrentStep(title)

    if not id then
        id = GLV:GetQuestIDByName(title)
    end

    local numId = tonumber(id)

    local store = GLV.QuestTracker and GLV.QuestTracker.store or GLV.Settings:GetOption({"QuestTracker"}) or GLV.Settings:GetDefaults().char.QuestTracker
    if store and numId then
        -- Add to Completed
        if store.Completed then
            store.Completed[numId] = { title = title, timestamp = time() }
        end
        -- Remove from Accepted (quest is no longer in log after turn-in)
        if store.Accepted and store.Accepted[numId] then
            store.Accepted[numId] = nil
        end
        GLV.Settings:SetOption(store, {"QuestTracker"})
    end

    if numId then
        GLV.QuestTracker:HandleQuestAction(numId, title, "TURNIN")
    end

    GLV.Ace.hooks["QuestRewardCompleteButton_OnClick"]()
end

-- Hook function for quest abandon
function HookQuestAbandon()
    local title = GetAbandonQuestName()
    if title then
        local id = GLV:GetQuestIDByName(title)
        local numId = tonumber(id)
        if numId and GLV.QuestTracker then
            local store = GLV.QuestTracker.store or GLV.Settings:GetOption({"QuestTracker"}) or {}
            if store.Accepted and store.Accepted[numId] then
                store.Accepted[numId] = nil
                GLV.Settings:SetOption(store, {"QuestTracker"})
            end
        end
    end
    GLV.Ace.hooks["AbandonQuest"]()
end
