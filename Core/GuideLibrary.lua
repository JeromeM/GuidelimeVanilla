--[[
Guidelime Vanilla

Author: Grommey

Description:
This is where Guides are registered.
A Guide is another Addon, and every lua (guides) file must begins with :
local GLV = LibStub("GuidelimeVanilla")
GLV:RegisterGuide(TEXT GUIDE, "Group Name")
]]--
local _G = _G or getfenv(0)
local GLV = LibStub("GuidelimeVanilla")

GLV.loadedGuides = GLV.loadedGuides or {}


--[[ GUIDE PACK MANAGEMENT FUNCTIONS ]]--

-- Get list of available guide packs (groups with at least one guide)
function GLV:GetAvailableGuidePacks()
    local packs = {}
    for group, guides in pairs(self.loadedGuides) do
        if guides and next(guides) then
            table.insert(packs, group)
        end
    end
    table.sort(packs)
    return packs
end

-- Get the currently active guide pack (only if explicitly set by user)
function GLV:GetActiveGuidePack()
    local activePack = self.Settings:GetOption({"Guide", "ActivePack"})

    -- Verify the pack still exists
    if activePack and self.loadedGuides[activePack] and next(self.loadedGuides[activePack]) then
        return activePack
    end

    -- No fallback - user must explicitly select a pack
    return nil
end

-- Set the active guide pack
function GLV:SetActiveGuidePack(packName)
    if self.loadedGuides[packName] and next(self.loadedGuides[packName]) then
        self.Settings:SetOption(packName, {"Guide", "ActivePack"})
        self:PopulateDropdown(packName)
        return true
    end
    return false
end

-- Show message when no guides are available
function GLV:ShowNoGuideMessage()
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    if not scrollChild then return end

    -- Clear existing content
    local children = {scrollChild:GetChildren()}
    for _, child in pairs(children) do
        if child and child.Hide then
            child:Hide()
            child:SetParent(nil)
        end
    end

    -- Count available packs
    local packs = self:GetAvailableGuidePacks()
    local packCount = table.getn(packs)

    local message
    if packCount == 0 then
        message = "|cFFFFFF00No guide pack installed.|r\n\nDownload a guide pack addon to get started."
    else
        message = "|cFFFFFF00No guide pack selected.|r\n\nGo to Settings > Guides to choose one."
    end

    -- Create or reuse message frame (styled like a guide step)
    local msgFrame = _G["GLV_NoGuideMessage"]
    if not msgFrame then
        msgFrame = CreateFrame("Frame", "GLV_NoGuideMessage", scrollChild)

        local msgText = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msgText:SetPoint("TOPLEFT", msgFrame, "TOPLEFT", 5, -5)
        msgText:SetJustifyH("LEFT")
        msgFrame.text = msgText
    end

    -- Set width based on parent scroll frame
    local scrollFrame = _G["GLV_MainScrollFrame"]
    local width = scrollFrame and scrollFrame:GetWidth() or 400
    msgFrame:SetWidth(width - 30)
    msgFrame:SetHeight(80)
    msgFrame.text:SetWidth(width - 50)

    msgFrame:SetParent(scrollChild)
    msgFrame:ClearAllPoints()
    msgFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -5)
    msgFrame.text:SetText(message)
    msgFrame:Show()

    -- Disable main dropdown
    local dropdown = _G["GLV_MainDropdown"]
    if dropdown then
        UIDropDownMenu_ClearAll(dropdown)
        UIDropDownMenu_SetText("", dropdown)
        local button = _G[dropdown:GetName().."Button"]
        if button then button:Disable() end
    end

    -- Clear guide name and step counter
    local guideTitle = _G["GLV_MainLoadedGuideTitle"]
    if guideTitle then
        guideTitle:SetText("")
    end
    local stepCounter = _G["GLV_MainLoadedGuideCounter"]
    if stepCounter then
        stepCounter:SetText("")
    end
end

-- Hide the no guide message
function GLV:HideNoGuideMessage()
    local msgFrame = _G["GLV_NoGuideMessage"]
    if msgFrame then
        msgFrame:Hide()
    end
end


--[[ GUIDE REGISTRATION FUNCTIONS ]]--

-- Store addon names for each guide pack
GLV.guidePackAddons = GLV.guidePackAddons or {}

-- Store starting guide mappings for each guide pack (race -> guide name)
GLV.guidePackStartingGuides = GLV.guidePackStartingGuides or {}

