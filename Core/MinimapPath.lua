--[[
Guidelime Vanilla - Minimap & World Map Path

Author: Grommey

Description:
Draws a dotted path on the minimap and/or world map from the player position
toward the navigation waypoint.

When either path is enabled, automatically disables pfQuest nodes to avoid
clutter, and restores them when both are disabled.
]]--

local GLV = LibStub("GuidelimeVanilla")

local MinimapPath = {}
GLV.MinimapPath = MinimapPath

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Minimap dots
local NUM_DOTS = 8
local DOT_SIZE = 2
local DOT_COLOR = { r = 0.6, g = 0.8, b = 1.0, a = 0.7 }
local START_OFFSET = 8

-- World map dots
local NUM_MAP_DOTS = 12
local MAP_DOT_SIZE = 3
local MAP_DOT_COLOR = { r = 0.5, g = 0.7, b = 1.0, a = 0.7 }

local UPDATE_INTERVAL = 0.15

-- ============================================================================
-- STATE
-- ============================================================================

local dots = {}            -- minimap dot pool
local mapDots = {}         -- world map dot pool
local isMinimapEnabled = false
local isWorldMapEnabled = false
local updateTimer = 0
local updateFrame = nil
local debugLastReason = nil

-- pfQuest saved state (to restore when both paths disabled)
local pfQuestSaved = nil

-- ============================================================================
-- PFQUEST INTEGRATION
-- ============================================================================

-- Config keys we manage (pfQuest_config is a SavedVariablesPerCharacter)
local PFQUEST_KEYS = {
    "minimapnodes", "showspawn", "showcluster",
    "showspawnmini", "showclustermini", "routes"
}

local function refreshPfMap()
    if not pfMap then return end
    if pfMap.UpdateMinimap then pfMap:UpdateMinimap() end
    if pfMap.UpdateNodes then pfMap:UpdateNodes() end
end

local function disablePfQuestNodes()
    if not pfQuest_config then return end
    if pfQuestSaved then return end  -- already disabled by us

    -- Validate keys and snapshot current values
    local snapshot = {}
    local wasEnabled = false
    for _, key in ipairs(PFQUEST_KEYS) do
        local val = pfQuest_config[key]
        if val == nil then
            if GLV.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[MinimapPath]|r pfQuest key missing: " .. key .. ", aborting integration")
            end
            return  -- unknown pfQuest version, abort safely
        end
        snapshot[key] = val
        if val == "1" then wasEnabled = true end
    end

    if not wasEnabled then return end

    -- Save snapshot to memory + persist to Settings (survives /reload)
    pfQuestSaved = snapshot
    GLV.Settings:SetOption(snapshot, {"Integration", "pfQuestSaved"})

    for _, key in ipairs(PFQUEST_KEYS) do
        pfQuest_config[key] = "0"
    end

    refreshPfMap()

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[MinimapPath]|r pfQuest nodes disabled (state saved)")
    end
end

local function restorePfQuestNodes()
    if not pfQuest_config or not pfQuestSaved then return end

    for _, key in ipairs(PFQUEST_KEYS) do
        if pfQuestSaved[key] ~= nil then
            pfQuest_config[key] = pfQuestSaved[key]
        end
    end

    refreshPfMap()

    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[MinimapPath]|r pfQuest nodes restored")
    end

    pfQuestSaved = nil
    GLV.Settings:SetOption(nil, {"Integration", "pfQuestSaved"})
end

-- Refresh pfQuest state based on current toggles and setting
local function updatePfQuestState()
    local hidePfQuest = GLV.Settings:GetOption({"Integration", "HidePfQuestNodes"})
    if hidePfQuest == nil then hidePfQuest = false end

    if hidePfQuest and (isMinimapEnabled or isWorldMapEnabled) then
        disablePfQuestNodes()
    else
        restorePfQuestNodes()
    end
end

-- Public wrapper so settings UI can trigger pfQuest state refresh
function MinimapPath:RefreshPfQuestState()
    updatePfQuestState()
end

-- ============================================================================
-- MINIMAP DOT POOL
-- ============================================================================

