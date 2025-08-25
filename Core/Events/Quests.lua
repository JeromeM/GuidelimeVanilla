--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Quest Tracker. Track when quests are accepted / completed
]]--
local _G = _G or getfenv()
local GLV = LibStub('AceAddon-3.0'):GetAddon('GuidelimeVanilla')
local QuestTracker = GLV:NewModule("QuestTracker", "AceHook-3.0", "AceEvent-3.0")


--[[ INITIALIZATION FUNCTIONS ]]--

-- Initialize quest tracking, hook original functions and register event handlers
function QuestTracker:OnEnable()
    DEFAULT_CHAT_FRAME:AddMessage("QuestTracker enabled")
    self.settings = GLV.db.char or {}

    self:Hook("QuestDetailAcceptButton_OnClick", function() HookQuestAccept() end)
    self:Hook("QuestRewardCompleteButton_OnClick", function() HookQuestComplete() end)
    self:Hook("AbandonQuest", function() HookQuestAbandon() end)

    self:RegisterEvent("QUEST_LOG_UPDATE", "OnQuestLogUpdate")
    
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
    local dbTools = GLV:GetModule("DBTools")

    if not GLV.CurrentDisplaySteps then
        return
    end
    
    local autoObjectiveTracking = GLV.db.char.QuestTracker.AutoObjectiveTracking or true
    if autoObjectiveTracking == false then
        return
    end
    
    local numEntries, numQuests = GetNumQuestLogEntries()
    
    for questIndex = 1, numEntries do
        local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(questIndex)
        
        if questLogTitleText and not isHeader then
            local questId = dbTools:GetQuestIDByName(questLogTitleText)
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

    if not self.settings.QuestTracker.Accepted then self.settings.QuestTracker.Accepted = {} end

    if id and not self.settings.QuestTracker.Accepted[id] then
        self.settings.QuestTracker.Accepted[id] = {
            title = title,
            timestamp = time()
        }
        
        self:HandleQuestAction(id, title, "ACCEPT")
    end
end

-- Centralized function to handle quest actions (accept, complete, turnin)
function QuestTracker:HandleQuestAction(questId, title, actionType)
    local characterTracker = GLV:GetModule("CharacterTracker")
    
    local currentGuideId = self.settings.Guide.CurrentGuide or "Unknown"
    local stepState = self.settings.Guide.Guides[currentGuideId].StepState or {}
    local stepQuestState = self.settings.Guide.Guides[currentGuideId].StepQuestState or {}
    
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
                    self.settings.Guide.Guides[currentGuideId].StepQuestState = stepQuestState
                    
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
        self.settings.Guide.Guides[currentGuideId].StepState = stepState
    end
    
    self:UpdateStepNavigation(stepMarked, multiActionStepFound)
    
    characterTracker:CheckCurrentStepXPRequirements()
end

-- Handle navigation between steps and update UI highlighting
function QuestTracker:UpdateStepNavigation(stepMarked, multiActionStepFound)
    local navigation = GLV:GetModule("Navigation")

    local currentGuideId = self.settings.Guide.CurrentGuide or "Unknown"
    local stepState = self.settings.Guide.Guides[currentGuideId].StepState or {}
    local stepQuestState = self.settings.Guide.Guides[currentGuideId].StepQuestState or {}
    
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
    
    self.settings.Guide.Guides[currentGuideId].CurrentStep = firstUnchecked
    
    if firstUnchecked > 0 then
        local mainScrollFrame = _G["GLV_MainScrollFrame"]
        local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
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
            
            if firstUnchecked > 0 and mainScrollFrame then
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
                local maxScroll = mainScrollFrame:GetVerticalScrollRange()
                if maxScroll and maxScroll > 0 then
                    targetScroll = math.min(targetScroll, maxScroll)
                end
                mainScrollFrame:SetVerticalScroll(targetScroll)

            end
            
            if GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[firstUnchecked] then
                local stepData = GLV.CurrentDisplaySteps[firstUnchecked]
                navigation:OnStepChanged(stepData)
            end
        end
    end
end

-- Public function to refresh highlighting (can be called from GuideWriter)
function QuestTracker:RefreshHighlighting()
    local scrollChild = _G("GLV_MainScrollFrameScrollChild")
    if scrollChild then
        local currentGuideId = self.settings.Guide.CurrentGuide or "Unknown"
        local activeStep = self.settings.Guide.Guides[currentGuideId].CurrentStep or 0
        if activeStep > 0 then
            applyHighlighting(scrollChild, activeStep)
        end
    end
end


--[[ HOOKS ]]--

-- Hook function for quest accept button
function HookQuestAccept()
    local dbTools = GLV:GetModule("DBTools")
    
    local title = GetTitleText()
    local id = dbTools:GetQuestIDByName(title)
    local numId = tonumber(id)
    if numId then
        self:TrackAccepted(numId, title)
    end
end

-- Hook function for quest complete button
function HookQuestComplete()
    local dbTools = GLV:GetModule("DBTools")

    local title = GetTitleText()
    local id = dbTools:GetQuestIDByName(title)
    local numId = tonumber(id)
    
    if self.settings.QuestTracker.Completed and numId then
        self.settings.QuestTracker.Completed[numId] = { title = title, timestamp = time() }
    end
    
    if numId then
        self:HandleQuestAction(numId, title, "TURNIN")
    end
end

-- Hook function for quest abandon
function HookQuestAbandon()
    local dbTools = GLV:GetModule("DBTools")

    local title = GetAbandonQuestName()
    if title then
        local id = dbTools:GetQuestIDByName(title)
        local numId = tonumber(id)
        if numId then
            if self.settings.QuestTracker.Accepted and self.settings.QuestTracker.Accepted[numId] then
                self.settings.QuestTracker.Accepted[numId] = nil
            end
        end
    end
end

