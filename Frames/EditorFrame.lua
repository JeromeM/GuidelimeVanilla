--[[
Guidelime Vanilla

Author: Grommey

Description:
Guide Editor UI - 100% Lua frame creation.
Window, EditBox, preview panel, toolbar, popups, save/load/import.
]]--
local GLV = LibStub("GuidelimeVanilla")

-- Local references
local Editor = GLV.GuideEditor
local FRAME_WIDTH = 1000
local FRAME_HEIGHT = 570
local TOOLBAR_HEIGHT = 38
local METADATA_HEIGHT = 122
local BOTTOM_BAR_HEIGHT = 35

-- Reusable popup frame reference
local tagPopup = nil

-- Spell name cache for LE search (built lazily via GetSpellRec)
local spellNameCache = nil
local function BuildSpellCache()
    if spellNameCache then return end
    if not GetSpellRec then
        spellNameCache = {}
        return
    end
    spellNameCache = {}
    -- Scan spell IDs (vanilla range is roughly 1-31000)
    for id = 1, 31000 do
        local rec = GetSpellRec(id)
        if rec and rec.name and rec.name ~= "" then
            table.insert(spellNameCache, {id = id, name = rec.name, rank = rec.rank or ""})
        end
    end
end

-- Delete confirmation dialog
StaticPopupDialogs["GLV_DELETE_GUIDE"] = {
    text = "Delete guide \"%s\"?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        if GLV_EditorFrame and GLV_EditorFrame.currentGuideName then
            Editor:DeleteGuide(GLV_EditorFrame.currentGuideName)
            GLV_EditorFrame.currentGuideName = nil
            GLV_Editor_NewGuide()
            GLV_Editor_RefreshSavedDropdown()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}


-- ============================================================================
-- MAIN FRAME CREATION
-- ============================================================================

local function CreateEditorFrame()
    local frame = getglobal("GLV_EditorFrame")
    if frame then
        -- /reload: frame persists but Lua state resets. Hide old children.
        local children = { frame:GetChildren() }
        for _, child in ipairs(children) do
            child:Hide()
        end
    else
        frame = CreateFrame("Frame", "GLV_EditorFrame", UIParent)
        frame:SetWidth(FRAME_WIDTH)
        frame:SetHeight(FRAME_HEIGHT)
        frame:SetPoint("CENTER", 0, 0)
        frame:SetFrameStrata("HIGH")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
    end

    -- (Re-)apply scripts (Lua functions don't survive /reload)
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    -- ESC to close (UISpecialFrames resets on /reload)
    table.insert(UISpecialFrames, "GLV_EditorFrame")

    -- Title
    local title = frame:CreateFontString("GLV_EditorFrameTitle", "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -8)
    title:SetText("|cFF6B8BD4Guide Editor|r")

    -- Close button
    local closeBtn = CreateFrame("Button", "GLV_EditorFrameClose", frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Track current guide
    frame.currentGuideName = nil

    frame:Hide()
    return frame
end


-- ============================================================================
-- METADATA FIELDS
-- ============================================================================

-- Race names for the race checkboxes
local EDITOR_RACES = {"Human", "Dwarf", "Night Elf", "Gnome", "High Elf", "Orc", "Undead", "Tauren", "Troll", "Goblin"}

-- Helper to create a faction dropdown callback (avoids Lua 5.0 closure bug)
local function createFactionCallback(dropdown, value, label)
    return function()
        UIDropDownMenu_SetSelectedValue(dropdown, value)
        UIDropDownMenu_SetText(label, dropdown)
    end
end

-- Group guides by level range for submenu (10-level buckets)
local function groupImportGuidesByRange(guides)
    local groups = {}
    local groupMap = {}
    for _, guide in ipairs(guides) do
        local minLvl = tonumber(guide.minLevel) or 0
        local rangeStart = minLvl <= 10 and 1 or (math.floor((minLvl - 1) / 10) * 10 + 1)
        local rangeEnd = rangeStart + 9
        local rangeKey = rangeStart .. "-" .. rangeEnd
        if not groupMap[rangeKey] then
            local grp = { key = rangeKey, label = "Levels " .. rangeKey, guides = {} }
            table.insert(groups, grp)
            groupMap[rangeKey] = table.getn(groups)
        end
        table.insert(groups[groupMap[rangeKey]].guides, guide)
    end
    return groups
end

local function CreateMetadataFields(parent)
    local SECTION_BACKDROP = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    }
    local TITLE_COLOR = {0.42, 0.55, 0.83}
    local LABEL_COLOR = {0.7, 0.7, 0.7}

    -- Helper: create a section panel with background and title
    local function MakeSection(name, title, x, y, w, h)
        local f = CreateFrame("Frame", name, parent)
        f:SetWidth(w)
        f:SetHeight(h)
        f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        f:SetBackdrop(SECTION_BACKDROP)
        f:SetBackdropColor(0.1, 0.1, 0.15, 0.6)
        f:SetBackdropBorderColor(0.3, 0.3, 0.4, 0.5)
        local t = f:CreateFontString(nil, "OVERLAY")
        t:SetFont("Fonts\\FRIZQT__.TTF", 10)
        t:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -5)
        t:SetText(title)
        t:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
        return f
    end

    -- Helper: create a label
    local function MakeLabel(parentFrame, text, x, y)
        local fs = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", x, y)
        fs:SetText(text)
        fs:SetTextColor(LABEL_COLOR[1], LABEL_COLOR[2], LABEL_COLOR[3])
        return fs
    end

    -- Helper: create an editbox
    local function MakeEditBox(name, parentFrame, width, maxLetters)
        local box = CreateFrame("EditBox", name, parentFrame, "InputBoxTemplate")
        box:SetWidth(width)
        box:SetHeight(18)
        box:SetAutoFocus(false)
        if maxLetters then box:SetMaxLetters(maxLetters) end
        box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        box:SetScript("OnEnterPressed", function() this:ClearFocus() end)
        return box
    end

    local PADDING = 10
    local SECTION_GAP = 4
    local TOP_Y = -28
    local SEC1_H = 64       -- Guide Info (2 rows: Name+Lvl, Desc)
    local SEC2_H = SEC1_H   -- Faction & Races (same height)
    local SEC3_H = 52       -- Next Guide (title + field + dropdown)
    local SEC_W_LEFT = 420  -- Guide Info (narrower: name, lvl, desc)
    local SEC_W_RIGHT = FRAME_WIDTH - SEC_W_LEFT - PADDING * 2 - SECTION_GAP

    -- ══════════════════════════════════════════════════════════════════
    -- Section 1: Guide Info (Name, Levels, Description)
    -- ══════════════════════════════════════════════════════════════════
    local sec1 = MakeSection("GLV_EditorSec1", "Guide Info", PADDING, TOP_Y, SEC_W_LEFT, SEC1_H)

    local FIELD_X = 50  -- align all fields to same left edge (right of labels)

    -- Row 1: Name + Levels
    local nameLabel = MakeLabel(sec1, "Name:", 8, -22)
    local nameBox = MakeEditBox("GLV_EditorNameBox", sec1, 200)
    nameBox:SetPoint("TOPLEFT", sec1, "TOPLEFT", FIELD_X, -22 + 4)

    local lvlLabel = MakeLabel(sec1, "Lvl:", 280, -22)
    local minBox = MakeEditBox("GLV_EditorMinLevelBox", sec1, 25, 2)
    minBox:SetPoint("LEFT", lvlLabel, "RIGHT", 3, 0)

    local dashFS = sec1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dashFS:SetPoint("LEFT", minBox, "RIGHT", 2, 0)
    dashFS:SetText("-")
    dashFS:SetTextColor(LABEL_COLOR[1], LABEL_COLOR[2], LABEL_COLOR[3])

    local maxBox = MakeEditBox("GLV_EditorMaxLevelBox", sec1, 25, 2)
    maxBox:SetPoint("LEFT", dashFS, "RIGHT", 2, 0)

    -- Row 2: Description (full width of section, +4px gap)
    local descLabel = MakeLabel(sec1, "Desc:", 8, -44)
    local descBox = MakeEditBox("GLV_EditorDescBox", sec1, SEC_W_LEFT - FIELD_X - 14)
    descBox:SetPoint("TOPLEFT", sec1, "TOPLEFT", FIELD_X, -44 + 4)

    -- Tab order
    nameBox:SetScript("OnTabPressed", function() getglobal("GLV_EditorMinLevelBox"):SetFocus() end)
    minBox:SetScript("OnTabPressed", function() getglobal("GLV_EditorMaxLevelBox"):SetFocus() end)
    maxBox:SetScript("OnTabPressed", function() getglobal("GLV_EditorDescBox"):SetFocus() end)
    descBox:SetScript("OnTabPressed", function() getglobal("GLV_EditorNextGuideBox"):SetFocus() end)

    -- ══════════════════════════════════════════════════════════════════
    -- Section 2: Faction & Races
    -- ══════════════════════════════════════════════════════════════════
    local sec2 = MakeSection("GLV_EditorSec2", "Faction & Races", PADDING + SEC_W_LEFT + SECTION_GAP, TOP_Y, SEC_W_RIGHT, SEC2_H)

    -- Faction dropdown
    local factionDD = CreateFrame("Frame", "GLV_EditorFactionDropdown", sec2, "UIDropDownMenuTemplate")
    factionDD:SetPoint("TOPLEFT", sec2, "TOPLEFT", -8, -18)
    UIDropDownMenu_SetWidth(80, factionDD)
    UIDropDownMenu_Initialize(factionDD, function()
        local factions = {"Alliance", "Horde", ""}
        local labels = {"Alliance", "Horde", "Both"}
        for i = 1, 3 do
            local info = {}
            info.text = labels[i]
            info.value = factions[i]
            info.func = createFactionCallback(factionDD, factions[i], labels[i])
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(factionDD, "Alliance")
    UIDropDownMenu_SetText("Alliance", factionDD)

    -- Races (2 rows of 5, compact)
    local raceXStart = 118
    local raceSpacing = 72
    local racesPerRow = 5
    for idx, race in ipairs(EDITOR_RACES) do
        local row = math.floor((idx - 1) / racesPerRow)
        local col = math.mod(idx - 1, racesPerRow)
        local cbName = "GLV_EditorRace_" .. string.gsub(race, "%s", "")
        local cb = CreateFrame("CheckButton", cbName, sec2, "UICheckButtonTemplate")
        cb:SetWidth(16)
        cb:SetHeight(16)
        cb:SetPoint("TOPLEFT", sec2, "TOPLEFT", raceXStart + col * raceSpacing, -10 - row * 17)
        local cbText = getglobal(cbName .. "Text")
        if cbText then
            cbText:SetText(race)
            cbText:SetFont("Fonts\\FRIZQT__.TTF", 8)
            cbText:SetTextColor(0.8, 0.8, 0.8)
        end
    end

    -- ══════════════════════════════════════════════════════════════════
    -- Section 3: Next Guide (with dropdown listing all loaded guides)
    -- ══════════════════════════════════════════════════════════════════
    local SEC3_Y = TOP_Y - SEC1_H - SECTION_GAP
    local sec3 = MakeSection("GLV_EditorSec3", "Next Guide", PADDING, SEC3_Y, FRAME_WIDTH - PADDING * 2, SEC3_H)

    local nxBox = MakeEditBox("GLV_EditorNextGuideBox", sec3, 340)
    nxBox:SetPoint("TOPLEFT", sec3, "TOPLEFT", 10, -26)
    nxBox:SetScript("OnTabPressed", function() this:ClearFocus() end)

    -- Dropdown to pick from loaded guides (3-level: Pack > Levels > Guide)
    local nxDD = CreateFrame("Frame", "GLV_EditorNextGuideDropdown", sec3, "UIDropDownMenuTemplate")
    nxDD:SetPoint("LEFT", nxBox, "RIGHT", -4, -2)
    UIDropDownMenu_SetWidth(250, nxDD)
    UIDropDownMenu_SetText("Browse...", nxDD)

    -- Pre-compute packs and level groups for the NX dropdown
    local function buildNxPackData()
        local packs = Editor:GetImportableGuides()
        local packGroups = {}
        for _, pack in ipairs(packs) do
            packGroups[pack.name] = groupImportGuidesByRange(pack.guides)
        end
        return packs, packGroups
    end

    UIDropDownMenu_Initialize(nxDD, function(level)
        if not level then level = 1 end
        local nxPacks, nxPackGroups = buildNxPackData()

        if level == 1 then
            if table.getn(nxPacks) == 0 then
                local info = {}
                info.text = "No guides loaded"
                info.disabled = 1
                UIDropDownMenu_AddButton(info, 1)
                return
            end
            for _, pack in ipairs(nxPacks) do
                local info = {}
                info.text = pack.name .. " (" .. table.getn(pack.guides) .. ")"
                info.value = pack.name
                info.hasArrow = 1
                info.notCheckable = 1
                UIDropDownMenu_AddButton(info, 1)
            end

        elseif level == 2 then
            local selectedPack = UIDROPDOWNMENU_MENU_VALUE
            local _, nxPackGroups2 = buildNxPackData()
            local groups = nxPackGroups2[selectedPack]
            if not groups then return end

            local totalGuides = 0
            for _, grp in ipairs(groups) do
                totalGuides = totalGuides + table.getn(grp.guides)
            end

            if totalGuides <= 25 then
                -- Few guides: flat list
                for _, grp in ipairs(groups) do
                    for _, guide in ipairs(grp.guides) do
                        local min = guide.minLevel or "?"
                        local max = guide.maxLevel or "?"
                        local nxValue = min .. "-" .. max .. " " .. guide.name
                        local info = {}
                        info.text = guide.name .. " (" .. min .. "-" .. max .. ")"
                        info.value = nxValue
                        local capturedVal = nxValue
                        info.func = function()
                            local box = getglobal("GLV_EditorNextGuideBox")
                            if box then box:SetText(capturedVal) end
                            UIDropDownMenu_SetText(capturedVal, nxDD)
                        end
                        UIDropDownMenu_AddButton(info, 2)
                    end
                end
            else
                -- Many guides: level range submenus
                for _, grp in ipairs(groups) do
                    local info = {}
                    info.text = grp.label .. " (" .. table.getn(grp.guides) .. ")"
                    info.value = selectedPack .. "|" .. grp.key
                    info.hasArrow = 1
                    info.notCheckable = 1
                    UIDropDownMenu_AddButton(info, 2)
                end
            end

        elseif level == 3 then
            local menuValue = UIDROPDOWNMENU_MENU_VALUE or ""
            local _, _, packName, rangeKey = string.find(menuValue, "^(.+)|(.+)$")
            if not packName or not rangeKey then return end

            local _, nxPackGroups3 = buildNxPackData()
            local groups = nxPackGroups3[packName]
            if not groups then return end

            for _, grp in ipairs(groups) do
                if grp.key == rangeKey then
                    for _, guide in ipairs(grp.guides) do
                        local min = guide.minLevel or "?"
                        local max = guide.maxLevel or "?"
                        local nxValue = min .. "-" .. max .. " " .. guide.name
                        local info = {}
                        info.text = guide.name .. " (" .. min .. "-" .. max .. ")"
                        info.value = nxValue
                        local capturedVal = nxValue
                        info.func = function()
                            local box = getglobal("GLV_EditorNextGuideBox")
                            if box then box:SetText(capturedVal) end
                            UIDropDownMenu_SetText(capturedVal, nxDD)
                        end
                        UIDropDownMenu_AddButton(info, 3)
                    end
                    break
                end
            end
        end
    end)
end


-- ============================================================================
-- TOOLBAR (TAG BUTTONS)
-- ============================================================================

local function CreateToolbarButton(parent, name, label, xOff, yOff, width, onClick, tooltip)
    local btn = CreateFrame("Button", name, parent)
    btn:SetWidth(width or 32)
    btn:SetHeight(18)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.45, 0.12, 0.1, 0.95)
    btn:SetBackdropBorderColor(0.7, 0.25, 0.2, 0.9)

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", 9)
    fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
    fs:SetText(label)
    fs:SetTextColor(1, 0.85, 0.7)
    btn.label = fs

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function()
        this:SetBackdropColor(0.6, 0.18, 0.14, 1)
        this:SetBackdropBorderColor(0.9, 0.35, 0.25, 1)
        this.label:SetTextColor(1, 1, 0.9)
        if tooltip then
            GameTooltip:SetOwner(this, "ANCHOR_TOP")
            GameTooltip:AddLine(tooltip, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        this:SetBackdropColor(0.45, 0.12, 0.1, 0.95)
        this:SetBackdropBorderColor(0.7, 0.25, 0.2, 0.9)
        this.label:SetTextColor(1, 0.85, 0.7)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnMouseDown", function()
        this:SetBackdropColor(0.3, 0.08, 0.06, 1)
        this.label:SetPoint("CENTER", this, "CENTER", 1, -1)
    end)
    btn:SetScript("OnMouseUp", function()
        this.label:SetPoint("CENTER", this, "CENTER", 0, 0)
    end)
    return btn
end

-- Small vertical separator between button groups
local function CreateGroupSeparator(parent, xOff, yOff, height)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetWidth(1)
    sep:SetHeight(height or 16)
    sep:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff - 2)
    sep:SetTexture(0.4, 0.4, 0.4, 0.6)
    return sep
