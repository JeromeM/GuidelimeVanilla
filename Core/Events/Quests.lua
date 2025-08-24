--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Quest Tracker. Track when quests are accepted / completed
]]--
local GLV = LibStub("GuidelimeVanilla")

local QuestTracker = {}
GLV.QuestTracker = QuestTracker

-- Initialize quest tracking, hook original functions and register event handlers
function QuestTracker:Init()
    local store = GLV.Ace.db.char.QuestTracker or {}
    self.store = store

    if GLV.Ace then
        GLV.Ace:Hook("QuestDetailAcceptButton_OnClick", HookQuestAccept)
        GLV.Ace:Hook("QuestRewardCompleteButton_OnClick", HookQuestComplete)
        GLV.Ace:Hook("AbandonQuest", HookQuestAbandon)

        GLV.Ace:RegisterEvent("QUEST_LOG_UPDATE", function() self:OnQuestLogUpdate() end)
    end
    
    self.previousQuestStates = {}
end


--[[ LOCAL FUNCTIONS ]]--

-- Utility function to apply highlighting to all frames
local function applyHighlighting(scrollChild, activeStepIndex)
    if not scrollChild then return end
    
    local totalSteps = GLV.CurrentDisplayStepsCount or 0
    if totalSteps == 0 then
        local stepIndex = 1
        while getglobal(scrollChild:GetName().."Step"..stepIndex) do
            totalSteps = stepIndex
            stepIndex = stepIndex + 1
        end
    end
    
    for di = 1, totalSteps do
        local frameName = scrollChild:GetName().."Step"..di
        local frame = getglobal(frameName)
        if frame and frame.SetBackdropColor then
            local color = (di == activeStepIndex) and {0.8,0.8,0.2,0.9} or (isEven(di) and {0.2,0.2,0.2,0.8} or {0.1,0.1,0.1,0.8})
            frame:SetBackdropColor(unpack(color))
        end
    end
end


--[[ EVENTS ]]--

-- Handle quest log updates and check for completed objectives
function QuestTracker:OnQuestLogUpdate()
    if not GLV.CurrentDisplaySteps then
        return
    end
    
    local autoObjectiveTracking = GLV.Ace.db.char.QuestTracker.AutoObjectiveTracking or true
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
end


--[[ OBJECTS FUNCTIONS ]]--

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
    
    if isComplete and isComplete == 1 then
        local currentState = self.previousQuestStates[questId]
        if not currentState or not currentState.wasComplete then
            
            self:HandleQuestAction(questId, questTitle, "COMPLETE")
            
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

    local store = self.store or GLV.Ace.db.char.QuestTracker or {}
    if not store.Accepted then store.Accepted = {} end

    if id and not store.Accepted[id] then
        store.Accepted[id] = {
            title = title,
            timestamp = time()
        }
        GLV.Ace.db.char.QuestTracker = store
        
        self:HandleQuestAction(id, title, "ACCEPT")
    end
end

-- Centralized function to handle quest actions (accept, complete, turnin)
function QuestTracker:HandleQuestAction(questId, title, actionType)
    
    local currentGuideId = GLV.Ace.db.char.Guide.CurrentGuide or "Unknown"
    local stepState = GLV.Ace.db.char.Guide.Guides[currentGuideId].StepState or {}
    local stepQuestState = GLV.Ace.db.char.Guide.Guides[currentGuideId].StepQuestState or {}
    
    local stepMarked = false
    local multiActionStepFound = false
    
    if not GLV.CurrentDisplaySteps then
        return
    end
    
    local diCount = GLV.CurrentDisplayStepsCount or 0
    local diToOrig = GLV.CurrentDisplayToOriginal or {}
    
    for di = 1, diCount do
        local step = GLV.CurrentDisplaySteps[di]
        local origIdx = diToOrig[di]
        
        if step and origIdx then
            
            if step.questTags and table.getn(step.questTags) > 0 then
                if not stepQuestState[origIdx] then
                    stepQuestState[origIdx] = {}
                end
                
                local hasMatchingAction = false
                local allActionsDone = true
                
                for _, questTag in ipairs(step.questTags) do
                    local actionKey = questTag.questId .. "_" .. questTag.tag
                    
                    if questTag.tag == actionType and questTag.questId == questId then
                        stepQuestState[origIdx][actionKey] = true
                        hasMatchingAction = true
                        multiActionStepFound = true
                    end
                    
                    if not stepQuestState[origIdx][actionKey] then
                        allActionsDone = false
                    end
                end
                
                if hasMatchingAction then
                    GLV.Ace.db.char.Guide.Guides[currentGuideId].StepQuestState = stepQuestState
                    
                    if allActionsDone then
                        stepState[origIdx] = true
                        stepMarked = true
                    end
                    
                    break
                end
            end
        end
    end
    
    if stepMarked then
        GLV.Ace.db.char.Guide.Guides[currentGuideId].StepState = stepState
    end
    
    self:UpdateStepNavigation(stepMarked, multiActionStepFound)
    
    if GLV.CharacterTracker then
        GLV.CharacterTracker:CheckCurrentStepXPRequirements()
    end
