--[[
Guidelime Vanilla
Author: Grommey

Description:
Guide Writer rework.
Display steps in a single frame with multiple lines, icon beside line, checkbox at right.
]]--
local GLV = LibStub("GuidelimeVanilla")

local CONFIG = {
    spacing = -4,
    lineHeight = 14,
    checkboxSize = 24,
    textOffset = 30,
    iconWidth = 13,
    totalWidth = 270,
    fontLineHeight = 13,
    ocSpacing = 6,
    lineSpacing = 4,
    iconYOffset = 0,
    backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true,
        tileSize = 16,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    },
    colors = {
        even = {0.2,0.2,0.2,0.8},
        odd = {0.1,0.1,0.1,0.8},
        active = {0.8,0.8,0.2,0.9},
        ongoing = {0.3,0.5,0.8,0.9}
    },
    titleFrame = GLV_MainLoadedGuideTitle
}

-- Get the guide text scale from settings
local function getGuideTextScale()
    if GLV.Settings and GLV.Settings.GetOption then
        return GLV.Settings:GetOption({"UI", "GuideTextScale"}) or 1
    end
    return 1
end

-- Get scaled font line height
local function getScaledFontLineHeight()
    return CONFIG.fontLineHeight * getGuideTextScale()
end

-- Apply scale to a FontString by setting custom font size
local function applyTextScale(fontString)
    local scale = getGuideTextScale()
    if scale ~= 1 then
        -- Get current font info and apply scaled size
        local fontFile, fontSize, fontFlags = fontString:GetFont()
        if fontFile and fontSize then
            fontString:SetFont(fontFile, fontSize * scale, fontFlags or "")
        end
    end
end

-- Reusable FontString for text measurement (prevents memory leak)
local measureFontString = nil

--[[ ONGOING STEPS MANAGER ]]--
-- Manages pinned ongoing steps that remain visible at top while guide progresses

local OngoingStepsManager = {
    activeSteps = {},  -- {displayIndex = true}
}

function OngoingStepsManager:Activate(displayIndex)
    self.activeSteps[displayIndex] = true
    self:Save()
end

function OngoingStepsManager:Deactivate(displayIndex)
    self.activeSteps[displayIndex] = nil
    self:Save()
end

function OngoingStepsManager:IsActive(displayIndex)
    return self.activeSteps[displayIndex] == true
end

function OngoingStepsManager:GetActiveIndices()
    local indices = {}
    for idx, _ in pairs(self.activeSteps) do
        table.insert(indices, idx)
    end
    table.sort(indices)
    return indices
end

function OngoingStepsManager:GetActiveCount()
    local count = 0
    for _ in pairs(self.activeSteps) do
        count = count + 1
    end
    return count
end

function OngoingStepsManager:Save()
    local guideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"})
    if guideId then
        GLV.Settings:SetOption(self.activeSteps, {"Guide", "Guides", guideId, "ActiveOngoingSteps"})
    end
end

function OngoingStepsManager:Load(guideId)
    if guideId then
        self.activeSteps = GLV.Settings:GetOption({"Guide", "Guides", guideId, "ActiveOngoingSteps"}) or {}
    else
        self.activeSteps = {}
    end
end

function OngoingStepsManager:Clear()
    self.activeSteps = {}
end

GLV.OngoingStepsManager = OngoingStepsManager

--[[ PINNED SECTION FUNCTIONS ]]--

-- Cleanup all children from a frame
local function cleanupFrameChildren(frame)
    if not frame then return end
    local children = {frame:GetChildren()}
    for _, child in pairs(children) do
        if child and type(child) == "table" then
            child:Hide()
            child:SetParent(nil)
        end
    end
    local regions = {frame:GetRegions()}
    for _, region in pairs(regions) do
        if region and region.Hide then
            region:Hide()
        end
    end
end

-- Adjust scroll frame position based on pinned section height
local function AdjustScrollFramePosition(pinnedHeight)
    local scrollFrame = getglobal("GLV_MainScrollFrame")
    local pinnedFrame = getglobal("GLV_MainPinnedSteps")

    if not scrollFrame then return end

    -- Base offset is -65 from top of GLV_Main
    local baseYOffset = -65

    if pinnedHeight > 0 and pinnedFrame then
        pinnedFrame:SetHeight(pinnedHeight)
        pinnedFrame:Show()
        -- Adjust Y offset to account for pinned section
        local newYOffset = baseYOffset - pinnedHeight - 5
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", GLV_Main, "TOPLEFT", 15, newYOffset)
        scrollFrame:SetHeight(285 - pinnedHeight - 5)
    else
        if pinnedFrame then
            pinnedFrame:Hide()
        end
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", GLV_Main, "TOPLEFT", 15, baseYOffset)
        scrollFrame:SetHeight(285)
    end
end

-- Debounce control for RefreshGuide
local refreshGuideScheduled = false
GLV.RefreshGuidePending = false

-- Track FontStrings for XP progress updates
GLV.XPProgressTrackers = {}

-- Track FontStrings for ongoing step objectives
GLV.OngoingObjectivesTrackers = {}