end

local function CreateToolbar(parent, yStart)
    local toolbar = CreateFrame("Frame", "GLV_EditorToolbar", parent)
    toolbar:SetWidth(FRAME_WIDTH - 20)
    toolbar:SetHeight(TOOLBAR_HEIGHT)
    toolbar:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yStart)

    -- Separator line above toolbar
    local sep = toolbar:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", toolbar, "TOPLEFT", 0, 2)
    sep:SetPoint("TOPRIGHT", toolbar, "TOPRIGHT", 0, 2)
    sep:SetTexture(0.3, 0.3, 0.3, 0.8)

    -- Helper: get editbox at click time (not at creation time)
    local function getEditBox()
        return getglobal("GLV_EditorEditBox")
    end

    local GAP = 2       -- space between buttons
    local SEP_GAP = 7   -- space around group separators
    local rowY = -2
    local x = 2

    -- +STEP first
    CreateToolbarButton(toolbar, "GLV_EditorBtn_Step", "+STEP", x, rowY, 46, function()
        Editor:InsertTag(getEditBox(), "\n ")
    end, "Insert new step (empty line)")
    x = x + 46 + GAP

    x = x + SEP_GAP - GAP
    CreateGroupSeparator(toolbar, x, rowY, 16)
    x = x + SEP_GAP

    -- Group: Quests
    local questTags = {
        {"QA", true, 28, "Accept Quest"},
        {"QC", true, 28, "Complete Quest"},
        {"QT", true, 28, "Turn in Quest"},
    }
    for _, def in ipairs(questTags) do
        local label, action, w, tip = def[1], def[2], def[3], def[4]
        CreateToolbarButton(toolbar, "GLV_EditorBtn_" .. label, label, x, rowY, w, function()
            GLV_Editor_ShowTagPopup(label)
        end, tip)
        x = x + w + GAP
    end

    x = x + SEP_GAP - GAP
    CreateGroupSeparator(toolbar, x, rowY, 16)
    x = x + SEP_GAP

    -- Group: Navigation
    CreateToolbarButton(toolbar, "GLV_EditorBtn_G:Pos", "G:Pos", x, rowY, 38, function()
        local tag, err = Editor:GetPlayerPositionTag()
        if tag then
            Editor:InsertTag(getEditBox(), tag .. " ")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Editor]|r " .. (err or "Unknown error"))
        end
    end, "Insert current position [G x,y Zone]")
    x = x + 38 + GAP
    CreateToolbarButton(toolbar, "GLV_EditorBtn_TAR", "TAR", x, rowY, 32, function()
        GLV_Editor_ShowTagPopup("TAR")
    end, "Target NPC (search by name)")
    x = x + 32 + GAP

    x = x + SEP_GAP - GAP
    CreateGroupSeparator(toolbar, x, rowY, 16)
    x = x + SEP_GAP

    -- Group: Items
    local itemTags = {
        {"CI", true, 24, "Collect Item (auto-completes)"},
        {"UI", true, 24, "Use Item"},
    }
    for _, def in ipairs(itemTags) do
        local label, action, w, tip = def[1], def[2], def[3], def[4]
        CreateToolbarButton(toolbar, "GLV_EditorBtn_" .. label, label, x, rowY, w, function()
            GLV_Editor_ShowTagPopup(label)
        end, tip)
        x = x + w + GAP
    end

    x = x + SEP_GAP - GAP
    CreateGroupSeparator(toolbar, x, rowY, 16)
    x = x + SEP_GAP

    -- Group: Travel
    local travelTags = {
        {"H", true,  22, "Use Hearthstone"},
        {"S", true,  22, "Bind Hearthstone"},
        {"P", true,  22, "Get Flight Path"},
        {"F", "[F]", 22, "Take Flight"},
    }
    for _, def in ipairs(travelTags) do
        local label, action, w, tip = def[1], def[2], def[3], def[4]
        local callback
        if action == true then
            callback = function() GLV_Editor_ShowTagPopup(label) end
        else
            callback = function() Editor:InsertTag(getEditBox(), action .. " ") end
        end
        CreateToolbarButton(toolbar, "GLV_EditorBtn_" .. label, label, x, rowY, w, callback, tip)
        x = x + w + GAP
    end

    x = x + SEP_GAP - GAP
    CreateGroupSeparator(toolbar, x, rowY, 16)
    x = x + SEP_GAP

    -- Group: Training
    local trainTags = {
        {"T",  "[T]", 22, "Train at Trainer"},
        {"LE", true,  24, "Learn Spell (search by name)"},
        {"SK", true,  24, "Skill Requirement"},
    }
    for _, def in ipairs(trainTags) do
        local label, action, w, tip = def[1], def[2], def[3], def[4]
        local callback
        if action == true then
            callback = function() GLV_Editor_ShowTagPopup(label) end
        else
            callback = function() Editor:InsertTag(getEditBox(), action .. " ") end
        end
        CreateToolbarButton(toolbar, "GLV_EditorBtn_" .. label, label, x, rowY, w, callback, tip)
        x = x + w + GAP
    end

    x = x + SEP_GAP - GAP
    CreateGroupSeparator(toolbar, x, rowY, 16)
    x = x + SEP_GAP

    -- Group: Modifiers
    local modTags = {
        {"XP", true,   26, "XP / Level Requirement"},
        {"A",  true,   22, "Class/Race Filter"},
        {"O",  "[O]",  22, "Ongoing Step (stays pinned)"},
        {"OC", "[OC]", 26, "Optional (completes with next step)"},
    }
    for _, def in ipairs(modTags) do
        local label, action, w, tip = def[1], def[2], def[3], def[4]
        local callback
        if action == true then
            callback = function() GLV_Editor_ShowTagPopup(label) end
        else
            callback = function() Editor:InsertTag(getEditBox(), action .. " ") end
        end
        CreateToolbarButton(toolbar, "GLV_EditorBtn_" .. label, label, x, rowY, w, callback, tip)
        x = x + w + GAP
    end

    -- LastQ button (rightmost)
    CreateToolbarButton(toolbar, "GLV_EditorBtn_LastQ", "LastQ", FRAME_WIDTH - 80, rowY, 48, function()
        local tag = Editor:GetLastAcceptedQuestTag()
        if tag then
            Editor:InsertTag(getEditBox(), tag .. " ")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Editor]|r No recently accepted quest found")
        end
    end, "Insert last accepted quest [QA]")

    return toolbar
