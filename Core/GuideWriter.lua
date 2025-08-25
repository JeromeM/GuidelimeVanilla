--[[
Guidelime Vanilla
Author: Grommey
Version: 0.2

Description:
Guide Writer rework.
Display steps in a single frame with multiple lines, icon beside line, checkbox at right.
]]--
local _G = _G or getfenv()
local GLV = LibStub('AceAddon-3.0'):GetAddon('GuidelimeVanilla')
local Writer = GLV:NewModule("Writer")

local CONFIG = {
    spacing = -4,
    lineHeight = 14,
    checkboxSize = 24,
    textOffset = 30,
    iconWidth = 13,
    totalWidth = 400,
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
        active = {0.8,0.8,0.2,0.9}
    },
    titleFrame = _G["GLV_MainLoadedGuideTitle"]
}


--[[ INITIALIZATION FUNCTIONS ]]--

function Writer:OnInitialize()
    DEFAULT_CHAT_FRAME:AddMessage("Writer initialized")
    self.settings = GLV.db.char or {}
end


--[[ UI CREATION FUNCTIONS ]]--

-- Create and set the guide title
local function createTitle(guide)
    local titleFrame = _G["GLV_MainLoadedGuideTitle"]
    if not titleFrame then return end
    titleFrame:SetText(guide.name .. " (" .. guide.minLevel .. "-" .. guide.maxLevel .. ")")
end

-- Wrap text to fit within specified width
local function wrapText(inputText, maxWidth, font)
    local wrappedText = ""
    local lineCount = 0
    local segments = {}
    inputText = inputText or ""
    for segment in string.gfind(inputText, "([^\n]*)\n?") do
        if segment and segment ~= "" then table.insert(segments, segment) end
    end

    local tempText = UIParent:CreateFontString(nil,"OVERLAY",font or "GameFontNormalSmall")
    for i, segment in ipairs(segments) do
        local currentLine = ""
        local words = {}
        for word in string.gfind(segment, "[%S]+") do table.insert(words, word) end
        for j, word in ipairs(words) do
            local testLine = currentLine == "" and word or currentLine.." "..word
            tempText:SetText(testLine)
            if tempText:GetStringWidth() <= maxWidth then
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
    local textHeight = tempText:GetHeight() * lineCount
    tempText:Hide()
    tempText:SetParent(nil)
    return wrappedText, lineCount, textHeight
end

-- Create checkbox for step completion
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


--[[ MAIN GUIDE FUNCTIONS ]]--

-- Public: rebuild the guide UI using the current guide and main scroll child
function Writer:RefreshGuide()
    local guide = GLV.CurrentGuide
    if not guide then return end
    local scrollChild = _G["GLV_MainScrollFrameScrollChild"]
    local mainScrollFrame = _G["GLV_MainScrollFrame"]
    if not scrollChild and mainScrollFrame and mainScrollFrame.GetScrollChild then
        scrollChild = mainScrollFrame:GetScrollChild()
    end
    if not scrollChild then return end
    self:CreateGuideSteps(scrollChild, guide, guide.id)
end