-- Update ongoing objectives display (called by QuestTracker events)
function GLV:UpdateOngoingObjectivesDisplay()
    if not GLV.QuestTracker or not GLV.OngoingObjectivesTrackers then return end
    if table.getn(GLV.OngoingObjectivesTrackers) == 0 then return end

    -- Group trackers by questId to avoid repeated quest log lookups
    local questObjectivesCache = {}

    for _, tracker in ipairs(GLV.OngoingObjectivesTrackers) do
        if tracker.fontString and tracker.questId then
            -- Get objectives from cache or fetch
            if not questObjectivesCache[tracker.questId] then
                local objectives, _, _ = GLV.QuestTracker:GetQuestProgress(tracker.questId)
                questObjectivesCache[tracker.questId] = objectives or {}
            end

            local objectives = questObjectivesCache[tracker.questId]
            if objectives and objectives[tracker.objectiveIndex] then
                local obj = objectives[tracker.objectiveIndex]
                local objColor = obj.completed and "|cFF00FF00" or "|cFFFFFF00"
                local objText = objColor .. "  - " .. obj.text .. "|r"
                tracker.fontString:SetText(objText)
            end
        end
    end
end

-- Update XP progress display on tracked FontStrings (active step and ongoing steps)
function GLV:UpdateXPProgressDisplay()
    if not GLV.CharacterTracker or not GLV.XPProgressTrackers then return end

    -- Get current active step
    local currentGuideId = GLV.Settings:GetOption({"Guide", "CurrentGuide"}) or "Unknown"
    local activeStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0

    for _, tracker in ipairs(GLV.XPProgressTrackers) do
        if tracker.fontString and tracker.experienceRequirement and tracker.originalText then
            -- Show progress on ongoing steps only (active step XP shown in navigation frame)
            local isOngoingStep = OngoingStepsManager and OngoingStepsManager:IsActive(tracker.stepIndex)

            if isOngoingStep then
                local progress, isDone = GLV.CharacterTracker:GetXPProgress(tracker.experienceRequirement)
                if progress then
                    -- Put progress on a new line with empty line before
                    local newText = tracker.originalText .. "\n\n" .. progress
                    tracker.fontString:SetText(newText)
                else
                    tracker.fontString:SetText(tracker.originalText)
                end
            else
                -- Not active or ongoing step, show original text without progress
                tracker.fontString:SetText(tracker.originalText)
            end
        end
    end
end

--[[ UI CREATION FUNCTIONS ]]--

-- Create and set the guide title with level range information
local function createTitle(guide)
    GLV_MainLoadedGuideTitle:SetText(guide.name .. " (" .. guide.minLevel .. "-" .. guide.maxLevel .. ")")
end

-- Wrap text to fit within specified width and return wrapped text with line count and height
local function wrapText(inputText, maxWidth, font, textScale)
    local wrappedText = ""
    local lineCount = 0
    local segments = {}
    inputText = inputText or ""
    textScale = textScale or getGuideTextScale()

    -- Adjust maxWidth for scale (text will be scaled up, so we need to account for that)
    local adjustedMaxWidth = maxWidth / textScale

    -- Convert \\ to newline
    inputText = string.gsub(inputText, "\\\\", "\n")
    for segment in string.gfind(inputText, "([^\n]*)\n?") do
        if segment and segment ~= "" then table.insert(segments, segment) end
    end

    -- Reuse a single FontString for measurement to prevent memory leaks
    if not measureFontString then
        measureFontString = UIParent:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
        measureFontString:Hide()
    end
    local tempText = measureFontString

    for i, segment in ipairs(segments) do
        local currentLine = ""
        local words = {}
        for word in string.gfind(segment, "[%S]+") do table.insert(words, word) end
        for j, word in ipairs(words) do
            local testLine = currentLine == "" and word or currentLine.." "..word
            tempText:SetText(testLine)
            if tempText:GetStringWidth() <= adjustedMaxWidth then
                currentLine = testLine
            else
                wrappedText = wrappedText..(wrappedText=="" and "" or "\n")..currentLine
                lineCount = lineCount + 1
                currentLine = word
            end
        end
        if currentLine ~= "" then
            wrappedText = wrappedText..(wrappedText=="" and "" or "\n")..currentLine
            lineCount = lineCount + 1
        end
        if i < safe_tablelen(segments) then
            wrappedText = wrappedText.."\n"
            lineCount = lineCount + 1
        end
    end
    local textHeight = tempText:GetHeight() * lineCount * textScale
    return wrappedText, lineCount, textHeight
end

-- Create checkbox for step completion with proper textures and positioning
local function createCheckbox(frame)
    local check = CreateFrame("CheckButton", frame:GetName().."Check", frame)
    check:SetWidth(CONFIG.checkboxSize)
    check:SetHeight(CONFIG.checkboxSize)
    check:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
    local textures = {
        {method="SetNormalTexture", path="Interface\\Buttons\\UI-CheckBox-Up", layer="BACKGROUND"},
        {method="SetHighlightTexture", path="Interface\\Buttons\\UI-CheckBox-Highlight", layer="HIGHLIGHT"},
        {method="SetPushedTexture", path="Interface\\Buttons\\UI-CheckBox-Down", layer="ARTWORK"},
        {method="SetCheckedTexture", path="Interface\\Buttons\\UI-CheckBox-Check", layer="ARTWORK"}
    }
    for _, tex in ipairs(textures) do
        local t = check:CreateTexture(nil, tex.layer)
        t:SetTexture(tex.path)
        t:SetAllPoints(check)
        check[tex.method](check, t)
    end
    return check
end


--[[ ITEM INTERACTION FUNCTIONS ]]--

-- Find an item in bags by itemId and use it (WoW 1.12 compatible)
local function useItemById(itemId)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link and string.find(link, "item:"..itemId..":") then
                    UseContainerItem(bag, slot)
                    return true
                end
            end
        end
    end
    return false
end


--[[ STEP GROUPING FUNCTIONS ]]--