function MinimapPath:CreateMinimapDots()
    for i = 1, NUM_DOTS do
        local name = "GLV_MinimapDot" .. i
        -- Reuse existing frame on /reload to avoid orphaning the old one
        local dot = getglobal(name) or CreateFrame("Frame", name, Minimap)
        dot:SetWidth(DOT_SIZE)
        dot:SetHeight(DOT_SIZE)
        dot:SetFrameStrata("TOOLTIP")
        dot:SetFrameLevel(10)

        if not dot.tex then
            local tex = dot:CreateTexture(nil, "OVERLAY")
            tex:SetAllPoints(dot)
            dot.tex = tex
        end
        dot.tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        dot.tex:SetVertexColor(DOT_COLOR.r, DOT_COLOR.g, DOT_COLOR.b, DOT_COLOR.a)

        dot:Hide()
        dots[i] = dot
    end
end

-- ============================================================================
-- WORLD MAP DOT POOL
-- ============================================================================

function MinimapPath:CreateWorldMapDots()
    for i = 1, NUM_MAP_DOTS do
        local name = "GLV_WorldMapDot" .. i
        -- Reuse existing frame on /reload to avoid orphaning the old one
        local dot = getglobal(name) or CreateFrame("Frame", name, WorldMapButton)
        dot:SetWidth(MAP_DOT_SIZE)
        dot:SetHeight(MAP_DOT_SIZE)
        dot:SetFrameStrata("FULLSCREEN")
        dot:SetFrameLevel(10)

        if not dot.tex then
            local tex = dot:CreateTexture(nil, "OVERLAY")
            tex:SetAllPoints(dot)
            dot.tex = tex
        end
        dot.tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        dot.tex:SetVertexColor(MAP_DOT_COLOR.r, MAP_DOT_COLOR.g, MAP_DOT_COLOR.b, MAP_DOT_COLOR.a)

        dot:Hide()
        mapDots[i] = dot
    end
end

-- ============================================================================
-- MINIMAP UPDATE
-- ============================================================================

function MinimapPath:UpdateMinimap()
    if not GLV.GuideNavigation then
        debugLastReason = "no GuideNavigation"
        self:HideMinimapDots()
        return
    end
    if not GLV.GuideNavigation:IsArrowNavigationActive() then
        debugLastReason = "arrow not active"
        self:HideMinimapDots()
        return
    end

    local waypoint = GLV.GuideNavigation:GetCurrentWaypoint()
    if not waypoint then
        debugLastReason = "no waypoint"
        self:HideMinimapDots()
        return
    end

    local C, Z, pX, pY = Astrolabe:GetCurrentPlayerPosition()
    if not C or not Z then
        debugLastReason = "no player position"
        self:HideMinimapDots()
        return
    end

    if not waypoint.z then
        debugLastReason = "waypoint.z nil"
        self:HideMinimapDots()
        return
    end
    if Z ~= waypoint.z then
        debugLastReason = "zone mismatch (Z=" .. tostring(Z) .. " wp=" .. tostring(waypoint.z) .. ")"
        self:HideMinimapDots()
        return
    end

    local dist, xDelta, yDelta = Astrolabe:ComputeDistance(
        C, Z, pX, pY,
        waypoint.c, waypoint.z, waypoint.x, waypoint.y
    )
    if not dist or dist < 1 then
        debugLastReason = "dist too small"
        self:HideMinimapDots()
        return
    end

    local zoom = Minimap:GetZoom()
    local mapDiameter
    if Astrolabe.minimapOutside then
        mapDiameter = MinimapSize.outdoor[zoom]
    else
        mapDiameter = MinimapSize.indoor[zoom]
    end
    if not mapDiameter then
        debugLastReason = "no mapDiameter"
        self:HideMinimapDots()
        return
    end

    local mapWidth = Minimap:GetWidth()
    local mapHeight = Minimap:GetHeight()
    local xScale = mapDiameter / mapWidth
    local yScale = mapDiameter / mapHeight
    local mapRadius = mapWidth / 2

    local pixelX = xDelta / xScale
    local pixelY = -yDelta / yScale

    local totalPixelDist = math.sqrt(pixelX * pixelX + pixelY * pixelY)
    if totalPixelDist < START_OFFSET then
        debugLastReason = "too close"
        self:HideMinimapDots()
        return
    end

    local dirX = pixelX / totalPixelDist
    local dirY = pixelY / totalPixelDist

    local maxDist = math.min(totalPixelDist, mapRadius - 1)
    if maxDist <= START_OFFSET then
        debugLastReason = "too close for dots"
        self:HideMinimapDots()
        return
    end

    debugLastReason = "OK (dist=" .. string.format("%.0f", dist) .. "y)"

    local spacing = (maxDist - START_OFFSET) / (NUM_DOTS - 1)

    for i = 1, NUM_DOTS do
        local t = START_OFFSET + (i - 1) * spacing
        local dx = dirX * t
        local dy = dirY * t

        local dotDist = math.sqrt(dx * dx + dy * dy)
        if dotDist > (mapRadius - 1) then
            dots[i]:Hide()
        else
            dots[i]:ClearAllPoints()
            dots[i]:SetPoint("CENTER", Minimap, "CENTER", dx, dy)
            dots[i]:Show()
        end
    end