end


-- ============================================================================
-- EDIT BOX + PREVIEW PANEL
-- ============================================================================

local function CreateEditArea(parent, yStart)
    local SCROLLBAR_WIDTH = 20
    local PADDING = 12
    local GAP = 6
    local contentHeight = FRAME_HEIGHT - math.abs(yStart) - BOTTOM_BAR_HEIGHT - 15

    -- 3-panel layout: Editor (38%) | Syntax (28%) | Live Preview (34%)
    local totalInner = FRAME_WIDTH - (PADDING * 2) - (GAP * 2) - (SCROLLBAR_WIDTH * 3)
    local editWidth = math.floor(totalInner * 0.38)
    local syntaxWidth = math.floor(totalInner * 0.28)
    local liveWidth = totalInner - editWidth - syntaxWidth
    local scrollHeight = contentHeight - 12

    -- ================================================================
    -- LEFT PANEL: Per-Line Editor
    -- One single-line EditBox per line of guide text. Avoids the
    -- ~2048px rendering limit of a single multi-line EditBox.
    -- A hidden multi-line EditBox serves as data store for
    -- Save/Load/Preview compatibility.
    -- ================================================================
    local editContainer = CreateFrame("Frame", "GLV_EditorEditContainer", parent)
    editContainer:SetWidth(editWidth + SCROLLBAR_WIDTH)
    editContainer:SetHeight(contentHeight)
    editContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yStart)
    editContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    editContainer:SetBackdropColor(0, 0, 0, 0.5)
    editContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    -- Hidden data-store EditBox (backward compat for Save/Load/Preview)
    local hiddenEditBox = CreateFrame("EditBox", "GLV_EditorEditBox", editContainer)
    hiddenEditBox:SetMultiLine(true)
    hiddenEditBox:SetMaxLetters(99999)
    hiddenEditBox:SetAutoFocus(false)
    hiddenEditBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    hiddenEditBox:SetWidth(1)
    hiddenEditBox:SetHeight(1)
    hiddenEditBox:SetPoint("TOPLEFT", editContainer, "TOPLEFT", 0, 0)
    hiddenEditBox:SetAlpha(0)
    hiddenEditBox:EnableMouse(false)
    hiddenEditBox:Hide()

    -- ScrollFrame for per-line EditBoxes
    local editScroll = CreateFrame("ScrollFrame", "GLV_EditorEditScroll", editContainer, "UIPanelScrollFrameTemplate")
    editScroll:SetPoint("TOPLEFT", editContainer, "TOPLEFT", 6, -6)
    editScroll:SetPoint("BOTTOMRIGHT", editContainer, "BOTTOMRIGHT", -6 - SCROLLBAR_WIDTH, 6)

    local editChild = CreateFrame("Frame", "GLV_EditorEditChild", editScroll)
    local lineBoxWidth = editWidth - 12
    editChild:SetWidth(lineBoxWidth)
    editChild:SetHeight(scrollHeight)
    editScroll:SetScrollChild(editChild)

    -- Per-line EditBox pool and state
    local LINE_HEIGHT = 14
    local lineBoxes = {}       -- array of EditBox frames
    editChild.lineBoxes = lineBoxes
    editChild.rawText = ""

    -- Flag to prevent recursive syncs
    local syncing = false

    -- Sync all per-line EditBoxes → raw text store + trigger preview
    local function syncToHidden()
        if syncing then return end
        syncing = true
        local parts = {}
        for i = 1, table.getn(lineBoxes) do
            table.insert(parts, lineBoxes[i]:GetText() or "")
        end
        local fullText = table.concat(parts, "\n")
        -- Unescape double pipes from EditBox (WoW returns || for typed |)
        fullText = string.gsub(fullText, "||", "|")
        -- Store raw text in Lua variable (preserves |c color codes)
        editChild.rawText = fullText

        -- Update scroll child height
        local totalH = math.max(scrollHeight, table.getn(lineBoxes) * LINE_HEIGHT + 20)
        editChild:SetHeight(totalH)
        editScroll:UpdateScrollChildRect()

        if GLV.Ace and GLV.Ace.ScheduleEvent then
            GLV.Ace:CancelScheduledEvent("GLV_EditorPreview")
            GLV.Ace:ScheduleEvent("GLV_EditorPreview", GLV_Editor_UpdatePreview, 0.3)
        end
        syncing = false
    end

    -- Remove a line EditBox at index, merge its text into previous
    local function removeLine(idx)
        if idx < 1 or idx > table.getn(lineBoxes) then return end
        local box = lineBoxes[idx]
        local text = box:GetText() or ""
        box:Hide()
        table.remove(lineBoxes, idx)
        -- Re-anchor remaining boxes
        for i = idx, table.getn(lineBoxes) do
            lineBoxes[i]:ClearAllPoints()
            if i == 1 then
                lineBoxes[i]:SetPoint("TOPLEFT", editChild, "TOPLEFT", 2, -2)
            else
                lineBoxes[i]:SetPoint("TOPLEFT", lineBoxes[i - 1], "BOTTOMLEFT", 0, 0)
            end
        end
        return text
    end

    -- Create a single line EditBox at a given index
    local function createLineBox(idx, text)
        local box = CreateFrame("EditBox", nil, editChild)
        box:SetWidth(lineBoxWidth - 4)
        box:SetHeight(LINE_HEIGHT)
        box:SetAutoFocus(false)
        box:SetFont("Fonts\\FRIZQT__.TTF", 11)
        box:SetTextColor(1, 1, 1)
        box:SetTextInsets(2, 2, 0, 0)
        box:SetMaxLetters(9999)

        -- Insert at index
        if idx > table.getn(lineBoxes) then
            table.insert(lineBoxes, box)
        else
            table.insert(lineBoxes, idx, box)
        end

        -- Anchor
        if idx == 1 then
            box:SetPoint("TOPLEFT", editChild, "TOPLEFT", 2, -2)
        else
            box:SetPoint("TOPLEFT", lineBoxes[idx - 1], "BOTTOMLEFT", 0, 0)
        end
        -- Re-anchor boxes after this one
        for i = idx + 1, table.getn(lineBoxes) do
            lineBoxes[i]:ClearAllPoints()
            lineBoxes[i]:SetPoint("TOPLEFT", lineBoxes[i - 1], "BOTTOMLEFT", 0, 0)
        end

        box:SetText(text or "")
        -- Force cursor to start so the EditBox doesn't scroll to show end of text
        pcall(function() box:SetCursorPosition(0) end)
        box:Show()

        -- Store line index (updated dynamically)
        box.lineIdx = idx

        -- Track last focused line for InsertTag
        box:SetScript("OnEditFocusGained", function()
            editChild.lastFocusedLine = this
        end)

        -- OnTextChanged → sync
        box:SetScript("OnTextChanged", function()
            syncToHidden()
        end)

        -- Enter → split line at cursor, create new line below
        box:SetScript("OnEnterPressed", function()
            local fullText = this:GetText() or ""
            -- GetCursorPosition may not exist in WoW 1.12
            local ok, cursorPos = pcall(function() return this:GetCursorPosition() end)
            if not ok or not cursorPos then cursorPos = string.len(fullText) end
            local before = string.sub(fullText, 1, cursorPos)
            local after = string.sub(fullText, cursorPos + 1)
            -- Find current line index
            local myIdx = 0
            for i = 1, table.getn(lineBoxes) do
                if lineBoxes[i] == this then myIdx = i; break end
            end
            if myIdx == 0 then return end
            this:SetText(before)
            local newBox = createLineBox(myIdx + 1, after)
            newBox:SetFocus()
            pcall(function() newBox:SetCursorPosition(0) end)
            syncToHidden()
        end)

        -- Tab → insert spaces
        box:SetScript("OnTabPressed", function()
            this:Insert("    ")
        end)

        -- Escape → clear focus
        box:SetScript("OnEscapePressed", function()
            this:ClearFocus()
        end)

        -- Mouse wheel on any line → scroll the panel
        box:EnableMouseWheel(true)
        box:SetScript("OnMouseWheel", function()
            this:ClearFocus()
            local scroll = editScroll:GetVerticalScroll()
            local maxScroll = editScroll:GetVerticalScrollRange()
            local delta = 42
            if arg1 > 0 then
                editScroll:SetVerticalScroll(math.max(0, scroll - delta))
            else
                editScroll:SetVerticalScroll(math.min(maxScroll, scroll + delta))
            end
        end)

        -- Backspace/Delete merge + Up/Down navigation between lines
        -- Arrow navigation is deferred with ScheduleEvent because the EditBox
        -- processes arrow keys internally before OnKeyDown completes.
        box:SetScript("OnKeyDown", function()
            local myIdx = 0
            for i = 1, table.getn(lineBoxes) do
                if lineBoxes[i] == this then myIdx = i; break end
            end
            if arg1 == "BACKSPACE" then
                local pos = this:GetCursorPosition()
                if pos == 0 and myIdx > 1 then
                    local prevBox = lineBoxes[myIdx - 1]
                    local prevText = prevBox:GetText() or ""
                    local curText = this:GetText() or ""
                    local mergePos = string.len(prevText)
                    removeLine(myIdx)
                    prevBox:SetText(prevText .. curText)
                    prevBox:SetFocus()
                    pcall(function() prevBox:SetCursorPosition(mergePos) end)
                    syncToHidden()
                end
            elseif arg1 == "DELETE" then
                local pos = this:GetCursorPosition()
                local curText = this:GetText() or ""
                if pos >= string.len(curText) and myIdx < table.getn(lineBoxes) then
                    local nextText = removeLine(myIdx + 1)
                    this:SetText(curText .. (nextText or ""))
                    pcall(function() this:SetCursorPosition(pos) end)
                    syncToHidden()
                end
            elseif arg1 == "UP" and myIdx > 1 then
                -- Defer focus change to next frame so EditBox finishes processing
                local targetIdx = myIdx - 1
                local cursorPos = this:GetCursorPosition()
                if GLV.Ace and GLV.Ace.ScheduleEvent then
                    GLV.Ace:ScheduleEvent("GLV_EditorArrowNav", function()
                        local target = lineBoxes[targetIdx]
                        if target then
                            target:SetFocus()
                            local tLen = string.len(target:GetText() or "")
                            pcall(function() target:SetCursorPosition(math.min(cursorPos, tLen)) end)
                        end
                    end, 0.01)
                end
            elseif arg1 == "DOWN" and myIdx < table.getn(lineBoxes) then
                local targetIdx = myIdx + 1
                local cursorPos = this:GetCursorPosition()
                if GLV.Ace and GLV.Ace.ScheduleEvent then
                    GLV.Ace:ScheduleEvent("GLV_EditorArrowNav", function()
                        local target = lineBoxes[targetIdx]
                        if target then
                            target:SetFocus()
                            local tLen = string.len(target:GetText() or "")
                            pcall(function() target:SetCursorPosition(math.min(cursorPos, tLen)) end)
                        end
                    end, 0.01)
                end
            end
        end)

        return box
    end

    -- Build per-line EditBoxes from text
    local function buildLinesFromText(text)
        -- Clear existing
        for i = 1, table.getn(lineBoxes) do
            lineBoxes[i]:Hide()
        end
        for i = table.getn(lineBoxes), 1, -1 do
            table.remove(lineBoxes, i)
        end

        if not text or text == "" then
            createLineBox(1, "")
            syncToHidden()
            return
        end

        -- Split text into lines
        local idx = 1
        local start = 1
        while true do
            local nl = string.find(text, "\n", start, true)
            if nl then
                createLineBox(idx, string.sub(text, start, nl - 1))
                idx = idx + 1
                start = nl + 1
            else
                createLineBox(idx, string.sub(text, start))
                break
            end
        end
        syncToHidden()
    end

    -- Expose functions on editChild so Load/Import/InsertTag can use them
    editChild.buildLinesFromText = buildLinesFromText
    editChild.createLineBox = createLineBox
    editChild.syncToHidden = syncToHidden
    editChild.lastFocusedLine = nil

    -- Start with one empty line
    createLineBox(1, "")

    -- Mouse wheel on container
    editContainer:EnableMouseWheel(true)
    editContainer:SetScript("OnMouseWheel", function()
        local scroll = editScroll:GetVerticalScroll()
        local maxScroll = editScroll:GetVerticalScrollRange()
        local delta = 42
        if arg1 > 0 then
            editScroll:SetVerticalScroll(math.max(0, scroll - delta))
        else
            editScroll:SetVerticalScroll(math.min(maxScroll, scroll + delta))
        end
    end)

    -- Header
    local editHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editHeader:SetPoint("BOTTOMLEFT", editContainer, "TOPLEFT", 4, 2)
    editHeader:SetText("|cFF888888Source|r")

    -- ================================================================
    -- MIDDLE PANEL: Syntax Highlighting
    -- ================================================================
    local syntaxContainer = CreateFrame("Frame", "GLV_EditorSyntaxContainer", parent)
    syntaxContainer:SetWidth(syntaxWidth + SCROLLBAR_WIDTH)
    syntaxContainer:SetHeight(contentHeight)
    syntaxContainer:SetPoint("TOPLEFT", editContainer, "TOPRIGHT", GAP, 0)
    syntaxContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    syntaxContainer:SetBackdropColor(0.05, 0.05, 0.1, 0.6)
    syntaxContainer:SetBackdropBorderColor(0.3, 0.3, 0.5, 0.8)

    local syntaxScroll = CreateFrame("ScrollFrame", "GLV_EditorSyntaxScroll", syntaxContainer, "UIPanelScrollFrameTemplate")
    syntaxScroll:SetPoint("TOPLEFT", syntaxContainer, "TOPLEFT", 6, -6)
    syntaxScroll:SetPoint("BOTTOMRIGHT", syntaxContainer, "BOTTOMRIGHT", -6 - SCROLLBAR_WIDTH, 6)

    local syntaxChild = CreateFrame("Frame", "GLV_EditorSyntaxChild", syntaxScroll)
    syntaxChild:SetWidth(syntaxWidth - 8)
    syntaxChild:SetHeight(scrollHeight)

    -- FontStrings are created per-line in UpdatePreview (avoids single FontString text limit)
    syntaxChild.lineFS = {}

    syntaxScroll:SetScrollChild(syntaxChild)

    local syntaxHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    syntaxHeader:SetPoint("BOTTOMLEFT", syntaxContainer, "TOPLEFT", 4, 2)
    syntaxHeader:SetText("|cFF888888Syntax|r")

    -- ================================================================
    -- RIGHT PANEL: Live Guide Preview
    -- ================================================================
    local liveContainer = CreateFrame("Frame", "GLV_EditorLiveContainer", parent)
    liveContainer:SetWidth(liveWidth + SCROLLBAR_WIDTH)
    liveContainer:SetHeight(contentHeight)
    liveContainer:SetPoint("TOPLEFT", syntaxContainer, "TOPRIGHT", GAP, 0)
    liveContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    liveContainer:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    liveContainer:SetBackdropBorderColor(0.3, 0.3, 0.5, 0.8)

    local liveScroll = CreateFrame("ScrollFrame", "GLV_EditorLiveScroll", liveContainer, "UIPanelScrollFrameTemplate")
    liveScroll:SetPoint("TOPLEFT", liveContainer, "TOPLEFT", 6, -6)
    liveScroll:SetPoint("BOTTOMRIGHT", liveContainer, "BOTTOMRIGHT", -6 - SCROLLBAR_WIDTH, 6)

    local liveChild = CreateFrame("Frame", "GLV_EditorLiveChild", liveScroll)
    liveChild:SetWidth(liveWidth - 8)
    liveChild:SetHeight(scrollHeight)

    liveScroll:SetScrollChild(liveChild)

    local liveHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    liveHeader:SetPoint("BOTTOMLEFT", liveContainer, "TOPLEFT", 4, 2)
    liveHeader:SetText("|cFF888888Guide Preview|r")
