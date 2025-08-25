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
local _G = _G or getfenv()
local GLV = LibStub('AceAddon-3.0'):GetAddon('GuidelimeVanilla')

local prototype = {
    OnEnable = function(self)
        self.settings = GLV.db.char or {}
    end
}
local Library = GLV:NewModule("Library", prototype)

Library.loadedGuides = Library.loadedGuides or {}


--[[ GUIDE REGISTRATION FUNCTIONS ]]--

-- Activate all registered guides (parse and process them)
function Library:ActivateGuides()
    DEFAULT_CHAT_FRAME:AddMessage("ActivateGuides")
    local parser = GLV:GetModule("Parser")
    
    -- Clear existing loaded guides
    self.loadedGuides = {}
    
    -- Process each raw guide
    for group, guides in pairs(GLV.rawGuides) do
        if not self.loadedGuides[group] then
            self.loadedGuides[group] = {}
        end
        
        for guideId, rawGuide in pairs(guides) do
            -- Parse the guide
            local guide = parser:parseGuide(rawGuide.text, group)
            if guide and guide.name and guide.id then
                -- Store the processed guide
                self.loadedGuides[group][guide.id] = {
                    text = rawGuide.text,
                    name = guide.name,
                    minLevel = guide.minLevel,
                    maxLevel = guide.maxLevel,
                    description = guide.description
                }
            end
        end
    end
    
    -- Update global reference for compatibility
    GLV.loadedGuides = self.loadedGuides
    
    -- Populate dropdown for the current group
    local currentGroup = GLV.db.char.Guide.CurrentGroup
    if currentGroup and self.loadedGuides[currentGroup] then
        self:PopulateDropdown(currentGroup)
    end
end


--[[ DROPDOWN MANAGEMENT FUNCTIONS ]]--

-- Function factory to create the dropdown callback function
local function createDropdownCallback(group, guideId, guideData, displayName, dropdown)
    return function()
        Library:LoadGuide(group, guideId)
        UIDropDownMenu_SetSelectedValue(dropdown, guideId)
        UIDropDownMenu_SetText(displayName, dropdown)
    end
end

-- Populate the guide selection dropdown with all available guides
function Library:PopulateDropdown(group)
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
function Library:LoadGuide(group, guideId)
    local parser = GLV:GetModule("Parser")
    local writer = GLV:GetModule("Writer")
    local navigation = GLV:GetModule("Navigation")
    local characterTracker = GLV:GetModule("CharacterTracker")
    local questTracker = GLV:GetModule("QuestTracker")

    navigation:ClearAllWaypoints()
    
    local guideData = GLV.loadedGuides[group] and GLV.loadedGuides[group][guideId]
    if not guideData then
        return
    end
    
    local guide = parser:parseGuide(guideData.text, group)
    if not guide then
        return
    end
    
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if not scrollChild then
        return
    end
    
    self.settings.Guide.CurrentGuide = guideId
    
    GLV.CurrentGuide = guide
    
    DEFAULT_CHAT_FRAME:AddMessage("CreateGuideSteps: " .. guideId)
    writer:CreateGuideSteps(scrollChild, guide, guideId)
    
    local scrollFrame = _G["GLV_MainScrollFrame"]
    if scrollFrame then
        scrollFrame:UpdateScrollChildRect()
        scrollFrame:SetVerticalScroll(0)
    end
    
    local savedStepState = self.settings.Guide.Guides[guideId].StepState or {} 
    local savedCurrentStep = self.settings.Guide.Guides[guideId].CurrentStep or 0
    
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
        self.settings.Guide.Guides[guideId].CurrentStep = savedCurrentStep
        questTracker:RefreshHighlighting()
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
        self.settings.Guide.Guides[guideId].CurrentStep = firstUnchecked
        questTracker:RefreshHighlighting()
    end
    
    local currentStep = self.settings.Guide.Guides[guideId].CurrentStep or 0
    
    if currentStep > 0 then
        local stepData = nil
        
        if GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[currentStep] then
            stepData = GLV.CurrentDisplaySteps[currentStep]
        elseif guide and guide.steps and guide.steps[currentStep] then
            stepData = guide.steps[currentStep]
        end
        
        if stepData and TomTom and TomTom.AddMFWaypoint then
            local success, err = pcall(function()
                navigation:OnStepChanged(stepData)
            end)
            if not success then
            end
        end
    end
    
    questTracker:RefreshHighlighting()
    
    characterTracker:CheckCurrentStepXPRequirements()
    
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
function Library:DebugGuides()
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