-- Register starting guide mappings for a guide pack
-- raceMapping is a table like: { Human = "Elwynn Forest", Dwarf = "Dun Morogh", ... }
function GLV:RegisterStartingGuides(packName, raceMapping)
    if not packName or not raceMapping then return end
    self.guidePackStartingGuides[packName] = raceMapping
end

-- Get the starting guide name for a race in a specific pack
function GLV:GetStartingGuideForRace(packName, race)
    local mapping = self.guidePackStartingGuides[packName]
    if mapping and mapping[race] then
        return mapping[race]
    end
    return nil
end

-- Register a new guide with the system
-- addonName is optional - if provided, it's used to fetch addon metadata (Notes, etc.)
function GLV:RegisterGuide(guideText, group, addonName)
    local guide = self.Parser:parseGuide(guideText, group)
    if not guide then
        return
    end

    if not self.loadedGuides[group] then
        self.loadedGuides[group] = {}
    end

    -- Store addon name for this pack (only once per pack)
    if addonName and not self.guidePackAddons[group] then
        self.guidePackAddons[group] = addonName
    end

    if guide.name ~= nil and guide.id ~= nil then
        if not self.loadedGuides[group][guide.id] then
            self.loadedGuides[group][guide.id] = {
                text = guideText,
                name = guide.name,
                minLevel = guide.minLevel,
                maxLevel = guide.maxLevel,
                description = guide.description,
                faction = guide.faction
            }

            self.Settings:SetOption(group, {"Guide", "CurrentGroup"})

            -- Populate dropdown if scroll child exists
            local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
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