end


-- ============================================================================
-- BOTTOM BAR (Save, Load, New, Delete, Import)
-- ============================================================================

local function CreateBottomBar(parent)
    local barY = 12

    -- New button
    local newBtn = CreateFrame("Button", "GLV_EditorNewBtn", parent, "UIPanelButtonTemplate")
    newBtn:SetWidth(50)
    newBtn:SetHeight(22)
    newBtn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 12, barY)
    newBtn:SetText("New")
    newBtn:SetScript("OnClick", function() GLV_Editor_NewGuide() end)

    -- Save button
    local saveBtn = CreateFrame("Button", "GLV_EditorSaveBtn", parent, "UIPanelButtonTemplate")
    saveBtn:SetWidth(50)
    saveBtn:SetHeight(22)
    saveBtn:SetPoint("LEFT", newBtn, "RIGHT", 4, 0)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", function() GLV_Editor_SaveGuide() end)

    -- Delete button
    local delBtn = CreateFrame("Button", "GLV_EditorDeleteBtn", parent, "UIPanelButtonTemplate")
    delBtn:SetWidth(55)
    delBtn:SetHeight(22)
    delBtn:SetPoint("LEFT", saveBtn, "RIGHT", 4, 0)
    delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function() GLV_Editor_DeleteGuide() end)

    -- Separator
    local sepLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sepLabel:SetPoint("LEFT", delBtn, "RIGHT", 12, 0)
    sepLabel:SetText("|cFF666666|||r")

    -- Saved guides label
    local loadLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    loadLabel:SetPoint("LEFT", sepLabel, "RIGHT", 8, 0)
    loadLabel:SetText("Guide:")

    -- Saved guides dropdown
    local savedDropdown = CreateFrame("Frame", "GLV_EditorSavedDropdown", parent, "UIDropDownMenuTemplate")
    savedDropdown:SetPoint("LEFT", loadLabel, "RIGHT", -12, -2)
    UIDropDownMenu_SetWidth(130, savedDropdown)

    -- Separator 2
    local sepLabel2 = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sepLabel2:SetPoint("LEFT", savedDropdown, "RIGHT", -4, 2)
    sepLabel2:SetText("|cFF666666|||r")

    -- Import dropdown
    local importDropdown = CreateFrame("Frame", "GLV_EditorImportDropdown", parent, "UIDropDownMenuTemplate")
    importDropdown:SetPoint("LEFT", sepLabel2, "RIGHT", -12, -2)
    UIDropDownMenu_SetWidth(100, importDropdown)
    UIDropDownMenu_SetText("Import", importDropdown)
end


-- ============================================================================
-- TAG POPUP (reusable)
-- ============================================================================