end

-- Handle navigation between steps and update UI highlighting
function QuestTracker:UpdateStepNavigation(stepMarked, multiActionStepFound)
    local currentGuideId = GLV.Ace.db.char.Guide.CurrentGuide or "Unknown"
    local stepState = GLV.Ace.db.char.Guide.Guides[currentGuideId].StepState or {}
    local stepQuestState = GLV.Ace.db.char.Guide.Guides[currentGuideId].StepQuestState or {}
    
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
                    if step and step.questTags and table.getn(step.questTags) > 1 and stepQuestState[origIdx] then
                        local allDone = true
                        for _, questTag in ipairs(step.questTags) do
                            local actionKey = questTag.questId .. "_" .. questTag.tag
                            if not stepQuestState[origIdx][actionKey] then
                                allDone = false
                                break
                            end
                        end
                        if allDone then
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
    
    GLV.Ace.db.char.Guide.Guides[currentGuideId].CurrentStep = firstUnchecked
    
    if firstUnchecked > 0 then
        local scrollChild = GLV_MainScrollFrameScrollChild
        if scrollChild then
            for di = 1, diCount do
                if hasCb[di] then
                    local origIdx = diToOrig[di]
                    if origIdx and stepState[origIdx] then
                        local frameName = scrollChild:GetName().."Step"..di
                        local check = getglobal(frameName.."Check")
                        if check and check.SetChecked then
                            check:SetChecked(true)
                        end
                    end
                end
            end
            
            applyHighlighting(scrollChild, firstUnchecked)
            
            if firstUnchecked > 0 and GLV_MainScrollFrame then
                local targetScroll = 0
                for i = 1, firstUnchecked - 1 do
                    local stepFrameName = scrollChild:GetName().."Step"..i
                    local stepFrame = getglobal(stepFrameName)
                    if stepFrame and stepFrame.GetHeight then
                        targetScroll = targetScroll + stepFrame:GetHeight()
                    end
                end
                if firstUnchecked > 1 then
                    local spacing = -4
                    targetScroll = targetScroll + (math.abs(spacing) * (firstUnchecked - 1))
                end
                targetScroll = math.max(0, targetScroll)
                local maxScroll = GLV_MainScrollFrame:GetVerticalScrollRange()
                if maxScroll and maxScroll > 0 then
                    targetScroll = math.min(targetScroll, maxScroll)
                end
                GLV_MainScrollFrame:SetVerticalScroll(targetScroll)

            end
            
            if GLV.TomTomIntegration and GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[firstUnchecked] then
                local stepData = GLV.CurrentDisplaySteps[firstUnchecked]
                GLV.TomTomIntegration:OnStepChanged(stepData)
            end
        end
    end
end

-- Public function to refresh highlighting (can be called from GuideWriter)
function QuestTracker:RefreshHighlighting()
    local scrollChild = getglobal("GLV_MainScrollFrameScrollChild")
    if scrollChild then
        local currentGuideId = GLV.Ace.db.char.Guide.CurrentGuide or "Unknown"
        local activeStep = GLV.Ace.db.char.Guide.Guides[currentGuideId].CurrentStep or 0
        if activeStep > 0 then
            applyHighlighting(scrollChild, activeStep)
        end
    end
end


--[[ HOOKS ]]--

-- Hook function for quest accept button
function HookQuestAccept()
    local title = GetTitleText()
    local id = GLV:GetQuestIDByName(title)
    local numId = tonumber(id)
    if numId then
        GLV.QuestTracker:TrackAccepted(numId, title)
    end
    GLV.Ace.hooks["QuestDetailAcceptButton_OnClick"]()
end

-- Hook function for quest complete button
function HookQuestComplete()
    local title = GetTitleText()
    local id = GLV:GetQuestIDByName(title)
    local numId = tonumber(id)
    
    local store = GLV.QuestTracker and GLV.QuestTracker.store or GLV.Ace.db.char.QuestTracker or GLV.Ace.db.char.QuestTracker
    if store and store.Completed and numId then
        store.Completed[numId] = { title = title, timestamp = time() }
        GLV.Ace.db.char.QuestTracker = store
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
            local store = GLV.QuestTracker.store or GLV.Ace.db.char.QuestTracker or {}
            if store.Accepted and store.Accepted[numId] then
                store.Accepted[numId] = nil
                GLV.Ace.db.char.QuestTracker = store
            end
        end
    end
    GLV.Ace.hooks["AbandonQuest"]()
end

