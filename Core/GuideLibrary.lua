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

-- Filter guides by player faction/race
local function filterGuides(guides, playerFaction, playerRace)
    local filtered = {}
    for guideId, guideData in pairs(guides) do
        local showGuide = true
        if guideData.faction and guideData.faction ~= "" then
            for value in string.gfind(guideData.faction .. ",", "([^,]+),") do
                value = string.gsub(value, "^%s*(.-)%s*$", "%1")
                if value ~= playerFaction and value ~= playerRace then
                    showGuide = false
                    break
                end
            end
        end
        if showGuide then
            table.insert(filtered, {id = guideId, data = guideData})
        end
    end
    -- Sort by minLevel first, then by name
    table.sort(filtered, function(a, b)
        local aMin = tonumber(a.data.minLevel) or 0
        local bMin = tonumber(b.data.minLevel) or 0
        if aMin ~= bMin then
            return aMin < bMin
        else
            return (a.data.name or "") < (b.data.name or "")
        end
    end)
    return filtered
end

-- Build display name for a guide
local function getGuideDisplayName(guideData)
    if guideData.minLevel and guideData.maxLevel then
        return guideData.name .. " (" .. guideData.minLevel .. "-" .. guideData.maxLevel .. ")"
    end
    return guideData.name
end

-- Group guides into level range buckets (1-10, 11-20, etc.)
local function groupGuidesByLevelRange(sortedGuides)
    local groups = {}      -- ordered list of {rangeKey, label, guides}
    local groupMap = {}    -- rangeKey -> index in groups

    for _, guideEntry in ipairs(sortedGuides) do
        local minLvl = tonumber(guideEntry.data.minLevel) or 0
        -- Calculate range bucket: 1-10, 11-20, 21-30, etc.
        local rangeStart
        if minLvl <= 10 then
            rangeStart = 1
        else
            rangeStart = math.floor((minLvl - 1) / 10) * 10 + 1
        end
        local rangeEnd = rangeStart + 9
        local rangeKey = rangeStart .. "-" .. rangeEnd
        local label = "Levels " .. rangeKey

        if not groupMap[rangeKey] then
            local group = {key = rangeKey, label = label, guides = {}}
            table.insert(groups, group)
            groupMap[rangeKey] = table.getn(groups)
        end

        table.insert(groups[groupMap[rangeKey]].guides, guideEntry)
    end

    return groups
end

-- Max buttons per dropdown level in WoW 1.12
local DROPDOWN_MAX_BUTTONS = 30

-- Populate the guide selection dropdown with guides from active pack only
-- Uses multi-level submenus when there are more than DROPDOWN_MAX_BUTTONS guides
function GLV:PopulateDropdown(group)
    local dropdown = _G["GLV_MainDropdown"]
    if not dropdown then
        return
    end

    -- Get active pack (or use provided group as fallback)
    local activePack = self:GetActiveGuidePack()
    if not activePack then
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

    -- Pre-filter and sort guides
    local sortedGuides = filterGuides(guides, playerFaction, playerRace)
    local guideCount = table.getn(sortedGuides)
    local useSubmenus = guideCount > DROPDOWN_MAX_BUTTONS

    if useSubmenus then
        -- Multi-level: level range groups with submenus
        local levelGroups = groupGuidesByLevelRange(sortedGuides)

        UIDropDownMenu_Initialize(dropdown, function(level)
            if not level then level = 1 end

            if level == 1 then
                -- Level 1: show level range categories
                for _, grp in ipairs(levelGroups) do
                    local info = {}
                    info.text = grp.label .. " (" .. table.getn(grp.guides) .. ")"
                    info.value = grp.key
                    info.hasArrow = 1
                    info.notCheckable = 1
                    UIDropDownMenu_AddButton(info, 1)
                end

            elseif level == 2 then
                -- Level 2: show guides in selected range
                local selectedRange = UIDROPDOWNMENU_MENU_VALUE
                for _, grp in ipairs(levelGroups) do
                    if grp.key == selectedRange then
                        for _, guideEntry in ipairs(grp.guides) do
                            local info = {}
                            info.text = getGuideDisplayName(guideEntry.data)
                            info.value = guideEntry.id
                            info.func = createDropdownCallback(activePack, guideEntry.id, guideEntry.data, getGuideDisplayName(guideEntry.data), dropdown)
                            UIDropDownMenu_AddButton(info, 2)
                        end
                        break
                    end
                end
            end
        end)
    else
        -- Flat list: few enough guides to display directly
        UIDropDownMenu_Initialize(dropdown, function()
            for _, guideEntry in ipairs(sortedGuides) do
                local info = {}
                info.text = getGuideDisplayName(guideEntry.data)
                info.value = guideEntry.id
                info.func = createDropdownCallback(activePack, guideEntry.id, guideEntry.data, getGuideDisplayName(guideEntry.data), dropdown)
                UIDropDownMenu_AddButton(info)
            end
        end)
    end

    -- Set default selection
    local currentGuide = self.Settings:GetOption({"Guide", "CurrentGuide"})
    local selected = false

    if currentGuide and guides[currentGuide] then
        local guideData = guides[currentGuide]
        UIDropDownMenu_SetSelectedValue(dropdown, currentGuide)
        UIDropDownMenu_SetText(getGuideDisplayName(guideData), dropdown)
        selected = true
    end

    if not selected and table.getn(sortedGuides) > 0 then
        local first = sortedGuides[1]
        UIDropDownMenu_SetSelectedValue(dropdown, first.id)
        UIDropDownMenu_SetText(getGuideDisplayName(first.data), dropdown)
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