local function CreateTagPopup()
    if tagPopup then return tagPopup end

    tagPopup = CreateFrame("Frame", "GLV_EditorTagPopup", UIParent)
    tagPopup:SetWidth(280)
    tagPopup:SetHeight(160)
    tagPopup:SetPoint("CENTER", 0, 50)
    tagPopup:SetFrameStrata("TOOLTIP")
    tagPopup:SetMovable(true)
    tagPopup:EnableMouse(true)
    tagPopup:RegisterForDrag("LeftButton")
    tagPopup:SetScript("OnDragStart", function() this:StartMoving() end)
    tagPopup:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    tagPopup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    table.insert(UISpecialFrames, "GLV_EditorTagPopup")

    -- Title
    local popTitle = tagPopup:CreateFontString("GLV_EditorTagPopupTitle", "OVERLAY", "GameFontNormal")
    popTitle:SetPoint("TOP", 0, -12)

    -- Field 1: ID / value
    local f1Label = tagPopup:CreateFontString("GLV_EditorTagPopupF1Label", "OVERLAY", "GameFontNormalSmall")
    f1Label:SetPoint("TOPLEFT", 15, -32)
    f1Label:SetText("ID:")

    local f1Box = CreateFrame("EditBox", "GLV_EditorTagPopupF1", tagPopup, "InputBoxTemplate")
    f1Box:SetWidth(180)
    f1Box:SetHeight(20)
    f1Box:SetPoint("LEFT", f1Label, "RIGHT", 5, 0)
    f1Box:SetAutoFocus(false)
    f1Box:SetScript("OnEscapePressed", function() tagPopup:Hide() end)

    -- Field 2: text / count / objective
    local f2Label = tagPopup:CreateFontString("GLV_EditorTagPopupF2Label", "OVERLAY", "GameFontNormalSmall")
    f2Label:SetPoint("TOPLEFT", 15, -56)
    f2Label:SetText("Value:")

    local f2Box = CreateFrame("EditBox", "GLV_EditorTagPopupF2", tagPopup, "InputBoxTemplate")
    f2Box:SetWidth(180)
    f2Box:SetHeight(20)
    f2Box:SetPoint("LEFT", f2Label, "RIGHT", 5, 0)
    f2Box:SetAutoFocus(false)
    f2Box:SetScript("OnEscapePressed", function() tagPopup:Hide() end)

    -- Preview label (shows resolved name)
    local previewLabel = tagPopup:CreateFontString("GLV_EditorTagPopupPreview", "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetPoint("TOPLEFT", 15, -80)
    previewLabel:SetWidth(250)
    previewLabel:SetJustifyH("LEFT")

    -- Quest log dropdown
    local questDropdown = CreateFrame("Frame", "GLV_EditorTagPopupQuestDD", tagPopup, "UIDropDownMenuTemplate")
    questDropdown:SetPoint("TOPLEFT", 0, -95)
    UIDropDownMenu_SetWidth(220, questDropdown)
    questDropdown:Hide()

    -- OK button
    local okBtn = CreateFrame("Button", "GLV_EditorTagPopupOK", tagPopup, "UIPanelButtonTemplate")
    okBtn:SetWidth(60)
    okBtn:SetHeight(22)
    okBtn:SetPoint("BOTTOMRIGHT", tagPopup, "BOTTOMRIGHT", -80, 12)
    okBtn:SetText("OK")

    -- Cancel button
    local cancelBtn = CreateFrame("Button", "GLV_EditorTagPopupCancel", tagPopup, "UIPanelButtonTemplate")
    cancelBtn:SetWidth(60)
    cancelBtn:SetHeight(22)
    cancelBtn:SetPoint("LEFT", okBtn, "RIGHT", 4, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() tagPopup:Hide() end)

    tagPopup:Hide()
    return tagPopup
end


-- ============================================================================
-- GLOBAL FUNCTIONS (called from scripts)
-- ============================================================================

-- Icon mapping for tag types (only non-quest types; quest icons are already in parsed text)
local TAG_ICONS = {
    TRAIN             = "Interface\\GossipFrame\\TrainerGossipIcon",
    HEARTHSTONE       = "Interface\\Icons\\INV_Misc_Rune_01",
    BIND_HEARTHSTONE  = "Interface\\Icons\\INV_Misc_Rune_01",
    GET_FLIGHT_PATH   = "Interface\\GossipFrame\\TaxiGossipIcon",
    GET_FP            = "Interface\\GossipFrame\\TaxiGossipIcon",
    FLY_TO            = "Interface\\GossipFrame\\TaxiGossipIcon",
    COLLECT_ITEM      = "Interface\\Icons\\INV_Misc_Bag_08",
    LEARN             = "Interface\\GossipFrame\\TrainerGossipIcon",
    SKILL             = "Interface\\GossipFrame\\TrainerGossipIcon",
}

-- Render the live guide preview (mini guide renderer)
-- Parser returns flat steps (one per line), not grouped steps with sub-lines
local function RenderLivePreview(text)
    local liveChild = getglobal("GLV_EditorLiveChild")
    local liveScroll = getglobal("GLV_EditorLiveScroll")
    if not liveChild then return end

    -- Clear previous children
    local children = { liveChild:GetChildren() }
    for _, child in pairs(children) do
        if child and child.Hide then
            child:Hide()
            child:SetParent(nil)
        end
    end

    if not text or text == "" then return end
    if not GLV.Parser or not GLV.Parser.parseGuide then return end

    -- Parse the guide
    local guide = GLV.Parser:parseGuide(text, "EditorPreview")
    if not guide or not guide.steps or table.getn(guide.steps) == 0 then return end

    local childWidth = liveChild:GetWidth()
    local stepSpacing = -2
    local lastFrame = nil
    local totalHeight = 0
    local stepIdx = 0

    local bgColors = {
        {0.18, 0.18, 0.18, 0.9},
        {0.12, 0.12, 0.12, 0.9},
    }
    local activeColor = {0.8, 0.8, 0.2, 0.9}

    for _, step in ipairs(guide.steps) do
        -- Skip empty separator lines
        if not step.emptyLine and step.text and step.text ~= "" then
            stepIdx = stepIdx + 1

            local frameName = "GLV_EditorLiveStep" .. stepIdx
            local frame = CreateFrame("Frame", frameName, liveChild)
            frame:SetWidth(childWidth)
            frame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                tile = true, tileSize = 16, edgeSize = 0,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })

            -- First step is active (yellow), others alternate
            if stepIdx == 1 then
                frame:SetBackdropColor(unpack(activeColor))
            else
                local bgIdx = math.mod(stepIdx - 1, 2) + 1
                frame:SetBackdropColor(unpack(bgColors[bgIdx]))
            end

            -- Determine icon from step data
            local iconSize = 13
            local hasIcon = false
            local iconTexturePath = nil

            if step.icon then
                iconTexturePath = step.icon
                hasIcon = true
            elseif step.stepType then
                iconTexturePath = TAG_ICONS[step.stepType]
                if iconTexturePath and iconTexturePath ~= "" then
                    hasIcon = true
                end
            end

            local textXOffset = hasIcon and (iconSize + 6) or 4

            -- FontString for text
            local textWidth = childWidth - textXOffset - 22
            local textFS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            textFS:SetFont("Fonts\\FRIZQT__.TTF", 11)
            textFS:SetWidth(textWidth)
            textFS:SetJustifyH("LEFT")
            textFS:SetJustifyV("TOP")
            textFS:SetNonSpaceWrap(true)
            textFS:SetText(step.text)
            textFS:SetPoint("TOPLEFT", frame, "TOPLEFT", textXOffset, -2)

            -- Estimate height: strip color codes, split on \n, estimate wrapped lines per sub-line
            local cleanText = string.gsub(step.text or "", "|c%x%x%x%x%x%x%x%x", "")
            cleanText = string.gsub(cleanText, "|r", "")
            local charsPerLine = math.max(1, math.floor(textWidth / 7))
            local totalLines = 0
            for subline in string.gfind(cleanText .. "\n", "(.-)\n") do
                local trimmed = string.gsub(subline, "^%s+", "")
                if string.len(trimmed) == 0 then
                    totalLines = totalLines + 1
                else
                    totalLines = totalLines + math.max(1, math.ceil(string.len(trimmed) / charsPerLine))
                end
            end
            local textHeight = math.max(14, totalLines * 14)

            if hasIcon and iconTexturePath then
                local iconTex = frame:CreateTexture(nil, "OVERLAY")
                iconTex:SetWidth(iconSize)
                iconTex:SetHeight(iconSize)
                iconTex:SetTexture(iconTexturePath)
                iconTex:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -2)
            end

            local frameHeight = textHeight + 6
            frame:SetHeight(frameHeight)
            if lastFrame then
                frame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, stepSpacing)
            else
                frame:SetPoint("TOPLEFT", liveChild, "TOPLEFT", 0, 0)
            end
            frame:Show()

            lastFrame = frame
            totalHeight = totalHeight + frameHeight + math.abs(stepSpacing)
        end
    end

    -- Resize child to fit
    if liveScroll then
        liveChild:SetHeight(math.max(liveScroll:GetHeight(), totalHeight + 10))
        liveScroll:UpdateScrollChildRect()
    end
end

-- Update both preview panels (syntax + live)
function GLV_Editor_UpdatePreview()
    local editChild = getglobal("GLV_EditorEditChild")
    local text = editChild and editChild.rawText or ""

    -- 1) Syntax panel (per-line FontStrings to avoid single FontString text limit)
    local syntaxChild = getglobal("GLV_EditorSyntaxChild")
    local syntaxScroll = getglobal("GLV_EditorSyntaxScroll")
    if syntaxChild and syntaxScroll then
        local colored = Editor:ColorizeText(text)

        -- Split into lines
        local lines = {}
        local start = 1
        while true do
            local nl = string.find(colored, "\n", start, true)
            if nl then
                table.insert(lines, string.sub(colored, start, nl - 1))
                start = nl + 1
            else
                table.insert(lines, string.sub(colored, start))
                break
            end
        end

        -- Ensure lineFS pool exists (lost after /reload)
        if not syntaxChild.lineFS then syntaxChild.lineFS = {} end

        local childWidth = syntaxChild:GetWidth()
        local yOff = -4
        local lineHeight = 14

        for i, lineText in ipairs(lines) do
            local fs = syntaxChild.lineFS[i]
            if not fs then
                fs = syntaxChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                fs:SetFont("Fonts\\FRIZQT__.TTF", 11)
                fs:SetWidth(childWidth - 8)
                fs:SetJustifyH("LEFT")
                fs:SetJustifyV("TOP")
                fs:SetNonSpaceWrap(true)
                syntaxChild.lineFS[i] = fs
            end
            fs:SetText(lineText ~= "" and lineText or " ")
            fs:SetPoint("TOPLEFT", syntaxChild, "TOPLEFT", 4, yOff)
            fs:Show()

            local h = fs:GetHeight()
            if not h or h < lineHeight then h = lineHeight end
            yOff = yOff - h
        end

        -- Hide excess FontStrings from previous longer text
        for i = table.getn(lines) + 1, table.getn(syntaxChild.lineFS) do
            if syntaxChild.lineFS[i] then
                syntaxChild.lineFS[i]:Hide()
            end
        end

        -- Update scroll child height
        local totalH = math.abs(yOff) + 10
        syntaxChild:SetHeight(math.max(syntaxScroll:GetHeight(), totalH))
        syntaxScroll:UpdateScrollChildRect()
    end

    -- 2) Live guide preview (pcall protected)
    local ok, err = pcall(RenderLivePreview, text)
    if not ok and GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Editor Preview]|r " .. tostring(err))
    end