-- Create and display all guide steps in the UI
function Writer:CreateGuideSteps(scrollChild, guide, guideId)
    if not scrollChild or not scrollChild.GetNumChildren then return end
    if not guide or not guide.steps then return end

    local navigation = GLV:GetModule("Navigation")

    -- Cleanup previous children
    local children = {scrollChild:GetChildren()}
    for i, child in pairs(children) do
        if child and type(child)=="table" then
            child:Hide()
            child:SetParent(nil)
        end
    end

    local lastLine = nil
    local totalHeight = 0
    -- Use the passed guideId instead of guide.id
    local currentGuideId = guideId or guide.id or "Unknown"
    local stepState = self.settings.Guide.Guides[currentGuideId].StepState or {} 
    local displaySteps = {}
    -- expose current guide to other modules (e.g., quest tracker)
    GLV.CurrentGuide = guide
    local originalIndexToDisplayIndex = {}
    local displayIndexToOriginalIndex = {}

    -- regroup steps: OC + main line
    local i=1
    while i <= safe_tablelen(guide.steps) do
        local stepFrameData = {lines={}, icon=nil, hasCheckbox=false, questTags={}}
        -- collect [OC] lines
        while i <= safe_tablelen(guide.steps) and guide.steps[i] and (guide.steps[i].emptyLine or guide.steps[i].complete_with_next) do
            table.insert(stepFrameData.lines, {
                text = guide.steps[i].text,
                isOC = guide.steps[i].emptyLine or guide.steps[i].complete_with_next,
                icon = guide.steps[i].icon,
                useItemId = guide.steps[i].useItemId,
                questId = guide.steps[i].questId,
                coords = guide.steps[i].coords,
                stepType = guide.steps[i].stepType,
                questTags = guide.steps[i].questTags,
                experienceRequirement = guide.steps[i].experienceRequirement
            })
            if guide.steps[i].icon and not stepFrameData.icon then
                stepFrameData.icon = guide.steps[i].icon
            end
            -- Collect questTags from this OC line
            if guide.steps[i].questTags then
                for _, tag in ipairs(guide.steps[i].questTags) do
                    table.insert(stepFrameData.questTags, tag)
                end
            end
            
            -- Check if this OC line has XP requirements (for checkbox)
            if guide.steps[i].experienceRequirement then
                stepFrameData.hasCheckbox = true
            end
            i=i+1
        end
        if i <= safe_tablelen(guide.steps) and guide.steps[i] then
            table.insert(stepFrameData.lines, {text=guide.steps[i].text, isOC=false, icon=guide.steps[i].icon, useItemId=guide.steps[i].useItemId, questId=guide.steps[i].questId, coords=guide.steps[i].coords, stepType=guide.steps[i].stepType, questTags=guide.steps[i].questTags, experienceRequirement=guide.steps[i].experienceRequirement})

            stepFrameData.hasCheckbox = true
            
            -- Check if this line has XP requirements (for checkbox)
            if guide.steps[i].experienceRequirement then
                stepFrameData.hasCheckbox = true
            end
            if guide.steps[i].icon and not stepFrameData.icon then
                stepFrameData.icon = guide.steps[i].icon
            end
            -- Collect questTags from the main line
            if guide.steps[i].questTags then
                for _, tag in ipairs(guide.steps[i].questTags) do
                    table.insert(stepFrameData.questTags, tag)
                end

            end
            -- map original index (main line) to display index pre-insertion
            local displayIndex = safe_tablelen(displaySteps) + 1
            originalIndexToDisplayIndex[i] = displayIndex
            displayIndexToOriginalIndex[displayIndex] = i
            i=i+1
        end
        table.insert(displaySteps, stepFrameData)
    end

    -- Get the current step for this specific guide
    local counterFrame = _G["GLV_MainLoadedGuideCounter"]
    if not counterFrame then return end
    local currentStep = self.settings.Guide.Guides[currentGuideId].CurrentStep or 0
    counterFrame:SetText("("..currentStep.."/"..safe_tablelen(displaySteps)..")")

    -- publish mapping and display metadata for other modules
    GLV.CurrentStepIndexMap = originalIndexToDisplayIndex
    GLV.CurrentDisplayStepsCount = safe_tablelen(displaySteps)
    GLV.CurrentDisplaySteps = displaySteps  -- Expose the grouped steps for TomTom integration
    GLV.CurrentDisplayHasCheckbox = {}
    for di, st in ipairs(displaySteps) do
        GLV.CurrentDisplayHasCheckbox[di] = st.hasCheckbox and true or false
    end
    GLV.CurrentDisplayToOriginal = displayIndexToOriginalIndex

    -- create frames
    for idx, step in ipairs(displaySteps) do
        local frame = CreateFrame("Frame", scrollChild:GetName().."Step"..idx, scrollChild)
        frame:SetWidth(CONFIG.totalWidth)
        frame:SetBackdrop(CONFIG.backdrop)
        -- Keep frame mouse enabled so children can receive events normally
        if frame.EnableMouse then frame:EnableMouse(true) end

        local color = isEven(idx) and CONFIG.colors.even or CONFIG.colors.odd
        frame:SetBackdropColor(unpack(color))

        local yOffset = -2
        local frameHeight = 0
        local lineStrings = {}

        -- create lines inside frame
        for li, line in ipairs(step.lines) do
            local hasIcon = type(line.icon) == "string" and line.icon ~= "" and line.icon ~= nil
            local reservedIconWidth = CONFIG.iconWidth + 4
            local availableWidth = CONFIG.totalWidth - CONFIG.checkboxSize - 16 - reservedIconWidth

            local textFrame = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
            
            local wrappedText, lineCount, textHeight = wrapText(line.text or "", availableWidth)
            textFrame:SetText(wrappedText)
            textFrame:SetJustifyH("LEFT")
            textFrame:SetJustifyV("TOP")
            textFrame:SetWidth(availableWidth)
            -- stable text height using a fixed font line height multiplier for consistency
            local usedHeight = (lineCount * CONFIG.fontLineHeight)
            textFrame:SetHeight(usedHeight)

            local offsetX = reservedIconWidth

            -- icon for this line (only if line.icon is provided)
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
                icon:SetTexture(line.icon)

                -- Optional: click action provided by parser
                if line.useItemId then
                    local itemIdForClick = line.useItemId
                    local function handleUse()
                        useItemById(itemIdForClick)
                    end
                    iconButton:SetScript("OnClick", handleUse)
                    iconButton:SetScript("OnMouseUp", handleUse)
                    -- Improve UX: highlight and slightly larger hitbox
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
                local origIdx = displayIndexToOriginalIndex[currentIndex]
                if origIdx then
                    stepState[origIdx] = checked
                end
                self.settings.Guide.Guides[currentGuideId].StepState = stepState
                -- recompute activeStep as first unchecked
                local totalSteps = table.getn(displaySteps)
                local newActiveStep = 0
                for i2 = 1, totalSteps do
                    if displaySteps[i2] and displaySteps[i2].hasCheckbox then
                        local orig = displayIndexToOriginalIndex[i2]
                        if orig and not stepState[orig] then
                            newActiveStep = i2
                            break
                        end
                    end
                end
                self.settings.Guide.Guides[currentGuideId].CurrentStep = newActiveStep
                counterFrame:SetText("("..tostring(newActiveStep).."/"..tostring(totalSteps)..")")
                -- visually highlight the new active step and reset others
                for i2 = 1, totalSteps do
                    local f = getglobal(scrollChild:GetName().."Step"..i2)
                    if f and f.SetBackdropColor then
                        local col = (i2 == newActiveStep) and CONFIG.colors.active or (isEven(i2) and CONFIG.colors.even or CONFIG.colors.odd)
                        f:SetBackdropColor(unpack(col))
                    end
                end
                
                -- Also update the global CurrentStep for other modules
                self.settings.Guide.Guides[currentGuideId].CurrentStep = newActiveStep
                
                -- Update TomTom waypoint for the new active step
                if newActiveStep > 0 then
                    local activeStepData = displaySteps[newActiveStep]
                    if activeStepData then
                        navigation:OnStepChanged(activeStepData)
                    end
                end
                
                -- Scroll to show the new active step at the top (only when checking a box)
                if checked and newActiveStep > 0 and mainScrollFrame then
                    -- Calculate the exact position: sum of all previous step heights + spacing
                    local targetScroll = 0
                    for i = 1, newActiveStep - 1 do
                        local stepFrame = getglobal(scrollChild:GetName().."Step"..i)
                        if stepFrame and stepFrame.GetHeight then
                            targetScroll = targetScroll + stepFrame:GetHeight()
                        end
                    end
                    -- Add spacing between frames (spacing * (number of steps - 1))
                    if newActiveStep > 1 then
                        targetScroll = targetScroll + (math.abs(CONFIG.spacing) * (newActiveStep - 1))
                    end
                    -- Ensure we don't scroll below 0
                    targetScroll = math.max(0, targetScroll)
                    -- Adjust scroll to leave some space above for manual scrolling
                    local maxScroll = mainScrollFrame:GetVerticalScrollRange()
                    if maxScroll and maxScroll > 0 then
                        targetScroll = math.min(targetScroll, maxScroll)
                    end
                    mainScrollFrame:SetVerticalScroll(targetScroll)
                end
                 
             end)
        end

        frame:SetHeight(frameHeight + 4)
        frame:SetPoint("TOPLEFT", lastLine or scrollChild, lastLine and "BOTTOMLEFT" or "TOPLEFT", 0, lastLine and CONFIG.spacing or 0)
        lastLine = frame
        totalHeight = totalHeight + frameHeight + math.abs(CONFIG.spacing)
    end

    scrollChild:SetHeight(math.max(1, totalHeight))
    -- Use the saved CurrentStep for this guide, or calculate first unchecked if none saved
    local totalSteps = table.getn(displaySteps)
    local activeStep = self.settings.Guide.Guides[currentGuideId].CurrentStep or 0
    
    -- If no saved step, find first unchecked
    if activeStep == 0 then
        for i2 = 1, totalSteps do
            if displaySteps[i2] and displaySteps[i2].hasCheckbox then
                local orig = displayIndexToOriginalIndex[i2]
                if orig and not stepState[orig] then
                    activeStep = i2
                    break
                end
            end
        end
        -- Save the calculated step
        if activeStep > 0 then
            self.settings.Guide.Guides[currentGuideId].CurrentStep = activeStep
        end
    end
    
    counterFrame:SetText("("..tostring(activeStep).."/"..tostring(totalSteps)..")")
    
    -- highlight active frame at initial render and normalize others
    for i2 = 1, totalSteps do
        local f = getglobal(scrollChild:GetName().."Step"..i2)
        if f and f.SetBackdropColor then
            local col = (i2 == activeStep) and CONFIG.colors.active or (isEven(i2) and CONFIG.colors.even or CONFIG.colors.odd)
            f:SetBackdropColor(unpack(col))
        end
    end
    
    -- Set initial TomTom waypoint
    if activeStep > 0 then
        local activeStepData = displaySteps[activeStep]
        if activeStepData then
            navigation:OnStepChanged(activeStepData)
        end
    end
    
    -- Scroll to show the active step at the top (initial load)
    if activeStep > 0 and mainScrollFrame then
        -- Wait 1 second for UI to stabilize, then scroll to active step
        Writer:ScheduleTimer(function()
            if mainScrollFrame then
                -- Same calculation as checkbox click: sum of all previous step heights + spacing
                local targetScroll = 0
                for i = 1, activeStep - 1 do
                    local stepFrame = getglobal(scrollChild:GetName().."Step"..i)
                    if stepFrame and stepFrame.GetHeight then
                        targetScroll = targetScroll + stepFrame:GetHeight()
                    end
                end
                -- Add spacing between frames (spacing * (number of steps - 1))
                if activeStep > 1 then
                    targetScroll = targetScroll + (math.abs(CONFIG.spacing) * (activeStep - 1))
                end
                -- Ensure we don't scroll below 0
                targetScroll = math.max(0, targetScroll)
                -- Adjust scroll to leave some space above for manual scrolling
                local maxScroll = mainScrollFrame:GetVerticalScrollRange()
                if maxScroll and maxScroll > 0 then
                    targetScroll = math.min(targetScroll, maxScroll)
                end
                mainScrollFrame:SetVerticalScroll(targetScroll)
            end
        end, 1)
    end
     
     createTitle(guide)
    
    -- Initialize TomTom integration AFTER the guide is completely displayed and parsed
    Writer:ScheduleTimer(function()
        navigation:Init()
    end, 1.0)
end