-- Populate the guide selection dropdown with guides from active pack only
function GLV:PopulateDropdown(group)
    local dropdown = _G["GLV_MainDropdown"]
    if not dropdown then
        return
    end

    -- Get active pack (or use provided group as fallback)
    local activePack = self:GetActiveGuidePack()
    if not activePack then
        -- No guides available at all
        UIDropDownMenu_Initialize(dropdown, function()
            local info = {}
            info.text = "No guides available"
            info.disabled = 1
            UIDropDownMenu_AddButton(info)
        end)
        UIDropDownMenu_SetText("Select a guide", dropdown)
        self:ShowNoGuideMessage()
        return
    end

    -- Hide the no guide message if it was shown
    self:HideNoGuideMessage()

    -- Enable the dropdown
    local button = _G[dropdown:GetName().."Button"]
    if button then button:Enable() end

    local guides = self.loadedGuides[activePack]
    if not guides or not next(guides) then
        UIDropDownMenu_Initialize(dropdown, function()
            local info = {}
            info.text = "No guides in this pack"
            info.disabled = 1
            UIDropDownMenu_AddButton(info)
        end)
        UIDropDownMenu_SetText("Select a guide", dropdown)
        return
    end

    -- Get player faction and race for filtering
    local playerFaction = self.Settings:GetOption({"CharInfo", "Faction"})
    local playerRace = self.Settings:GetOption({"CharInfo", "Race"})

    UIDropDownMenu_Initialize(dropdown, function()
        -- Create a sorted list of guides by minLevel then by name
        local sortedGuides = {}
        for guideId, guideData in pairs(guides) do
            -- Filter by faction/race
            -- All values in [GA] must match (AND logic)
            -- e.g., "Horde,Tauren" means player must be Horde AND Tauren
            local showGuide = true
            if guideData.faction and guideData.faction ~= "" then
                for value in string.gfind(guideData.faction .. ",", "([^,]+),") do
                    value = string.gsub(value, "^%s*(.-)%s*$", "%1") -- trim whitespace
                    -- Each value must match either faction or race
                    if value ~= playerFaction and value ~= playerRace then
                        showGuide = false
                        break
                    end
                end
            end

            if showGuide then
                table.insert(sortedGuides, {id = guideId, data = guideData})
            end
        end

        -- Sort by minLevel first, then by name
        table.sort(sortedGuides, function(a, b)
            local aMinLevel = tonumber(a.data.minLevel) or 0
            local bMinLevel = tonumber(b.data.minLevel) or 0

            if aMinLevel ~= bMinLevel then
                return aMinLevel < bMinLevel
            else
                return (a.data.name or "") < (b.data.name or "")
            end
        end)

        -- Add sorted guides to dropdown
        for _, guideEntry in pairs(sortedGuides) do
            local guideId = guideEntry.id
            local guideData = guideEntry.data
            local info = {}
            local displayName = guideData.name
            if guideData.minLevel and guideData.maxLevel then
                displayName = guideData.name .. " (" .. guideData.minLevel .. "-" .. guideData.maxLevel .. ")"
            end
            info.text = displayName
            info.value = guideId
            info.func = createDropdownCallback(activePack, guideId, guideData, displayName, dropdown)
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Set default selection to first guide if none selected
    local currentGuide = self.Settings:GetOption({"Guide", "CurrentGuide"})
    local selected = false

    if currentGuide and guides[currentGuide] then
        local guideData = guides[currentGuide]
        local displayName = guideData.name
        if guideData.minLevel and guideData.maxLevel then
            displayName = guideData.name .. " (" .. guideData.minLevel .. "-" .. guideData.maxLevel .. ")"
        end
        UIDropDownMenu_SetSelectedValue(dropdown, currentGuide)
        UIDropDownMenu_SetText(displayName, dropdown)
        selected = true
    end

    if not selected then
        -- Select first guide
        for guideId, guideData in pairs(guides) do
            local displayName = guideData.name
            if guideData.minLevel and guideData.maxLevel then
                displayName = guideData.name .. " (" .. guideData.minLevel .. "-" .. guideData.maxLevel .. ")"
            end
            UIDropDownMenu_SetSelectedValue(dropdown, guideId)
            UIDropDownMenu_SetText(displayName, dropdown)
            break
        end
    end
end


--[[ GUIDE LOADING FUNCTIONS ]]--

-- Load and display a specific guide
function GLV:LoadGuide(group, guideId)
    if GLV.GuideNavigation then
        GLV.GuideNavigation:ClearAllWaypoints()
    end

    -- Clear previous ongoing steps when changing guides
    if GLV.OngoingStepsManager then
        GLV.OngoingStepsManager:Clear()
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
    
    GLV.Settings:SetOption(guideId, {"Guide", "CurrentGuide"})

    -- Load ongoing steps state for this guide
    if GLV.OngoingStepsManager then
        GLV.OngoingStepsManager:Load(guideId)
    end

    GLV.CurrentGuide = guide

    GLV:CreateGuideSteps(scrollChild, guide, guideId)
    
    local scrollFrame = _G["GLV_MainScrollFrame"]
    if scrollFrame then
        scrollFrame:UpdateScrollChildRect()
        -- Don't reset scroll to 0 - let GuideWriter.lua handle the scroll position
    end
    
    local savedStepState = GLV.Settings:GetOption({"Guide", "Guides", guideId, "StepState"}) or {}
    local savedCurrentStep = GLV.Settings:GetOption({"Guide", "Guides", guideId, "CurrentStep"}) or 0
    
    if savedStepState and next(savedStepState) then
        for stepIndex, isCompleted in pairs(savedStepState) do
            if isCompleted then
                local foundStep = false
                for displayIndex, originalIndex in pairs(GLV.CurrentDisplayToOriginal) do
                    if originalIndex == stepIndex then
                        local stepFrame = _G[scrollChild:GetName() .. "Step" .. guideId .. "_" .. displayIndex]
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
        GLV.Settings:SetOption(savedCurrentStep, {"Guide", "Guides", guideId, "CurrentStep"})
    else
        -- Only calculate first unchecked if we don't have a saved step
        local currentStep = GLV.Settings:GetOption({"Guide", "Guides", guideId, "CurrentStep"}) or 0
        
        if not currentStep or currentStep == 0 then
            -- Let GuideWriter.lua handle this in CreateGuideSteps - it has the proper logic
            -- We just make sure the current step gets reset so CreateGuideSteps will calculate it
            GLV.Settings:SetOption(0, {"Guide", "Guides", guideId, "CurrentStep"})
        end
    end
    
    if GLV.GuideNavigation then
        local currentStep = GLV.Settings:GetOption({"Guide", "Guides", guideId, "CurrentStep"}) or 0
        
        if currentStep > 0 then
            local stepData = nil
            
            if GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[currentStep] then
                stepData = GLV.CurrentDisplaySteps[currentStep]
            elseif guide and guide.steps and guide.steps[currentStep] then
                stepData = guide.steps[currentStep]
            end
            
            if stepData then
                local success, err = pcall(function()
                    GLV.GuideNavigation:OnStepChanged(stepData)
                end)
                if not success and GLV.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[GLV Error]|r Navigation: " .. tostring(err))
                end
            end
        end
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
    
    -- CreateGuideSteps already handles highlighting via updateStepColors
end


-- Debug functions removed - were unused