end

-- Create a new empty guide
function GLV_Editor_NewGuide()
    local frame = getglobal("GLV_EditorFrame")
    if not frame then return end

    frame.currentGuideName = nil

    local nameBox = getglobal("GLV_EditorNameBox")
    local minBox = getglobal("GLV_EditorMinLevelBox")
    local maxBox = getglobal("GLV_EditorMaxLevelBox")
    local nxBox = getglobal("GLV_EditorNextGuideBox")
    local editBox = getglobal("GLV_EditorEditBox")
    local factionDD = getglobal("GLV_EditorFactionDropdown")

    local descBox = getglobal("GLV_EditorDescBox")

    if nameBox then nameBox:SetText("") end
    if minBox then minBox:SetText("1") end
    if maxBox then maxBox:SetText("10") end
    if descBox then descBox:SetText("") end
    if nxBox then nxBox:SetText("") end

    -- Set faction dropdown to player's faction
    local playerFaction = "Alliance"
    if GLV.Settings then
        playerFaction = GLV.Settings:GetOption({"CharInfo", "Faction"}) or "Alliance"
    end
    if factionDD then
        UIDropDownMenu_SetSelectedValue(factionDD, playerFaction)
        UIDropDownMenu_SetText(playerFaction, factionDD)
    end

    -- Uncheck all race checkboxes
    for _, race in ipairs(EDITOR_RACES) do
        local cb = getglobal("GLV_EditorRace_" .. string.gsub(race, "%s", ""))
        if cb then cb:SetChecked(false) end
    end

    -- Rebuild per-line EditBoxes (empty)
    local editChild = getglobal("GLV_EditorEditChild")
    if editChild and editChild.buildLinesFromText then
        editChild.buildLinesFromText("")
        -- Focus first line
        if editChild.lineBoxes and editChild.lineBoxes[1] then
            editChild.lineBoxes[1]:SetFocus()
        end
    end

    local editScroll = getglobal("GLV_EditorEditScroll")
    if editScroll then editScroll:SetVerticalScroll(0) end

    GLV_Editor_UpdatePreview()
end

-- Save the current guide
function GLV_Editor_SaveGuide()
    local frame = getglobal("GLV_EditorFrame")
    if not frame then return end

    local nameBox = getglobal("GLV_EditorNameBox")
    local minBox = getglobal("GLV_EditorMinLevelBox")
    local maxBox = getglobal("GLV_EditorMaxLevelBox")
    local descBox = getglobal("GLV_EditorDescBox")
    local editChild = getglobal("GLV_EditorEditChild")
    local factionDD = getglobal("GLV_EditorFactionDropdown")
    local nxBox = getglobal("GLV_EditorNextGuideBox")

    local guideName = nameBox and nameBox:GetText() or ""
    if guideName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Editor]|r Please enter a guide name")
        return
    end

    local minLvl = minBox and minBox:GetText() or "1"
    local maxLvl = maxBox and maxBox:GetText() or "60"
    local description = descBox and descBox:GetText() or ""
    local faction = factionDD and UIDropDownMenu_GetSelectedValue(factionDD) or ""
    local nextGuide = nxBox and nxBox:GetText() or ""
    local bodyText = editChild and editChild.rawText or ""

    -- Collect selected races
    local selectedRaces = {}
    for _, race in ipairs(EDITOR_RACES) do
        local cbName = "GLV_EditorRace_" .. string.gsub(race, "%s", "")
        local cb = getglobal(cbName)
        if cb and cb:GetChecked() then
            table.insert(selectedRaces, race)
        end
    end

    -- Build GA value: faction + races comma-separated
    local gaValue = faction
    if table.getn(selectedRaces) > 0 then
        local raceStr = table.concat(selectedRaces, ",")
        if gaValue ~= "" then
            gaValue = gaValue .. "," .. raceStr
        else
            gaValue = raceStr
        end
    end

    -- Build full guide text with header
    local lines = Editor:BuildHeaderFromMetadata(guideName, minLvl, maxLvl, gaValue, description)
    local header = table.concat(lines, "\n")

    -- Add next guide line at the end if specified
    local nxLine = ""
    if nextGuide ~= "" then
        local nxTag = Editor:BuildNextGuideLine(nextGuide)
        if nxTag then
            nxLine = "\n" .. nxTag
        end
    end

    -- Strip existing header/footer tags from body so metadata fields always take precedence
    local strippedLines = {}
    for line in string.gfind(bodyText .. "\n", "(.-)[\n]") do
        -- Skip lines that are purely header/footer tags: [N ...], [D ...], [GA ...], [NX ...]
        local trimmed = string.gsub(line, "^%s+", "")
        if not string.find(trimmed, "^%[N%s+%d") and
           not string.find(trimmed, "^%[NX%s") and
           not string.find(trimmed, "^%[D%s") and
           not string.find(trimmed, "^%[GA%s") then
            table.insert(strippedLines, line)
        end
    end
    -- Remove leading empty lines after stripping
    while table.getn(strippedLines) > 0 and strippedLines[1] == "" do
        table.remove(strippedLines, 1)
    end
    -- Remove trailing empty lines
    while table.getn(strippedLines) > 0 and strippedLines[table.getn(strippedLines)] == "" do
        table.remove(strippedLines, table.getn(strippedLines))
    end
    local cleanBody = table.concat(strippedLines, "\n")

    -- Always combine: header + body + next guide
    local fullText = header .. "\n\n" .. cleanBody .. nxLine

    -- If name changed, delete the old guide entry first (rename)
    local oldName = frame.currentGuideName
    if oldName and oldName ~= "" and oldName ~= guideName then
        Editor:DeleteGuide(oldName)
    end

    local success = Editor:SaveGuide(guideName, fullText)
    if success then
        frame.currentGuideName = guideName
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Editor]|r Guide \"" .. guideName .. "\" saved!")
        GLV_Editor_RefreshSavedDropdown()
        -- Reload saved guide into editor so body reflects the full combined text
        GLV_Editor_LoadSavedGuide(guideName)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Editor]|r Failed to save guide")
    end
end

-- Delete the current guide
function GLV_Editor_DeleteGuide()
    local frame = getglobal("GLV_EditorFrame")
    if not frame or not frame.currentGuideName then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Editor]|r No guide loaded to delete")
        return
    end
    StaticPopup_Show("GLV_DELETE_GUIDE", frame.currentGuideName)
end

-- Load a saved guide into the editor
function GLV_Editor_LoadSavedGuide(name)
    local entry = Editor:LoadGuide(name)
    if not entry then return end

    local frame = getglobal("GLV_EditorFrame")
    if frame then
        frame.currentGuideName = name
    end

    -- Extract metadata from text
    local meta = Editor:ExtractMetadata(entry.text)

    local nameBox = getglobal("GLV_EditorNameBox")
    local minBox = getglobal("GLV_EditorMinLevelBox")
    local maxBox = getglobal("GLV_EditorMaxLevelBox")
    local descBox = getglobal("GLV_EditorDescBox")
    local nxBox = getglobal("GLV_EditorNextGuideBox")
    local editBox = getglobal("GLV_EditorEditBox")
    local factionDD = getglobal("GLV_EditorFactionDropdown")

    if nameBox then nameBox:SetText(meta.name or name) end
    if minBox then minBox:SetText(meta.minLevel or "1") end
    if maxBox then maxBox:SetText(meta.maxLevel or "60") end
    if descBox then descBox:SetText(meta.description or "") end
    if nxBox then nxBox:SetText(meta.nextGuide or "") end

    -- Parse GA value into faction + races
    local gaRaw = meta.faction or ""
    local factionVal = ""
    local raceSet = {}
    for value in string.gfind(gaRaw .. ",", "([^,]+),") do
        value = string.gsub(value, "^%s*(.-)%s*$", "%1")
        if value == "Alliance" or value == "Horde" then
            factionVal = value
        elseif value ~= "" then
            raceSet[value] = true
        end
    end

    if factionDD then
        local label = factionVal
        if factionVal == "" then label = "Both" end
        UIDropDownMenu_SetSelectedValue(factionDD, factionVal)
        UIDropDownMenu_SetText(label, factionDD)
    end

    -- Restore race checkboxes
    for _, race in ipairs(EDITOR_RACES) do
        local cb = getglobal("GLV_EditorRace_" .. string.gsub(race, "%s", ""))
        if cb then cb:SetChecked(raceSet[race] or false) end
    end

    -- Rebuild per-line EditBoxes from guide text
    local editChild = getglobal("GLV_EditorEditChild")
    if editChild and editChild.buildLinesFromText then
        editChild.buildLinesFromText(entry.text)
    end

    -- Scroll source panel to top
    local editScroll = getglobal("GLV_EditorEditScroll")
    if editScroll then editScroll:SetVerticalScroll(0) end

    GLV_Editor_UpdatePreview()
end

