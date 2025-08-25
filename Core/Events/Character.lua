--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
Character events tracker (XP, Level, etc.)
]]--

local GLV = LibStub('AceAddon-3.0'):GetAddon('GuidelimeVanilla')
local CharacterTracker = GLV:NewModule("CharacterTracker", "AceEvent-3.0")


--[[ INITIALIZATION FUNCTIONS ]]--

-- Initialize character tracking and register event handlers
function CharacterTracker:OnEnable()
    self.settings = GLV.db.char or {}
    
    self:RegisterEvent("PLAYER_XP_UPDATE", "OnPlayerXPUpdate")
    self:RegisterEvent("PLAYER_LEVEL_UP", "OnPlayerXPUpdate")
    self:RegisterEvent("LEARNED_SPELL_IN_TAB", "OnSpellLearned")

    self.previousPlayerLevel = UnitLevel("player")
    self.previousPlayerXP = UnitXP("player")
end


--[[ EVENTS ]]--

-- Handle player XP and level updates, check XP requirements
function CharacterTracker:OnPlayerXPUpdate()
    local currentLevel = UnitLevel("player")
    local currentXP = UnitXP("player")
      
    if currentLevel > self.previousPlayerLevel or (currentLevel == self.previousPlayerLevel and currentXP > self.previousPlayerXP) then
        
        local hasXPReqs, stepCompleted = self:CheckExperienceRequirements()
        
        self.previousPlayerLevel = currentLevel
        self.previousPlayerXP = currentXP
        
        self:ManageXPTimer(hasXPReqs)

    end
end

-- Handle spell learning events (debug only)
function CharacterTracker:OnSpellLearned()
    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime XP]|r Spell learned")
    end
end


--[[ OBJECTS FUNCTIONS ]]--

-- Check for XP changes and update step completion status
function CharacterTracker:CheckForXPChanges()
    local currentLevel = UnitLevel("player")
    local currentXP = UnitXP("player")
    
    if currentLevel ~= self.previousPlayerLevel or currentXP ~= self.previousPlayerXP then
        
        local hasXPReqs, stepCompleted = self:CheckExperienceRequirements()
        
        self.previousPlayerLevel = currentLevel
        self.previousPlayerXP = currentXP
        
        self:ManageXPTimer(hasXPReqs)
    end
end

-- Check if player meets XP requirements for current guide steps
function CharacterTracker:CheckExperienceRequirements()
    if not GLV.CurrentDisplaySteps then
        return false
    end

    local questTracker = GLV:GetModule("QuestTracker")
    
    local currentGuideId = self.settings.Guide.CurrentGuide or "Unknown"
    local stepState = self.settings.Guide.Guides[currentGuideId].StepState or {}
    local diCount = GLV.CurrentDisplayStepsCount or 0
    local diToOrig = GLV.CurrentDisplayToOriginal or {}
    
    local playerLevel = UnitLevel("player")
    local playerXP = UnitXP("player")
    local playerMaxXP = UnitXPMax("player")
    
    local hasAnyXPRequirements = false
    local stepCompleted = false
    
    for di = 1, diCount do
        local step = GLV.CurrentDisplaySteps[di]
        local origIdx = diToOrig[di]
        
        if step and origIdx and not stepState[origIdx] then
            local hasXPReq = false
            for _, line in ipairs(step.lines or {}) do
                if line.experienceRequirement then
                    hasXPReq = true
                    hasAnyXPRequirements = true
                    local req = line.experienceRequirement
                    local requirementMet = false
                    
                    if req.type == "level" then
                        requirementMet = (playerLevel >= req.targetLevel)

                    elseif req.type == "level_minus" then
                        if playerLevel >= req.targetLevel then
                            requirementMet = true

                        elseif playerLevel == (req.targetLevel - 1) then
                            local xpNeeded = playerMaxXP - playerXP
                            requirementMet = (xpNeeded <= req.xpMinus)

                        end
                        
                    elseif req.type == "level_percent" then
                        if playerLevel > req.targetLevel then
                            requirementMet = true

                        elseif playerLevel == req.targetLevel then
                            local currentPercent = (playerXP / playerMaxXP) * 100
                            requirementMet = (currentPercent >= req.targetPercent)
                        end
                    end
                    
                    if requirementMet then
                        stepState[origIdx] = true
                        self.settings.Guide.Guides[currentGuideId].StepState = stepState
                        
                        questTracker:UpdateStepNavigation(true, false)
                        stepCompleted = true
                        break
                    end
                end
            end
            
        end
    end
    
    return hasAnyXPRequirements, stepCompleted
end

-- Check and update XP timer based on current requirements
function CharacterTracker:CheckAndUpdateXPTimer()
    local hasXPReqs = self:CheckExperienceRequirements()
    self:ManageXPTimer(hasXPReqs)
end

-- Manage XP timer based on whether there are requirements to monitor
function CharacterTracker:ManageXPTimer(hasXPRequirements)
    if hasXPRequirements then
        if self.xpCheckTimer then
            if not self.xpCheckTimer then
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime XP]|r Starting XP check timer")
                end
                self.xpCheckTimer = GLV:ScheduleRepeatingEvent("XPCheckUpdate", function() self:CheckForXPChanges() end, 2)
            end
        end
    else
        if self.xpCheckTimer then
            if not self.xpCheckTimer then
                if GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[GuideLime XP]|r Stopping XP check timer")
                end
                self.xpCheckTimer = GLV:CancelScheduledEvent("XPCheckUpdate")
            end
        end
    end
end

-- Check XP requirements immediately when loading guide or changing steps
function CharacterTracker:CheckCurrentStepXPRequirements()
    local hasXPReqs, stepCompleted = self:CheckExperienceRequirements()
    
    self:ManageXPTimer(hasXPReqs)
    
    return hasXPReqs, stepCompleted
end
