--[[
Guidelime Vanilla

Author: Grommey
Version: 0.1

Description:
This is where Guides are registered.
A Guide is another Addon, and every lua (guides) file must begins with :
local GLV = LibStub("GuidelimeVanilla")
GLV:RegisterGuide(TEXT GUIDE, "Group Name")
]]--
local GLV = LibStub("GuidelimeVanilla")

GLV.loadedGuides = GLV.loadedGuides or {}


--[[ GUIDE REGISTRATION FUNCTIONS ]]--

-- Register a new guide with the system
function GLV:RegisterGuide(guideText, group)
    local guide = self.Parser:parseGuide(guideText, group)
    if not guide then
        return
    end
    
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if not scrollChild then
    end

    if not self.loadedGuides[group] then
        self.loadedGuides[group] = {}
    end

    if guide.name ~= nil and guide.id ~= nil then
        if not self.loadedGuides[group][guide.id] then
            self.loadedGuides[group][guide.id] = {
                text = guideText,
                name = guide.name,
                minLevel = guide.minLevel,
                maxLevel = guide.maxLevel,
                description = guide.description
            }
            
            GLV.Ace.db.char.Guide.CurrentGroup = group
            
            if scrollChild then
                self:PopulateDropdown(group)
            end
        end
    end
end


--[[ DROPDOWN MANAGEMENT FUNCTIONS ]]--

-- Function factory to create the dropdown callback function
local function createDropdownCallback(group, guideId, guideData, displayName, dropdown)
    return function()
        GLV:LoadGuide(group, guideId)
        UIDropDownMenu_SetSelectedValue(dropdown, guideId)
        UIDropDownMenu_SetText(displayName, dropdown)
    end
end

-- Populate the guide selection dropdown with all available guides
function GLV:PopulateDropdown(group)
    local dropdown = _G["GLV_MainDropdown"]
    if not dropdown then
        return
    end

    UIDropDownMenu_Initialize(dropdown, function()
        local totalGuides = 0
        for g, guides in pairs(self.loadedGuides) do
            if guides then
                for _ in pairs(guides) do totalGuides = totalGuides + 1 end
            end
        end
        
        if totalGuides == 0 then
            local info = {}
            info.text = "Aucun guide disponible"
            info.disabled = 1
            UIDropDownMenu_AddButton(info)
            return
        end
        
        for g, guides in pairs(self.loadedGuides) do
            if guides and next(guides) then
                local groupInfo = {}
                groupInfo.text = "--- " .. g .. " ---"
                groupInfo.disabled = 1
                UIDropDownMenu_AddButton(groupInfo)
                
                for guideId, guideData in pairs(guides) do
                    local info = {}
                    local displayName = guideData.name
                    if guideData.minLevel and guideData.maxLevel then
                        displayName = guideData.name .. " (" .. guideData.minLevel .. "-" .. guideData.maxLevel .. ")"
                    end
                    info.text = displayName
                    info.value = guideId
                    info.func = createDropdownCallback(g, guideId, guideData, displayName, dropdown)
                    UIDropDownMenu_AddButton(info)
                end
            end
        end
    end)
    
    local selected = false
    for g, guides in pairs(self.loadedGuides) do
        if guides and next(guides) then
            for guideId, guideData in pairs(guides) do
                local displayName = guideData.name
                if guideData.minLevel and guideData.maxLevel then
                    displayName = guideData.name .. " (" .. guideData.minLevel .. "-" .. guideData.maxLevel .. ")"
                end
                
                UIDropDownMenu_SetSelectedValue(dropdown, guideId)
                UIDropDownMenu_SetText(displayName, dropdown)
                selected = true
                break
            end
            if selected then break end
        end
    end
    
    if not selected then
        UIDropDownMenu_SetText("Choisir un guide", dropdown)
    end
end


--[[ GUIDE LOADING FUNCTIONS ]]--