-- Refresh the saved guides dropdown
function GLV_Editor_RefreshSavedDropdown()
    local dropdown = getglobal("GLV_EditorSavedDropdown")
    if not dropdown then return end

    local names = Editor:GetSavedGuideNames()

    UIDropDownMenu_Initialize(dropdown, function()
        if table.getn(names) == 0 then
            local info = {}
            info.text = "No saved guides"
            info.disabled = 1
            UIDropDownMenu_AddButton(info)
            return
        end
        for _, name in ipairs(names) do
            local info = {}
            info.text = name
            info.value = name
            info.func = function()
                UIDropDownMenu_SetSelectedValue(dropdown, name)
                UIDropDownMenu_SetText(name, dropdown)
                GLV_Editor_LoadSavedGuide(name)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local frame = getglobal("GLV_EditorFrame")
    if frame and frame.currentGuideName then
        UIDropDownMenu_SetSelectedValue(dropdown, frame.currentGuideName)
        UIDropDownMenu_SetText(frame.currentGuideName, dropdown)
    else
        UIDropDownMenu_SetText("Select", dropdown)
    end
end

-- Factory function for import callback (avoids Lua 5.0 closure issues in loops)
local function createImportCallback(packName, guideId, displayName, dropdown)
    return function()
        local text = GLV.GuideEditor:ImportGuide(packName, guideId)
        if not text then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Editor]|r Failed to import guide")
            return
        end
        -- Rebuild per-line EditBoxes from imported text
        local editChild = getglobal("GLV_EditorEditChild")
        if editChild and editChild.buildLinesFromText then
            editChild.buildLinesFromText(text)
        end
        -- Scroll source panel to top
        local editScroll = getglobal("GLV_EditorEditScroll")
        if editScroll then editScroll:SetVerticalScroll(0) end
        local meta = GLV.GuideEditor:ExtractMetadata(text)
        local nameBox = getglobal("GLV_EditorNameBox")
        local minBox = getglobal("GLV_EditorMinLevelBox")
        local maxBox = getglobal("GLV_EditorMaxLevelBox")
        local descBox = getglobal("GLV_EditorDescBox")
        local nxBox = getglobal("GLV_EditorNextGuideBox")
        local factionDD = getglobal("GLV_EditorFactionDropdown")
        if nameBox then nameBox:SetText(meta.name or "") end
        if minBox then minBox:SetText(meta.minLevel or "1") end
        if maxBox then maxBox:SetText(meta.maxLevel or "60") end
        if descBox then descBox:SetText(meta.description or "") end
        if nxBox then nxBox:SetText(meta.nextGuide or "") end
        -- Parse GA value into faction + races
        local gaRaw = meta.faction or ""
        local importFaction = ""
        local importRaces = {}
        for value in string.gfind(gaRaw .. ",", "([^,]+),") do
            value = string.gsub(value, "^%s*(.-)%s*$", "%1")
            if value == "Alliance" or value == "Horde" then
                importFaction = value
            elseif value ~= "" then
                importRaces[value] = true
            end
        end
        if factionDD then
            local label = importFaction
            if importFaction == "" then label = "Both" end
            UIDropDownMenu_SetSelectedValue(factionDD, importFaction)
            UIDropDownMenu_SetText(label, factionDD)
        end
        for _, race in ipairs(EDITOR_RACES) do
            local cb = getglobal("GLV_EditorRace_" .. string.gsub(race, "%s", ""))
            if cb then cb:SetChecked(importRaces[race] or false) end
        end
        GLV_Editor_UpdatePreview()
        UIDropDownMenu_SetText("Import", dropdown)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Editor]|r Imported: " .. displayName)
    end
end

-- Initialize the import dropdown with 3-level menus (Pack > Level Range > Guide)
function GLV_Editor_RefreshImportDropdown()
    local dropdown = getglobal("GLV_EditorImportDropdown")
    if not dropdown then return end

    local packs = Editor:GetImportableGuides()
    -- Pre-compute level groups per pack
    local packGroups = {}
    for _, pack in ipairs(packs) do
        packGroups[pack.name] = groupImportGuidesByRange(pack.guides)
    end

    UIDropDownMenu_Initialize(dropdown, function(level)
        if not level then level = 1 end

        if level == 1 then
            -- Level 1: Pack names
            if table.getn(packs) == 0 then
                local info = {}
                info.text = "No guide packs"
                info.disabled = 1
                UIDropDownMenu_AddButton(info, 1)
                return
            end
            for _, pack in ipairs(packs) do
                local info = {}
                info.text = pack.name .. " (" .. table.getn(pack.guides) .. ")"
                info.value = pack.name
                info.hasArrow = 1
                info.notCheckable = 1
                UIDropDownMenu_AddButton(info, 1)
            end

        elseif level == 2 then
            -- Level 2: Level range groups (or flat list if few guides)
            local selectedPack = UIDROPDOWNMENU_MENU_VALUE
            local groups = packGroups[selectedPack]
            if not groups then return end

            -- If only 1 group or few total guides, show guides directly
            local totalGuides = 0
            for _, grp in ipairs(groups) do
                totalGuides = totalGuides + table.getn(grp.guides)
            end

            if totalGuides <= 25 then
                -- Flat list: show all guides directly
                for _, grp in ipairs(groups) do
                    for _, guide in ipairs(grp.guides) do
                        local displayName = guide.name
                        if guide.minLevel and guide.maxLevel then
                            displayName = guide.name .. " (" .. guide.minLevel .. "-" .. guide.maxLevel .. ")"
                        end
                        local info = {}
                        info.text = displayName
                        info.value = guide.id
                        info.func = createImportCallback(selectedPack, guide.id, displayName, dropdown)
                        UIDropDownMenu_AddButton(info, 2)
                    end
                end
            else
                -- Too many guides: show level range submenus
                for _, grp in ipairs(groups) do
                    local info = {}
                    info.text = grp.label .. " (" .. table.getn(grp.guides) .. ")"
                    info.value = selectedPack .. "|" .. grp.key
                    info.hasArrow = 1
                    info.notCheckable = 1
                    UIDropDownMenu_AddButton(info, 2)
                end
            end

        elseif level == 3 then
            -- Level 3: Individual guides within a level range
            local menuValue = UIDROPDOWNMENU_MENU_VALUE or ""
            local _, _, packName, rangeKey = string.find(menuValue, "^(.+)|(.+)$")
            if not packName or not rangeKey then return end

            local groups = packGroups[packName]
            if not groups then return end

            for _, grp in ipairs(groups) do
                if grp.key == rangeKey then
                    for _, guide in ipairs(grp.guides) do
                        local displayName = guide.name
                        if guide.minLevel and guide.maxLevel then
                            displayName = guide.name .. " (" .. guide.minLevel .. "-" .. guide.maxLevel .. ")"
                        end
                        local info = {}
                        info.text = displayName
                        info.value = guide.id
                        info.func = createImportCallback(packName, guide.id, displayName, dropdown)
                        UIDropDownMenu_AddButton(info, 3)
                    end
                    break
                end
            end
        end
    end)

    UIDropDownMenu_SetText("Import", dropdown)
end


-- ============================================================================
-- TAG POPUP LOGIC
-- ============================================================================