-- Group steps: combine OC steps with main lines
local function groupSteps(guide, stepState, currentGuideId)
    if not guide or not guide.steps then
        return {}, {}, {}
    end
    
    local displaySteps = {}
    local originalIndexToDisplayIndex = {}
    local displayIndexToOriginalIndex = {}
    
    local i = 1
    while i <= safe_tablelen(guide.steps) do
        local stepFrameData = {lines={}, icon=nil, hasCheckbox=false, questTags={}, learnTags={}}
        
        -- Collect [OC] lines
        while i <= safe_tablelen(guide.steps) and guide.steps[i] and (guide.steps[i].emptyLine or guide.steps[i].complete_with_next) do
            table.insert(stepFrameData.lines, {
                text = guide.steps[i].text,
                isOC = guide.steps[i].emptyLine or guide.steps[i].complete_with_next,
                icon = guide.steps[i].icon,
                useItemId = guide.steps[i].useItemId,
                equipItemId = guide.steps[i].equipItemId,
                questId = guide.steps[i].questId,
                coords = guide.steps[i].coords,
                stepType = guide.steps[i].stepType,
                questTags = guide.steps[i].questTags,
                experienceRequirement = guide.steps[i].experienceRequirement,
                learnTags = guide.steps[i].learnTags,
                destination = guide.steps[i].destination,
                bindLocation = guide.steps[i].bindLocation,
                collectItems = guide.steps[i].collectItems,
                targetIds = guide.steps[i].targetIds,
                hearthDestination = guide.steps[i].hearthDestination,
                learnSpells = guide.steps[i].learnSpells,
            })
            if guide.steps[i].icon and not stepFrameData.icon then
                stepFrameData.icon = guide.steps[i].icon
            end
            if guide.steps[i].questTags then
                for _, tag in ipairs(guide.steps[i].questTags) do
                    table.insert(stepFrameData.questTags, tag)
                end
            end
            if guide.steps[i].experienceRequirement then
                stepFrameData.hasCheckbox = true
            end
            i = i + 1
        end

        -- Add main line
        if i <= safe_tablelen(guide.steps) and guide.steps[i] then
            table.insert(stepFrameData.lines, {
                text = guide.steps[i].text,
                isOC = guide.steps[i].emptyLine or guide.steps[i].complete_with_next,
                icon = guide.steps[i].icon,
                useItemId = guide.steps[i].useItemId,
                equipItemId = guide.steps[i].equipItemId,
                questId = guide.steps[i].questId,
                coords = guide.steps[i].coords,
                stepType = guide.steps[i].stepType,
                questTags = guide.steps[i].questTags,
                experienceRequirement = guide.steps[i].experienceRequirement,
                learnTags = guide.steps[i].learnTags,
                destination = guide.steps[i].destination,
                bindLocation = guide.steps[i].bindLocation,
                collectItems = guide.steps[i].collectItems,
                targetIds = guide.steps[i].targetIds,
                hearthDestination = guide.steps[i].hearthDestination,
                learnSpells = guide.steps[i].learnSpells,
            })

            stepFrameData.hasCheckbox = true

            -- Propagate ongoing flag from parsed step
            stepFrameData.ongoing = guide.steps[i].ongoing or false

            if guide.steps[i].experienceRequirement then
                stepFrameData.hasCheckbox = true
            end
            if guide.steps[i].icon and not stepFrameData.icon then
                stepFrameData.icon = guide.steps[i].icon
            end
            if guide.steps[i].questTags then
                for _, tag in ipairs(guide.steps[i].questTags) do
                    table.insert(stepFrameData.questTags, tag)
                end
            end

            local displayIndex = safe_tablelen(displaySteps) + 1
            originalIndexToDisplayIndex[i] = displayIndex
            displayIndexToOriginalIndex[displayIndex] = i
            i = i + 1
        end
        table.insert(displaySteps, stepFrameData)
    end
    
    -- Handle next guide checkbox
    if guide.clickToNext and guide.next and safe_tablelen(displaySteps) > 0 then
        local lastStepIndex = safe_tablelen(displaySteps)
        displaySteps[lastStepIndex].hasCheckbox = true
    end
    
    return displaySteps, originalIndexToDisplayIndex, displayIndexToOriginalIndex
end

--[[ SCROLL MANAGEMENT FUNCTIONS ]]--

-- Calculate scroll position for a specific step
-- Counts heights of all frames BEFORE the active step in the scroll child
local function calculateScrollPosition(stepIndex, scrollChild, guideId, spacing)
    local targetScroll = 0
    local framesFound = 0

    for i = 1, stepIndex - 1 do
        -- Only count frames that were created in this refresh (tracked in CurrentFrameIndices)
        if GLV.CurrentFrameIndices and GLV.CurrentFrameIndices[i] then
            local frameName = scrollChild:GetName().."Step"..guideId.."_"..i
            local stepFrame = getglobal(frameName)
            if stepFrame then
                local frameHeight = stepFrame:GetHeight()
                if frameHeight and frameHeight > 0 then
                    targetScroll = targetScroll + frameHeight
                    framesFound = framesFound + 1
                end
            end
        end
    end

    -- Add spacing for frames that exist
    if framesFound > 0 then
        targetScroll = targetScroll + (math.abs(spacing) * framesFound)
    end

    return math.max(0, targetScroll)
end

-- Scroll to specific step (positions it at top of visible area)
local function scrollToStep(stepIndex, scrollChild, guideId, spacing)
    if stepIndex > 0 and GLV_MainScrollFrame then
        local targetScroll = calculateScrollPosition(stepIndex, scrollChild, guideId, spacing)
        local maxScroll = GLV_MainScrollFrame:GetVerticalScrollRange()
        if maxScroll and maxScroll > 0 then
            targetScroll = math.min(targetScroll, maxScroll)
        end
        GLV_MainScrollFrame:SetVerticalScroll(targetScroll)
    end