--[[ GUIDE SELECTION FUNCTIONS ]]--

-- Automatically load the appropriate guide based on player level and race
function GLV:LoadDefaultGuideForRace(race)
    local activePack = self:GetActiveGuidePack()
    if not activePack then return end

    local guides = self.loadedGuides[activePack]
    if not guides then return end

    -- First, try to load saved guide
    local savedGuideId = self.Settings:GetOption({"Guide", "CurrentGuide"})
    if savedGuideId and savedGuideId ~= "Unknown" and guides[savedGuideId] then
        self:LoadGuide(activePack, savedGuideId)
        GLV.QuestTracker:SyncQuestAcceptSteps()
        return
    end

    -- Load guide based on player level and race
    local playerLevel = UnitLevel("player")
    local bestGuide = nil

    -- For low level players (1-11), use race-based starting guides
    if playerLevel <= 11 and race then
        bestGuide = self:FindStartingGuideForRace(race, activePack)
    end

    -- For higher level players, or if no race guide found, use level-based selection
    if not bestGuide then
        bestGuide = self:FindBestGuideForLevel(playerLevel, activePack)
    end

    if bestGuide then
        self:LoadGuide(activePack, bestGuide.id)
        GLV.QuestTracker:SyncQuestAcceptSteps()
    end
end

-- TurtleWoW custom races mapped to their closest standard race
-- Used as fallback when guide packs don't include TurtleWoW-specific mappings
local RACE_ALIASES = {
    ["HighElf"] = "NightElf",
}

-- Find starting guide based on player race for new characters
function GLV:FindStartingGuideForRace(race, packName)
    local guides = self.loadedGuides[packName]
    if not guides then return nil end

    -- Get the starting guide name from the pack's registered mapping
    local targetGuideName = self:GetStartingGuideForRace(packName, race)

    -- Try race alias if no direct mapping (TurtleWoW custom races)
    if not targetGuideName and RACE_ALIASES[race] then
        targetGuideName = self:GetStartingGuideForRace(packName, RACE_ALIASES[race])
    end

    if not targetGuideName then return nil end

    for guideId, guideData in pairs(guides) do
        if guideData.name == targetGuideName then
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Guide Loading]|r Selected starting guide: " .. guideData.name .. " for " .. race)
            end
            return {id = guideId, data = guideData}
        end
    end

    return nil
end

-- Find the best guide for player's current level
function GLV:FindBestGuideForLevel(playerLevel, packName)
    local guides = self.loadedGuides[packName]
    if not guides then return nil end

    -- Collect and sort guides for deterministic selection
    local sorted = {}
    for guideId, guideData in pairs(guides) do
        if guideData.minLevel and guideData.maxLevel then
            local minLevel = tonumber(guideData.minLevel)
            local maxLevel = tonumber(guideData.maxLevel)
            if minLevel and maxLevel then
                table.insert(sorted, {id = guideId, data = guideData, min = minLevel, max = maxLevel})
            end
        end
    end
    table.sort(sorted, function(a, b)
        if a.min ~= b.min then return a.min < b.min end
        return (a.data.name or "") < (b.data.name or "")
    end)

    local bestGuide = nil
    local bestMatch = 999

    for _, entry in ipairs(sorted) do
        if playerLevel >= entry.min and playerLevel <= entry.max then
            -- Perfect match - player level is in guide range, pick first sorted
            bestGuide = {id = entry.id, data = entry.data}
            break
        elseif entry.min <= playerLevel then
            -- Guide is below player level, but could be close
            local levelDiff = playerLevel - entry.max
            if levelDiff < bestMatch then
                bestMatch = levelDiff
                bestGuide = {id = entry.id, data = entry.data}
            end
        end
    end

    if GLV.Debug then
        if bestGuide then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Guide Loading]|r Selected guide: " .. bestGuide.data.name .. " for level " .. playerLevel)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Guide Loading]|r No suitable guide found for level " .. playerLevel)
        end
    end

    return bestGuide
end