function GLV_Editor_ShowTagPopup(tagType)
    local popup = CreateTagPopup()

    local titleText = getglobal("GLV_EditorTagPopupTitle")
    local f1Label = getglobal("GLV_EditorTagPopupF1Label")
    local f1Box = getglobal("GLV_EditorTagPopupF1")
    local f2Label = getglobal("GLV_EditorTagPopupF2Label")
    local f2Box = getglobal("GLV_EditorTagPopupF2")
    local preview = getglobal("GLV_EditorTagPopupPreview")
    local questDD = getglobal("GLV_EditorTagPopupQuestDD")
    local okBtn = getglobal("GLV_EditorTagPopupOK")

    -- Reset
    if f1Box then f1Box:SetText(""); f1Box:Show() end
    if f2Box then f2Box:SetText(""); f2Box:Show() end
    if f2Label then f2Label:Show() end
    if preview then preview:SetText("") end
    if questDD then questDD:Hide() end

    -- Configure based on tag type
    if tagType == "QA" or tagType == "QC" or tagType == "QT" then
        titleText:SetText("Insert [" .. tagType .. "] tag")
        f1Label:SetText("Quest ID:")
        if tagType == "QC" then
            f2Label:SetText("Obj index:")
            f2Label:Show()
            f2Box:Show()
        else
            f2Label:Hide()
            f2Box:Hide()
        end

        -- Show quest log dropdown
        questDD:Show()
        popup:SetHeight(195)
        UIDropDownMenu_Initialize(questDD, function()
            -- Raise DropDownList1 above TOOLTIP strata so it's clickable over the popup
            local ddList = getglobal("DropDownList1")
            if ddList then ddList:SetFrameStrata("TOOLTIP") end
            local numEntries = GetNumQuestLogEntries()
            for i = 1, numEntries do
                local title, level, tag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i)
                if title and not isHeader then
                    local info = {}
                    info.text = "[" .. (level or "?") .. "] " .. title
                    info.func = function()
                        -- Try to find quest ID
                        local qid = GLV:GetQuestIDByName(title)
                        if qid and f1Box then
                            f1Box:SetText(tostring(qid))
                        end
                        if preview then
                            preview:SetText("|cFFAAAAAA" .. title .. (qid and " (ID: " .. qid .. ")" or "") .. "|r")
                        end
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end
        end)

        -- OnTextChanged for ID preview
        f1Box:SetScript("OnTextChanged", function()
            local id = this:GetText()
            if id and id ~= "" then
                local qname = GLV:GetQuestNameByID(id)
                if preview then
                    preview:SetText("|cFFAAAAAA" .. qname .. "|r")
                end
            end
        end)

        okBtn:SetScript("OnClick", function()
            local id = f1Box:GetText() or ""
            if id == "" then popup:Hide(); return end
            local editBox = getglobal("GLV_EditorEditBox")
            if tagType == "QC" then
                local obj = f2Box:GetText() or ""
                if obj ~= "" then
                    Editor:InsertTag(editBox, "[QC" .. id .. "," .. obj .. "] ")
                else
                    Editor:InsertTag(editBox, "[QC" .. id .. "] ")
                end
            else
                Editor:InsertTag(editBox, "[" .. tagType .. id .. "] ")
            end
            popup:Hide()
        end)

    elseif tagType == "TAR" then
        titleText:SetText("Insert [TAR] tag")
        f1Label:SetText("NPC ID:")
        f2Label:SetText("Search:")
        f2Label:Show()
        f2Box:Show()
        f2Box:SetText("")
        popup:SetHeight(195)
        questDD:Show()

        -- ID field → preview NPC name
        f1Box:SetScript("OnTextChanged", function()
            local id = this:GetText()
            if id and id ~= "" then
                local name = GLV:getTargetName(id)
                if preview then
                    preview:SetText("|cFFAAAAAA" .. (name or "Unknown") .. "|r")
                end
            else
                if preview then preview:SetText("") end
            end
        end)

        -- Search field → populate dropdown with matching NPCs
        UIDropDownMenu_Initialize(questDD, function()
            local ddList = getglobal("DropDownList1")
            if ddList then ddList:SetFrameStrata("TOOLTIP") end
            local searchText = f2Box:GetText() or ""
            if string.len(searchText) < 2 then return end
            local lowerSearch = string.lower(searchText)
            local Localized = VGDB and VGDB["units"] and (VGDB["units"]["enUS"] or VGDB["units"]["enGB"])
            if not Localized then return end
            local results = {}
            for npcId, npcName in pairs(Localized) do
                if type(npcName) == "string" and string.find(string.lower(npcName), lowerSearch, 1, true) then
                    table.insert(results, {id = npcId, name = npcName})
                    if table.getn(results) >= 20 then break end
                end
            end
            table.sort(results, function(a, b) return a.name < b.name end)
            for _, r in ipairs(results) do
                local info = {}
                info.text = r.name .. "  |cFF888888(" .. r.id .. ")|r"
                local capturedId = r.id
                local capturedName = r.name
                info.func = function()
                    if f1Box then f1Box:SetText(tostring(capturedId)) end
                    if preview then
                        preview:SetText("|cFFAAAAAA" .. capturedName .. " (ID: " .. capturedId .. ")|r")
                    end
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        -- Refresh dropdown when search text changes
        f2Box:SetScript("OnTextChanged", function()
            local searchText = this:GetText() or ""
            if string.len(searchText) >= 2 then
                UIDropDownMenu_SetText("Select NPC...", questDD)
                ToggleDropDownMenu(1, nil, questDD)
            end
        end)

        okBtn:SetScript("OnClick", function()
            local id = f1Box:GetText() or ""
            if id == "" then popup:Hide(); return end
            local editBox = getglobal("GLV_EditorEditBox")
            Editor:InsertTag(editBox, "[TAR" .. id .. "] ")
            popup:Hide()
        end)

    elseif tagType == "CI" then
        titleText:SetText("Insert [CI] tag")
        f1Label:SetText("Item ID:")
        f2Label:SetText("Count:")
        f2Label:Show()
        f2Box:Show()
        f2Box:SetText("1")
        popup:SetHeight(130)
        questDD:Hide()

        f1Box:SetScript("OnTextChanged", function()
            local id = this:GetText()
            if id and id ~= "" then
                local name = GLV:GetItemNameById(tonumber(id))
                if preview then
                    preview:SetText("|cFFAAAAAA" .. (name or "Unknown") .. "|r")
                end
            end
        end)

        okBtn:SetScript("OnClick", function()
            local id = f1Box:GetText() or ""
            local count = f2Box:GetText() or "1"
            if id == "" then popup:Hide(); return end
            local editBox = getglobal("GLV_EditorEditBox")
            Editor:InsertTag(editBox, "[CI" .. id .. "," .. count .. "] ")
            popup:Hide()
        end)

    elseif tagType == "UI" then
        titleText:SetText("Insert [UI] tag")
        f1Label:SetText("Item ID:")
        f2Label:Hide()
        f2Box:Hide()
        popup:SetHeight(130)
        questDD:Hide()

        f1Box:SetScript("OnTextChanged", function()
            local id = this:GetText()
            if id and id ~= "" then
                local name = GLV:GetItemNameById(tonumber(id))
                if preview then
                    preview:SetText("|cFFAAAAAA" .. (name or "Unknown") .. "|r")
                end
            end
        end)

        okBtn:SetScript("OnClick", function()
            local id = f1Box:GetText() or ""
            if id == "" then popup:Hide(); return end
            local editBox = getglobal("GLV_EditorEditBox")
            Editor:InsertTag(editBox, "[UI" .. id .. "] ")
            popup:Hide()
        end)

    elseif tagType == "H" or tagType == "S" or tagType == "P" then
        local labels = {H = "Hearthstone [H]", S = "Bind Hearthstone [S]", P = "Flight Path [P]"}
        titleText:SetText("Insert " .. labels[tagType])
        f1Label:SetText("Location:")
        f2Label:Hide()
        f2Box:Hide()
        popup:SetHeight(120)
        questDD:Hide()
        f1Box:SetScript("OnTextChanged", nil)

        okBtn:SetScript("OnClick", function()
            local loc = f1Box:GetText() or ""
            local editBox = getglobal("GLV_EditorEditBox")
            if loc ~= "" then
                Editor:InsertTag(editBox, "[" .. tagType .. " " .. loc .. "] ")
            else
                Editor:InsertTag(editBox, "[" .. tagType .. "] ")
            end
            popup:Hide()
        end)

    elseif tagType == "LE" then
        titleText:SetText("Insert [LE SP] tag")
        f1Label:SetText("Spell ID:")
        f2Label:SetText("Search:")
        f2Label:Show()
        f2Box:Show()
        f2Box:SetText("")
        popup:SetHeight(195)
        questDD:Show()

        -- Build spell cache on first use
        BuildSpellCache()

        -- ID field → preview spell name
        f1Box:SetScript("OnTextChanged", function()
            local id = this:GetText()
            if id and id ~= "" then
                local name = GLV:getSpellName(id)
                if name and name ~= "UNKNOWN_SPELL" then
                    if preview then
                        preview:SetText("|cFFAAAAAA" .. name .. "|r")
                    end
                end
            else
                if preview then preview:SetText("") end
            end
        end)

        -- Search field → populate dropdown with matching spells
        UIDropDownMenu_Initialize(questDD, function()
            local ddList = getglobal("DropDownList1")
            if ddList then ddList:SetFrameStrata("TOOLTIP") end
            local searchText = f2Box:GetText() or ""
            if string.len(searchText) < 2 then return end
            local lowerSearch = string.lower(searchText)
            local results = {}
            for _, entry in ipairs(spellNameCache or {}) do
                if string.find(string.lower(entry.name), lowerSearch, 1, true) then
                    table.insert(results, entry)
                    if table.getn(results) >= 20 then break end
                end
            end
            table.sort(results, function(a, b)
                if a.name == b.name then return a.id < b.id end
                return a.name < b.name
            end)
            for _, r in ipairs(results) do
                local info = {}
                local display = r.name
                if r.rank and r.rank ~= "" then
                    display = display .. " (" .. r.rank .. ")"
                end
                info.text = display .. "  |cFF888888(" .. r.id .. ")|r"
                local capturedId = r.id
                local capturedName = r.name
                info.func = function()
                    if f1Box then f1Box:SetText(tostring(capturedId)) end
                    if preview then
                        preview:SetText("|cFFAAAAAA" .. capturedName .. " (ID: " .. capturedId .. ")|r")
                    end
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        -- Refresh dropdown when search text changes
        f2Box:SetScript("OnTextChanged", function()
            local searchText = this:GetText() or ""
            if string.len(searchText) >= 2 then
                UIDropDownMenu_SetText("Select spell...", questDD)
                ToggleDropDownMenu(1, nil, questDD)
            end
        end)

        okBtn:SetScript("OnClick", function()
            local id = f1Box:GetText() or ""
            if id == "" then popup:Hide(); return end
            local editBox = getglobal("GLV_EditorEditBox")
            Editor:InsertTag(editBox, "[LE SP " .. id .. "] ")
            popup:Hide()
        end)

    elseif tagType == "SK" then
        titleText:SetText("Insert [SK] tag")
        f1Label:SetText("Skill:")
        f2Label:SetText("Level:")
        f2Label:Show()
        f2Box:Show()
        popup:SetHeight(130)
        questDD:Hide()
        f1Box:SetScript("OnTextChanged", nil)

        -- Auto-fill skill name from skill list
        f1Box:SetText("")
        if preview then
            local skillList = {}
            for i = 1, GetNumSkillLines() do
                local skillName, header = GetSkillLineInfo(i)
                if skillName and not header then
                    table.insert(skillList, skillName)
                end
            end
            preview:SetText("|cFF888888Skills: " .. table.concat(skillList, ", ") .. "|r")
        end

        okBtn:SetScript("OnClick", function()
            local skill = f1Box:GetText() or ""
            local level = f2Box:GetText() or ""
            if skill == "" then popup:Hide(); return end
            local editBox = getglobal("GLV_EditorEditBox")
            Editor:InsertTag(editBox, "[SK " .. skill .. " " .. level .. "] ")
            popup:Hide()
        end)

    elseif tagType == "XP" then
        titleText:SetText("Insert [XP] tag")
        f1Label:SetText("Level:")
        f2Label:SetText("Percent (opt):")
        f2Label:Show()
        f2Box:Show()
        popup:SetHeight(130)
        questDD:Hide()
        f1Box:SetScript("OnTextChanged", nil)

        -- Auto-fill current level
        local playerLevel = UnitLevel("player") or 1
        f1Box:SetText(tostring(playerLevel))

        okBtn:SetScript("OnClick", function()
            local lvl = f1Box:GetText() or ""
            local pct = f2Box:GetText() or ""
            if lvl == "" then popup:Hide(); return end
            local editBox = getglobal("GLV_EditorEditBox")
            if pct ~= "" then
                Editor:InsertTag(editBox, "[XP" .. lvl .. "-" .. pct .. "] ")
            else
                Editor:InsertTag(editBox, "[XP" .. lvl .. "] ")
            end
            popup:Hide()
        end)

    elseif tagType == "A" then
        titleText:SetText("Insert [A] tag")
        f1Label:SetText("Class/Race:")
        f2Label:Hide()
        f2Box:Hide()
        popup:SetHeight(120)
        questDD:Hide()
        f1Box:SetScript("OnTextChanged", nil)

        -- Suggest player's class
        local _, playerClass = UnitClass("player")
        local _, playerRace = UnitRace("player")
        if preview then
            preview:SetText("|cFF888888You: " .. (playerRace or "?") .. " " .. (playerClass or "?") .. "|r")
        end

        okBtn:SetScript("OnClick", function()
            local val = f1Box:GetText() or ""
            if val == "" then popup:Hide(); return end
            local editBox = getglobal("GLV_EditorEditBox")
            Editor:InsertTag(editBox, "[A " .. val .. "] ")
            popup:Hide()
        end)
    end

    popup:Show()
    if f1Box then f1Box:SetFocus() end
end


-- ============================================================================
-- INITIALIZATION (builds entire UI)
-- ============================================================================

function GLV_Editor_Initialize()
    local frame = CreateEditorFrame()
    CreateMetadataFields(frame)

    local toolbarY = -(30 + METADATA_HEIGHT)
    CreateToolbar(frame, toolbarY)

    local editAreaY = toolbarY - TOOLBAR_HEIGHT
    CreateEditArea(frame, editAreaY)

    CreateBottomBar(frame)

    -- Initialize dropdowns
    GLV_Editor_RefreshSavedDropdown()
    GLV_Editor_RefreshImportDropdown()

    -- Restore last open guide
    local lastGuide = Editor:GetLastOpenGuide()
    if lastGuide then
        GLV_Editor_LoadSavedGuide(lastGuide)
    end
end

-- Call initialization when the frame is first needed
-- Use Lua flag (resets on /reload) so editor reinitializes properly
local editorInitialized = false
local originalToggle = Editor.Toggle
function Editor:Toggle()
    if not editorInitialized then
        GLV_Editor_Initialize()
        editorInitialized = true
    else
        -- Refresh import dropdown each time (packs may have loaded since init)
        GLV_Editor_RefreshImportDropdown()
    end
    originalToggle(self)
end