end

-- ============================================================================
-- WORLD MAP UPDATE
-- ============================================================================

function MinimapPath:UpdateWorldMap()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then
        self:HideWorldMapDots()
        return
    end

    if not GLV.GuideNavigation then
        self:HideWorldMapDots()
        return
    end

    local waypoint = GLV.GuideNavigation:GetCurrentWaypoint()
    if not waypoint or not waypoint.z then
        self:HideWorldMapDots()
        return
    end

    -- Check world map is showing the waypoint's zone
    local mapContinent = GetCurrentMapContinent()
    local mapZone = GetCurrentMapZone()
    if mapContinent ~= waypoint.c or mapZone ~= waypoint.z then
        self:HideWorldMapDots()
        return
    end

    -- Player position on current map (0-1)
    local px, py = GetPlayerMapPosition("player")
    if px == 0 and py == 0 then
        self:HideWorldMapDots()
        return
    end

    -- Waypoint position (already 0-1 in zone coords)
    local wx, wy = waypoint.x, waypoint.y

    -- Map pixel dimensions
    local bmWidth = WorldMapButton:GetWidth()
    local bmHeight = WorldMapButton:GetHeight()

    -- Convert to pixels
    local playerPx = px * bmWidth
    local playerPy = py * bmHeight
    local wpPx = wx * bmWidth
    local wpPy = wy * bmHeight

    local dx = wpPx - playerPx
    local dy = wpPy - playerPy
    local totalDist = math.sqrt(dx * dx + dy * dy)

    if totalDist < 5 then
        self:HideWorldMapDots()
        return
    end

    local dirX = dx / totalDist
    local dirY = dy / totalDist
    local spacing = totalDist / (NUM_MAP_DOTS + 1)

    for i = 1, NUM_MAP_DOTS do
        local t = i * spacing
        local dotX = playerPx + dirX * t
        local dotY = playerPy + dirY * t

        mapDots[i]:ClearAllPoints()
        mapDots[i]:SetPoint("CENTER", WorldMapButton, "TOPLEFT", dotX, -dotY)
        mapDots[i]:Show()
    end
end

-- ============================================================================
-- VISIBILITY CONTROL
-- ============================================================================

function MinimapPath:HideMinimapDots()
    for i = 1, NUM_DOTS do
        if dots[i] then dots[i]:Hide() end
    end
end

function MinimapPath:HideWorldMapDots()
    for i = 1, NUM_MAP_DOTS do
        if mapDots[i] then mapDots[i]:Hide() end
    end
end

function MinimapPath:EnableMinimap()
    isMinimapEnabled = true
    updatePfQuestState()
end

function MinimapPath:DisableMinimap()
    isMinimapEnabled = false
    self:HideMinimapDots()
    updatePfQuestState()
end

function MinimapPath:EnableWorldMap()
    isWorldMapEnabled = true
    updatePfQuestState()
end

function MinimapPath:DisableWorldMap()
    isWorldMapEnabled = false
    self:HideWorldMapDots()
    updatePfQuestState()
end

-- Legacy aliases (used by existing checkbox handler)
function MinimapPath:Enable()
    self:EnableMinimap()