end

--[[ CHECKBOX LOGIC FUNCTIONS ]]--

-- Update step colors by rebuilding the UI (SetBackdropColor doesn't work after frame creation)
-- This function is kept for backwards compatibility with QuestTracker and TaxiTracker
local function updateStepColors(scrollChild, guideId, displaySteps, activeStepIndex)
    -- Just rebuild the UI - colors are set correctly during frame creation
    GLV:RefreshGuide()
end

-- Parse guide name content using the same logic as the parser
local function parseGuideNameContent(content)
    local lvlMin, lvlMax, guideName
    
    -- Pattern 1: "1-11 Dun Morogh" or "1-11 Dun Morogh"
    lvlMin, lvlMax, guideName = string.match(content, "(%d+)%s*%-%s*(%d+)%s*(.+)")
    
    -- Pattern 2: "1 11 Dun Morogh" (without dash)
    if not lvlMin then
        lvlMin, lvlMax, guideName = string.match(content, "(%d+)%s+(%d+)%s+(.+)")
    end
    
    -- Pattern 3: Just try to extract any numbers and text
    if not lvlMin then
        lvlMin, lvlMax, guideName = string.match(content, "(%d+)%s*[%-%s]%s*(%d+)%s*(.+)")
    end
    
    return lvlMin, lvlMax, guideName
end

-- Handle next guide loading
local function handleNextGuideLoad(guide, currentIndex, displaySteps)
    if guide.next and guide.clickToNext and currentIndex == safe_tablelen(displaySteps) then
        local nextGuideContent = guide.next
        
        -- Parse the next guide content using the same logic as the parser
        -- Format: "XX-XX Name" where XX-XX are levels and Name is the guide name
        local nextMinLevel, nextMaxLevel, nextGuideName = parseGuideNameContent(nextGuideContent)
        
        if not nextGuideName then
            return
        end
        
        -- Generate the expected guide ID using the same logic as the parser
        local expectedGuideId = "Unknown"
        if nextGuideName and nextGuideName ~= "" then
            expectedGuideId = string.gsub(nextGuideName, "%s+", "_")
            if nextMinLevel and nextMinLevel ~= "" then
                expectedGuideId = expectedGuideId .. "_" .. nextMinLevel
            end
            if nextMaxLevel and nextMaxLevel ~= "" then
                expectedGuideId = expectedGuideId .. "_" .. nextMaxLevel
            end
        end
        
        -- Look for exact match using the guide ID
        for groupName, groupGuides in pairs(GLV.loadedGuides) do
            if groupGuides then
                for guideId, guideData in pairs(groupGuides) do
                    if guideId == expectedGuideId then
                        GLV:LoadGuide(groupName, guideId)
                        return
                    end
                end
            end
        end
    end
end

-- Find the first unchecked step with checkbox
local function findFirstUncheckedStep(displaySteps, displayIndexToOriginalIndex, stepState)
    for i = 1, table.getn(displaySteps) do
        if displaySteps[i] and displaySteps[i].hasCheckbox then
            local orig = displayIndexToOriginalIndex[i]
            if orig and not stepState[orig] then
                return i
            end
        end
    end
    return 1 -- Fallback to first step
end

-- Calculate new active step based on checkbox state
local function calculateNewActiveStep(checked, currentIndex, currentActiveStep, displaySteps, displayIndexToOriginalIndex, stepState)
    -- Always recalculate to find the first unchecked step
    local firstUnchecked = findFirstUncheckedStep(displaySteps, displayIndexToOriginalIndex, stepState)

    -- If all steps are checked, stay on the last step with a checkbox
    if firstUnchecked == 1 and stepState[displayIndexToOriginalIndex[1]] then
        local totalSteps = table.getn(displaySteps)
        for i = totalSteps, 1, -1 do
            if displaySteps[i] and displaySteps[i].hasCheckbox then
                return i
            end
        end
    end

    return firstUnchecked
end

--[[ MAIN GUIDE FUNCTIONS ]]--

-- Public: rebuild the guide UI using the current guide and main scroll child
-- Uses debounce to prevent multiple rapid refreshes
function GLV:RefreshGuide()
    -- Debounce: if refresh is already scheduled, skip
    if refreshGuideScheduled then
        return
    end

    local guide = GLV.CurrentGuide
    if not guide then return end
    local scrollChild = GLV_MainScrollFrameScrollChild
    if not scrollChild and GLV_MainScrollFrame and GLV_MainScrollFrame.GetScrollChild then
        scrollChild = GLV_MainScrollFrame:GetScrollChild()
    end
    if not scrollChild then return end

    -- Mark as scheduled to prevent multiple calls
    refreshGuideScheduled = true
    GLV.RefreshGuidePending = true

    -- Use a small delay to batch multiple refresh requests
    GLV.Ace:ScheduleEvent("GLV_RefreshGuide", function()
        refreshGuideScheduled = false
        self:CreateGuideSteps(scrollChild, guide, guide.id)
    end, 0.1)
end

-- Create and display all guide steps in the UI with proper grouping and layout
function GLV:CreateGuideSteps(scrollChild, guide, guideId, callback)
    if not scrollChild or not scrollChild.GetNumChildren then 
        if callback then callback() end
        return 
    end
    if not guide or not guide.steps then 
        if callback then callback() end
        return 
    end

    -- Cleanup previous children
    local children = {scrollChild:GetChildren()}
    for i, child in pairs(children) do
        if child and type(child) == "table" then
            child:Hide()
            child:SetParent(nil)
        end
    end

    -- Clear progress trackers for new guide
    GLV.XPProgressTrackers = {}
    GLV.OngoingObjectivesTrackers = {}

    -- Track which step indices have frames created in this refresh
    GLV.CurrentFrameIndices = {}

    local lastLine = nil
    local totalHeight = 0
    local currentGuideId = guideId or guide.id or "Unknown"
    local stepState = GLV.Settings:GetOption({"Guide","Guides", currentGuideId, "StepState"}) or {}
    
    -- expose current guide to other modules (e.g., quest tracker)
    GLV.CurrentGuide = guide
    
    -- Use extracted function to group steps
    local displaySteps, originalIndexToDisplayIndex, displayIndexToOriginalIndex = groupSteps(guide, stepState, currentGuideId)

    local currentStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
    GLV_MainLoadedGuideCounter:SetText("("..currentStep.."/"..safe_tablelen(displaySteps)..")")

    GLV.CurrentStepIndexMap = originalIndexToDisplayIndex
    GLV.CurrentDisplayStepsCount = safe_tablelen(displaySteps)
    GLV.CurrentDisplaySteps = displaySteps
    GLV.CurrentDisplayHasCheckbox = {}
    for di, st in ipairs(displaySteps) do
        GLV.CurrentDisplayHasCheckbox[di] = st.hasCheckbox and true or false
    end
    GLV.CurrentDisplayToOriginal = displayIndexToOriginalIndex

    -- Calculate activeStep BEFORE creating frames so we can set the right color
    local totalSteps = table.getn(displaySteps)

    -- Find first unchecked step (the "real" position in the guide)
    local firstUncheckedStep = 0
    for i2 = 1, totalSteps do
        if displaySteps[i2] and displaySteps[i2].hasCheckbox then
            local orig = displayIndexToOriginalIndex[i2]
            if orig and not stepState[orig] then
                firstUncheckedStep = i2
                break
            end
        end
    end

    -- Deactivate ongoing steps that are now AFTER the first unchecked step
    -- This handles the case when user unchecks steps and goes back in the guide
    if firstUncheckedStep > 0 then
        local ongoingIndicesToDeactivate = {}
        for _, ongoingIdx in ipairs(OngoingStepsManager:GetActiveIndices()) do
            if ongoingIdx > firstUncheckedStep then
                table.insert(ongoingIndicesToDeactivate, ongoingIdx)
            end
        end
        for _, idx in ipairs(ongoingIndicesToDeactivate) do
            OngoingStepsManager:Deactivate(idx)
        end
    end

    -- Calculate activeStep - use firstUncheckedStep as base
    local activeStep = firstUncheckedStep
    if activeStep == 0 and totalSteps > 0 then
        -- All steps completed, use last step with checkbox
        for i2 = totalSteps, 1, -1 do
            if displaySteps[i2] and displaySteps[i2].hasCheckbox then
                activeStep = i2
                break
            end
        end
    end
    -- Final fallback
    if activeStep == 0 then
        activeStep = 1
    end
    -- Don't save yet - ongoing activation block below might update activeStep

    -- Handle ongoing step activation: if active step is an [O] step, activate it and find next non-ongoing step
    local activeStepData = displaySteps[activeStep]
    if activeStepData and activeStepData.ongoing then
        local origIdx = displayIndexToOriginalIndex[activeStep]
        if origIdx and not stepState[origIdx] then
            -- Activate this ongoing step
            if not OngoingStepsManager:IsActive(activeStep) then
                OngoingStepsManager:Activate(activeStep)
            end
            -- Find next non-ongoing unchecked step
            for i2 = activeStep + 1, totalSteps do
                if displaySteps[i2] and displaySteps[i2].hasCheckbox then
                    local orig = displayIndexToOriginalIndex[i2]
                    if orig and not stepState[orig] then
                        if not displaySteps[i2].ongoing then
                            activeStep = i2
                            GLV.Settings:SetOption(activeStep, {"Guide", "Guides", currentGuideId, "CurrentStep"})
                            break
                        else
                            -- Another ongoing step, activate it too
                            if not OngoingStepsManager:IsActive(i2) then
                                OngoingStepsManager:Activate(i2)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Save activeStep after ongoing activation logic has potentially updated it
    GLV.Settings:SetOption(activeStep, {"Guide", "Guides", currentGuideId, "CurrentStep"})

    -- Render pinned ongoing steps section
    local pinnedChild = getglobal("GLV_MainPinnedStepsChild")
    local pinnedFrame = getglobal("GLV_MainPinnedSteps")
    local ongoingIndices = OngoingStepsManager:GetActiveIndices()
    local pinnedTotalHeight = 0

    if pinnedChild and pinnedFrame then
        cleanupFrameChildren(pinnedChild)

        if table.getn(ongoingIndices) > 0 then
            local pinnedLastLine = nil

            for _, ongoingIdx in ipairs(ongoingIndices) do
                local step = displaySteps[ongoingIdx]
                if step then
                    local origIndexForThisStep = displayIndexToOriginalIndex[ongoingIdx]
                    local isCompleted = origIndexForThisStep and stepState[origIndexForThisStep]

                    -- Skip if already completed
                    if not isCompleted then
                        local frameName = pinnedChild:GetName().."PinnedStep"..guideId.."_"..ongoingIdx
                        local frame = CreateFrame("Frame", frameName, pinnedChild)

                        frame:Show()
                        frame:SetWidth(CONFIG.totalWidth)
                        frame:SetBackdrop(CONFIG.backdrop)
                        if frame.EnableMouse then frame:EnableMouse(true) end

                        -- Use BLUE color for ongoing steps
                        frame:SetBackdropColor(unpack(CONFIG.colors.ongoing))

                        local yOffset = -2
                        local frameHeight = 0

                        for li, line in ipairs(step.lines) do
                            local hasIcon = type(line.icon) == "string" and line.icon ~= "" and line.icon ~= nil
                            local reservedIconWidth = CONFIG.iconWidth + 4
                            local availableWidth = CONFIG.totalWidth - CONFIG.checkboxSize - 16 - reservedIconWidth

                            local textFrame = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
                            applyTextScale(textFrame)
                            local wrappedText, lineCount, textHeight = wrapText(line.text or "", availableWidth)
                            textFrame:SetText(wrappedText)
                            textFrame:SetJustifyH("LEFT")
                            textFrame:SetJustifyV("TOP")
                            textFrame:SetWidth(availableWidth)
                            local scaledLineHeight = getScaledFontLineHeight()
                            local usedHeight = (lineCount * scaledLineHeight)

                            -- Reserve extra height for XP progress (empty line + progress bar)
                            if line.experienceRequirement then
                                usedHeight = usedHeight + (scaledLineHeight * 2)
                            end

                            textFrame:SetHeight(usedHeight)

                            -- Track [XP] steps for progress display in pinned section
                            if line.experienceRequirement then
                                table.insert(GLV.XPProgressTrackers, {
                                    fontString = textFrame,
                                    experienceRequirement = line.experienceRequirement,
                                    originalText = wrappedText,
                                    originalHeight = usedHeight,
                                    stepIndex = ongoingIdx
                                })
                            end

                            local offsetX = reservedIconWidth

                            if hasIcon then
                                local iconButton = CreateFrame("Button", nil, pinnedChild)
                                iconButton:SetWidth(CONFIG.iconWidth)
                                iconButton:SetHeight(CONFIG.iconWidth)
                                iconButton:SetPoint("TOPRIGHT", textFrame, "TOPLEFT", -2, CONFIG.iconYOffset)
                                iconButton:EnableMouse(true)
                                iconButton:SetFrameStrata("TOOLTIP")
                                iconButton:Show()

                                local icon = iconButton:CreateTexture(nil, "OVERLAY")
                                icon:SetAllPoints(iconButton)

                                -- Try to get fresh texture for items (in case it was cached since parsing)
                                local textureToUse = line.icon
                                if line.useItemId then
                                    local itemId = tonumber(line.useItemId)
                                    if itemId then
                                        local _, _, _, _, _, _, _, _, freshTexture = GetItemInfo(itemId)
                                        if freshTexture then
                                            textureToUse = freshTexture
                                        end
                                    end
                                end
                                icon:SetTexture(textureToUse)

                                if line.useItemId then
                                    local itemIdForClick = line.useItemId
                                    local function handleUse()
                                        useItemById(itemIdForClick)
                                    end
                                    iconButton:SetScript("OnClick", handleUse)
                                end
                            end

                            textFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 2 + offsetX, yOffset)
                            yOffset = yOffset - (usedHeight + (line.isOC and CONFIG.ocSpacing or CONFIG.lineSpacing))
                            frameHeight = frameHeight + (usedHeight + (line.isOC and CONFIG.ocSpacing or CONFIG.lineSpacing))
                        end

                        -- Add quest objectives for ongoing steps
                        if step.questTags and table.getn(step.questTags) > 0 then
                            for _, questTag in ipairs(step.questTags) do
                                if questTag.questId and GLV.QuestTracker then
                                    local objectives, allComplete, numObjectives = GLV.QuestTracker:GetQuestProgress(questTag.questId)
                                    if objectives and table.getn(objectives) > 0 then
                                        for objIdx, obj in ipairs(objectives) do
                                            local objColor = obj.completed and "|cFF00FF00" or "|cFFFFFF00"
                                            local objText = objColor .. "  - " .. obj.text .. "|r"

                                            local objFrame = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                                            applyTextScale(objFrame)
                                            local reservedIconWidth = CONFIG.iconWidth + 4
                                            local availableWidth = CONFIG.totalWidth - CONFIG.checkboxSize - 16 - reservedIconWidth
                                            local wrappedObj, objLineCount = wrapText(objText, availableWidth)
                                            objFrame:SetText(wrappedObj)
                                            objFrame:SetJustifyH("LEFT")
                                            objFrame:SetJustifyV("TOP")
                                            objFrame:SetWidth(availableWidth)
                                            local objHeight = objLineCount * getScaledFontLineHeight()
                                            objFrame:SetHeight(objHeight)
                                            objFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 2 + reservedIconWidth, yOffset)

                                            yOffset = yOffset - (objHeight + 2)
                                            frameHeight = frameHeight + (objHeight + 2)

                                            -- Track for updates
                                            table.insert(GLV.OngoingObjectivesTrackers, {
                                                fontString = objFrame,
                                                questId = questTag.questId,
                                                objectiveIndex = objIdx,
                                                pinnedStepIdx = ongoingIdx
                                            })
                                        end
                                    end
                                end
                            end
                        end

                        -- Checkbox for pinned step
                        if step.hasCheckbox then
                            local check = createCheckbox(frame)
                            check:SetChecked(false)
                            local capturedIdx = ongoingIdx
                            check:SetScript("OnClick", function()
                                local checked = not not check:GetChecked()
                                local origIdx = displayIndexToOriginalIndex[capturedIdx]
                                if origIdx then
                                    stepState[origIdx] = checked
                                    GLV.Settings:SetOption(stepState, {"Guide","Guides", currentGuideId, "StepState"})
                                end
                                if checked then
                                    -- Deactivate the ongoing step when completed
                                    OngoingStepsManager:Deactivate(capturedIdx)
                                end
                                GLV:RefreshGuide()
                            end)
                        end

                        frame:SetHeight(frameHeight - CONFIG.lineSpacing + 4)
                        frame:SetPoint("TOPLEFT", pinnedLastLine or pinnedChild, pinnedLastLine and "BOTTOMLEFT" or "TOPLEFT", 0, pinnedLastLine and CONFIG.spacing or 0)
                        pinnedLastLine = frame
                        pinnedTotalHeight = pinnedTotalHeight + frameHeight + math.abs(CONFIG.spacing)
                    end
                end
            end

            pinnedChild:SetHeight(math.max(1, pinnedTotalHeight))
        end
    end

    -- Adjust scroll frame position based on pinned section
    AdjustScrollFramePosition(pinnedTotalHeight)

    for idx, step in ipairs(displaySteps) do
        -- Skip ongoing active steps that are NOT completed (they're shown in pinned section)
        local skipThisStep = false
        if OngoingStepsManager:IsActive(idx) then
            local origIdx = displayIndexToOriginalIndex[idx]
            if not (origIdx and stepState[origIdx]) then
                skipThisStep = true
            end
        end

        if not skipThisStep then
        local frameName = scrollChild:GetName().."Step"..guideId.."_"..idx
        local frame = CreateFrame("Frame", frameName, scrollChild)

        -- Ensure parent is set (CreateFrame reuses existing frames without changing parent)
        frame:SetParent(scrollChild)

        -- Track that this frame was created in this refresh
        GLV.CurrentFrameIndices[idx] = true

        -- Clean up old children if frame is being reused (FontStrings, textures, etc.)
        local regions = {frame:GetRegions()}
        for _, region in pairs(regions) do
            if region and region.Hide then
                region:Hide()
            end
        end
        local children = {frame:GetChildren()}
        for _, child in pairs(children) do
            if child and child.Hide then
                child:Hide()
                child:SetParent(nil)
            end
        end

        frame:Show()
        frame:SetWidth(CONFIG.totalWidth)
        frame:SetBackdrop(CONFIG.backdrop)
        if frame.EnableMouse then frame:EnableMouse(true) end

        -- Set color: YELLOW for active step, even/odd for others
        local color
        if idx == activeStep then
            color = CONFIG.colors.active
        else
            color = isEven(idx) and CONFIG.colors.even or CONFIG.colors.odd
        end
        frame:SetBackdropColor(unpack(color))

        local yOffset = -2
        local frameHeight = 0
        local lineStrings = {}

        for li, line in ipairs(step.lines) do
            local hasIcon = type(line.icon) == "string" and line.icon ~= "" and line.icon ~= nil
            local reservedIconWidth = CONFIG.iconWidth + 4
            local availableWidth = CONFIG.totalWidth - CONFIG.checkboxSize - 16 - reservedIconWidth

            local textFrame = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
            applyTextScale(textFrame)

            local wrappedText, lineCount, textHeight = wrapText(line.text or "", availableWidth)
            textFrame:SetText(wrappedText)
            textFrame:SetJustifyH("LEFT")
            textFrame:SetJustifyV("TOP")
            textFrame:SetWidth(availableWidth)
            local scaledLineHeight = getScaledFontLineHeight()
            local usedHeight = (lineCount * scaledLineHeight)

            -- Reserve extra height for XP progress (only for ongoing steps, active step shows in navigation)
            if line.experienceRequirement and idx ~= activeStep then
                usedHeight = usedHeight + (scaledLineHeight * 2)
            end

            textFrame:SetHeight(usedHeight)

            -- Track [XP] steps for progress display (only for ongoing steps)
            if line.experienceRequirement then
                table.insert(GLV.XPProgressTrackers, {
                    fontString = textFrame,
                    experienceRequirement = line.experienceRequirement,
                    originalText = wrappedText,
                    originalHeight = usedHeight,
                    stepIndex = idx
                })
            end

            local offsetX = reservedIconWidth

            if hasIcon then
                -- Create the clickable icon at scrollChild level to avoid any parent capturing issues
                local iconButton = CreateFrame("Button", nil, scrollChild)
                iconButton:SetWidth(CONFIG.iconWidth)
                iconButton:SetHeight(CONFIG.iconWidth)
                -- Position icon at consistent height relative to text
                local iconYOffset = CONFIG.iconYOffset
                iconButton:SetPoint("TOPRIGHT", textFrame, "TOPLEFT", -2, iconYOffset)
                iconButton:EnableMouse(true)
                if iconButton.RegisterForClicks then
                    iconButton:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
                end
                iconButton:SetFrameStrata("TOOLTIP")
                if iconButton.SetFrameLevel then
                    iconButton:SetFrameLevel(100)
                end
                iconButton:Show()
                if iconButton.Raise then iconButton:Raise() end
                if iconButton.Enable then iconButton:Enable() end

                local icon = iconButton:CreateTexture(nil, "OVERLAY")
                icon:SetAllPoints(iconButton)

                -- Try to get fresh texture for items (in case it was cached since parsing)
                local textureToUse = line.icon
                if line.useItemId then
                    local itemId = tonumber(line.useItemId)
                    if itemId then
                        local _, _, _, _, _, _, _, _, freshTexture = GetItemInfo(itemId)
                        if freshTexture then
                            textureToUse = freshTexture
                        end
                    end
                end
                icon:SetTexture(textureToUse)

                -- Optional: click action provided by parser
                if line.useItemId then
                    local itemIdForClick = line.useItemId
                    -- Handle item usage when icon is clicked, calls useItemById with the stored item ID
                    local function handleUse()
                        useItemById(itemIdForClick)
                    end
                    iconButton:SetScript("OnClick", handleUse)
                    iconButton:SetScript("OnMouseUp", handleUse)
                    if iconButton.SetHighlightTexture then
                        iconButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
                    end
                    if iconButton.SetHitRectInsets then
                        iconButton:SetHitRectInsets(-2, -2, -2, -2)
                    end
                    iconButton:SetScript("OnEnter", function()
                        GameTooltip:SetOwner(iconButton, "ANCHOR_RIGHT")
                        GameTooltip:SetText("Use item")
                        GameTooltip:Show()
                    end)
                    iconButton:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                end
            end


            -- Position text with consistent offset for good alignment
            textFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 2 + offsetX, yOffset)
            table.insert(lineStrings, textFrame)
            yOffset = yOffset - (usedHeight + (line.isOC and CONFIG.ocSpacing or CONFIG.lineSpacing))
            frameHeight = frameHeight + (usedHeight + (line.isOC and CONFIG.ocSpacing or CONFIG.lineSpacing))
        end

        -- checkbox
        if step.hasCheckbox then
            local check = createCheckbox(frame)
            local origIndexForDisplay = displayIndexToOriginalIndex[idx]
            check:SetChecked(origIndexForDisplay and (stepState[origIndexForDisplay] == true) or false)
            local currentIndex = idx
            check:SetScript("OnClick", function()
                local checked = not not check:GetChecked()
                if not currentIndex then return end
                
                -- Update step state
                local origIdx = displayIndexToOriginalIndex[currentIndex]
                if origIdx then
                    stepState[origIdx] = checked
                end
                GLV.Settings:SetOption(stepState, {"Guide","Guides", currentGuideId, "StepState"})
                
                -- Handle next guide loading if needed
                if checked then
                    handleNextGuideLoad(guide, currentIndex, displaySteps)
                end
                
                -- Calculate new active step
                local currentActiveStep = GLV.Settings:GetOption({"Guide", "Guides", currentGuideId, "CurrentStep"}) or 0
                local newActiveStep = calculateNewActiveStep(checked, currentIndex, currentActiveStep, displaySteps, displayIndexToOriginalIndex, stepState)
                
                -- Update step if changed
                if newActiveStep ~= currentActiveStep then
                    GLV.Settings:SetOption(newActiveStep, {"Guide", "Guides", currentGuideId, "CurrentStep"})

                    -- Update Guide Navigation waypoint
                    if newActiveStep > 0 and GLV.GuideNavigation then
                        local activeStepData = displaySteps[newActiveStep]
                        if activeStepData then
                            GLV.GuideNavigation:OnStepChanged(activeStepData)
                        end
                    end
                end

                -- Rebuild UI to update highlight and scroll (RefreshGuide handles everything)
                GLV:RefreshGuide()
            end)
        end

        frame:SetHeight(frameHeight - CONFIG.lineSpacing + 4)
        frame:SetPoint("TOPLEFT", lastLine or scrollChild, lastLine and "BOTTOMLEFT" or "TOPLEFT", 0, lastLine and CONFIG.spacing or 0)
        lastLine = frame
        totalHeight = totalHeight + frameHeight + math.abs(CONFIG.spacing)
        end -- end of if not skipThisStep
    end

    scrollChild:SetHeight(math.max(1, totalHeight))

    -- activeStep already calculated before frame creation, just update counter
    GLV_MainLoadedGuideCounter:SetText("("..tostring(activeStep).."/"..tostring(totalSteps)..")")
    
    -- Set initial Guide Navigation waypoint
    if activeStep > 0 and GLV.GuideNavigation then
        local activeStepData = displaySteps[activeStep]
        if activeStepData then
            GLV.GuideNavigation:OnStepChanged(activeStepData)
        end
    end
    
    -- Scroll to show the active step at the top
    if activeStep > 0 then
        GLV.Ace:ScheduleEvent(function()
            if GLV_MainScrollFrame and scrollChild then
                -- Force scroll child height update
                scrollChild:SetHeight(math.max(1, scrollChild:GetHeight()))
                GLV_MainScrollFrame:UpdateScrollChildRect()
                -- Small delay to let the scroll range update
                GLV.Ace:ScheduleEvent(function()
                    scrollToStep(activeStep, scrollChild, guideId, CONFIG.spacing)
                    -- Update XP progress display after scroll (only affects active step)
                    GLV:UpdateXPProgressDisplay()
                    GLV.RefreshGuidePending = false
                end, 0.05)
            end
        end, 0.15)
    else
        GLV.Ace:ScheduleEvent(function()
            if GLV_MainScrollFrame then
                GLV_MainScrollFrame:UpdateScrollChildRect()
                GLV_MainScrollFrame:SetVerticalScroll(0)
            end
            -- Update XP progress display
            GLV:UpdateXPProgressDisplay()
            GLV.RefreshGuidePending = false
        end, 0.15)
    end
     
    createTitle(guide)

    if callback then callback() end
end

-- Expose updateStepColors globally for use by QuestTracker
GLV.updateStepColors = updateStepColors