-- Load and display a specific guide
function GLV:LoadGuide(group, guideId)
    if GLV.TomTomIntegration then
        GLV.TomTomIntegration:ClearAllWaypoints()
    end
    
    local guideData = GLV.loadedGuides[group] and GLV.loadedGuides[group][guideId]
    if not guideData then
        return
    end
    
    local guide = GLV.Parser:parseGuide(guideData.text, group)
    if not guide then
        return
    end
    
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if not scrollChild then
        return
    end
    
    GLV.Ace.db.char.Guide.CurrentGuide = guideId
    
    GLV.CurrentGuide = guide
    
    GLV:CreateGuideSteps(scrollChild, guide, guideId)
    
    local scrollFrame = _G["GLV_MainScrollFrame"]
    if scrollFrame then
        scrollFrame:UpdateScrollChildRect()
        scrollFrame:SetVerticalScroll(0)
    end
    
    local savedStepState = GLV.Ace.db.char.Guide.Guides[guideId].StepState or {}
    local savedCurrentStep = GLV.Ace.db.char.Guide.Guides[guideId].CurrentStep or 0
    
    if savedStepState and next(savedStepState) then
        for stepIndex, isCompleted in pairs(savedStepState) do
            if isCompleted then
                local foundStep = false
                for displayIndex, originalIndex in pairs(GLV.CurrentDisplayToOriginal) do
                    if originalIndex == stepIndex then
                        local stepFrame = _G[scrollChild:GetName() .. "Step" .. displayIndex]
                        if stepFrame then
                            local checkbox = _G[stepFrame:GetName() .. "Check"]
                            if checkbox then
                                checkbox:SetChecked(true)
                                foundStep = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    
    if savedCurrentStep > 0 then
        GLV.Ace.db.char.Guide.Guides[guideId].CurrentStep = savedCurrentStep
        if GLV.QuestTracker then
            GLV.QuestTracker:RefreshHighlighting()
        end
    else
        local firstUnchecked = 1
        for i = 1, table.getn(guide.steps) do
            local stepFrame = _G[scrollChild:GetName() .. "Step" .. i]
            if stepFrame then
                local checkbox = _G[stepFrame:GetName() .. "Check"]
                if checkbox and not checkbox:GetChecked() then
                    firstUnchecked = i
                    break
                end
            end
        end
        GLV.Ace.db.char.Guide.Guides[guideId].CurrentStep = firstUnchecked
        if GLV.QuestTracker then
            GLV.QuestTracker:RefreshHighlighting()
        end
    end
    
    if GLV.TomTomIntegration then
        local currentStep = GLV.Ace.db.char.Guide.Guides[guideId].CurrentStep or 0
        
        if currentStep > 0 then
            local stepData = nil
            
            if GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[currentStep] then
                stepData = GLV.CurrentDisplaySteps[currentStep]
            elseif guide and guide.steps and guide.steps[currentStep] then
                stepData = guide.steps[currentStep]
            end
            
            if stepData and TomTom and TomTom.AddMFWaypoint then
                local success, err = pcall(function()
                    GLV.TomTomIntegration:OnStepChanged(stepData)
                end)
                if not success then
                end
            end
        end
    end
    
    if GLV.QuestTracker then
        GLV.QuestTracker:RefreshHighlighting()
    end
    
    if GLV.CharacterTracker then
        GLV.CharacterTracker:CheckCurrentStepXPRequirements()
    end
    
    local dropdown = _G["GLV_MainDropdown"]
    if dropdown then
        local guideData = GLV.loadedGuides[group] and GLV.loadedGuides[group][guideId]
        if guideData then
            local displayName = guideData.name
            if guideData.minLevel and guideData.maxLevel then
                displayName = guideData.name .. " (" .. guideData.minLevel .. "-" .. guideData.maxLevel .. ")"
            end
            UIDropDownMenu_SetSelectedValue(dropdown, guideId)
            UIDropDownMenu_SetText(displayName, dropdown)
        end
    end
end


--[[ DEBUG FUNCTIONS ]]--

-- Debug command to display loaded guides information
function GLV:DebugGuides()
    if not self.loadedGuides then
        return
    end
    
    local totalGroups = 0
    local totalGuides = 0
    
    for group, guides in pairs(self.loadedGuides) do
        totalGroups = totalGroups + 1
        
        if guides then
            local groupGuideCount = 0
            for guideId, guideData in pairs(guides) do
                groupGuideCount = groupGuideCount + 1
                totalGuides = totalGuides + 1
            end
        end
    end
end