end

function MinimapPath:Disable()
    self:DisableMinimap()
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function MinimapPath:DebugDump()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[MinimapPath Debug]|r ----")
    DEFAULT_CHAT_FRAME:AddMessage("  minimapEnabled: " .. tostring(isMinimapEnabled))
    DEFAULT_CHAT_FRAME:AddMessage("  worldMapEnabled: " .. tostring(isWorldMapEnabled))
    DEFAULT_CHAT_FRAME:AddMessage("  minimap dots: " .. tostring(table.getn(dots)))
    DEFAULT_CHAT_FRAME:AddMessage("  worldmap dots: " .. tostring(table.getn(mapDots)))
    if GLV.GuideNavigation then
        DEFAULT_CHAT_FRAME:AddMessage("  arrowActive: " .. tostring(GLV.GuideNavigation:IsArrowNavigationActive()))
        local wp = GLV.GuideNavigation:GetCurrentWaypoint()
        if wp then
            DEFAULT_CHAT_FRAME:AddMessage("  waypoint: c=" .. tostring(wp.c) .. " z=" .. tostring(wp.z) .. " x=" .. string.format("%.3f", wp.x or 0) .. " y=" .. string.format("%.3f", wp.y or 0))
        else
            DEFAULT_CHAT_FRAME:AddMessage("  waypoint: nil")
        end
    end
    local C, Z, pX, pY = Astrolabe:GetCurrentPlayerPosition()
    DEFAULT_CHAT_FRAME:AddMessage("  player: C=" .. tostring(C) .. " Z=" .. tostring(Z))
    DEFAULT_CHAT_FRAME:AddMessage("  lastReason: " .. tostring(debugLastReason))
    DEFAULT_CHAT_FRAME:AddMessage("  pfQuestSaved: " .. tostring(pfQuestSaved ~= nil))
    if pfQuest_config then
        local parts = {}
        for _, key in ipairs(PFQUEST_KEYS) do
            table.insert(parts, key .. "=" .. tostring(pfQuest_config[key]))
        end
        DEFAULT_CHAT_FRAME:AddMessage("  pfQuest: " .. table.concat(parts, " "))
    end
end

-- ============================================================================
-- SLASH COMMAND
-- ============================================================================

SLASH_GLVMINIMAP1 = "/glvminimap"
SlashCmdList["GLVMINIMAP"] = function()
    if GLV.MinimapPath and GLV.MinimapPath.DebugDump then
        GLV.MinimapPath:DebugDump()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[GuideLime]|r MinimapPath not loaded!")
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MinimapPath:Init()
    local minimapSetting = GLV.Settings:GetOption({"UI", "MinimapPath"})
    if minimapSetting == nil then minimapSetting = true end

    local worldmapSetting = GLV.Settings:GetOption({"UI", "WorldMapPath"})
    if worldmapSetting == nil then worldmapSetting = true end

    self:CreateMinimapDots()
    self:CreateWorldMapDots()

    -- Single OnUpdate frame drives both minimap and world map (reuse on /reload)
    updateFrame = getglobal("GLV_MinimapPathUpdateFrame") or CreateFrame("Frame", "GLV_MinimapPathUpdateFrame", UIParent)
    updateFrame:SetScript("OnUpdate", function()
        updateTimer = updateTimer + arg1
        if updateTimer >= UPDATE_INTERVAL then
            updateTimer = 0
            if isMinimapEnabled then
                MinimapPath:UpdateMinimap()
            end
            if isWorldMapEnabled then
                MinimapPath:UpdateWorldMap()
            end
        end
    end)

    if minimapSetting then
        isMinimapEnabled = true
    end
    if worldmapSetting then
        isWorldMapEnabled = true
    end

    -- Recover pfQuest snapshot from previous session (survives /reload)
    local persistedSnapshot = GLV.Settings:GetOption({"Integration", "pfQuestSaved"})
    if persistedSnapshot and pfQuest_config then
        pfQuestSaved = persistedSnapshot
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[MinimapPath]|r Recovered pfQuest snapshot from Settings")
        end
    end

    -- Single pfQuest update after both flags are set
    updatePfQuestState()

end
