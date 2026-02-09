# Coding Conventions

**Analysis Date:** 2026-02-09

## Naming Patterns

**Files:**
- Module files use PascalCase with descriptive names: `GuideParser.lua`, `GuideNavigation.lua`, `GuideLibrary.lua`
- Event tracker files placed in subdirectory: `Core/Events/Quests.lua`, `Core/Events/Character.lua`, `Core/Events/Talents.lua`
- Talent templates by class: `TalentTemplates/Mage.lua`, `TalentTemplates/Warrior.lua`, etc.
- Frame definitions in XML files: `Frames/MainFrame.xml`, `Frames/SettingsFrame.xml`
- Helper utilities grouped: `Helpers/Helpers.lua`, `Helpers/DBTools.lua`, `Helpers/Colors.lua`

**Functions:**
- Global functions use PascalCase with GLV prefix for UI handlers: `GLV_ToggleSettings()`, `GLV_HideGuideFrame()`, `GLV_ShowGuideFrame()`
- Local module functions use camelCase: `onQuestDetail()`, `checkCollectItems()`, `updateWaypointForStep()`
- Object methods use colon notation: `self:Init()`, `self:OnPlayerXPUpdate()`, `self:GetQuestProgress()`
- Event handlers follow pattern: `OnEventName()` (e.g., `OnPlayerLogin()`, `OnZoneChanged()`)
- Helper functions with underscores for internal functions: `disablePfQuestNodes()`, `restorePfQuestNodes()`, `updatePfQuestState()`

**Variables:**
- Local module objects use PascalCase: `QuestTracker = {}`, `CharacterTracker = {}`, `MinimapPath = {}`
- Private state variables in modules use lowercase with underscores: `lastQuestLogUpdate`, `isMinimapEnabled`, `updateTimer`
- Settings keys use nested table arrays: `{"Guide", "ActivePack"}`, `{"UI", "FrameStrata"}`, `{"Automation", "AutoAcceptQuests"}`
- Local constants use UPPER_SNAKE_CASE: `NUM_DOTS`, `DOT_SIZE`, `DOT_COLOR`, `QUEST_LOG_UPDATE_THROTTLE`
- Cache tables use descriptive names: `store.Accepted`, `store.Completed`, `previousQuestStates`

**Types:**
- Event tracker tables: `QuestTracker`, `CharacterTracker`, `TaxiTracker`, `GossipTracker`, `EquipmentTracker`, `ItemTracker`, `TalentTracker`
- Navigation object: `GuideNavigation` (accessed as `GLV.GuideNavigation`)
- Minimap path object: `MinimapPath` (accessed as `GLV.MinimapPath`)
- Parser object: `Parser` (accessed as `GLV.Parser`)
- Settings object: `Settings` (accessed as `GLV.Settings`)
- Color definitions use fields: `{ r = value, g = value, b = value, a = value }`

## Code Style

**Formatting:**
- No explicit formatter detected - follows Lua 5.0 conventions
- 4-space indentation for code blocks
- Functions use descriptive multi-line bodies
- Comments use `--` for single lines and `--[[...]]--` for multi-line blocks
- Module header blocks follow pattern: Author, Description, blank line, module initialization

**Linting:**
- Not detected - no linting configuration found
- No enforced style rules beyond Lua 5.0 compatibility
- Follows WoW 1.12 API conventions (uses `table.getn()` instead of `#`, `string.gfind()` for pattern matching)

## Import Organization

**Order:**
1. Header comments (description, author)
2. `local _G = _G or getfenv(0)` (environment setup for Lua 5.0)
3. `local GLV = LibStub("GuidelimeVanilla")` (main addon object)
4. Module initialization: `local ModuleName = {}`
5. Assignment to GLV: `GLV.ModuleName = ModuleName`
6. Constants and configuration
7. Functions and methods
8. Event handlers

**Path Aliases:**
- No explicit path aliases detected
- Addon uses LibStub for global module access: `local GLV = LibStub("GuidelimeVanilla")`
- All modules registered on GLV global singleton: `GLV.QuestTracker`, `GLV.Parser`, `GLV.Settings`, etc.
- Settings accessed via nested key arrays: `Settings:GetOption({"Guide", "ActivePack"})`

**Example Import Pattern:**
```lua
--[[
Description
]]--
local _G = _G or getfenv(0)
local GLV = LibStub("GuidelimeVanilla")

local QuestTracker = {}
GLV.QuestTracker = QuestTracker

local CONFIG = {
    colors = { ... }
}
```

## Error Handling

**Patterns:**
- Defensive nil checks with early returns: `if not currentGuideId or not currentStepIndex then return {} end`
- Nested nil checks for safe property access: `if not coords or not coords.x or not coords.y then return end`
- Type checks before operations: `if type(str) == "string" then ... end`
- Safe string/table operations in helpers: `safe_strlen()`, `safe_sub()`, `safe_tablelen()`
- Settings initialization with fallback: checks `if not GLV.Ace or not GLV.Ace.db` and schedules retry
- No exceptions thrown - uses nil returns to signal failure

**Validation Pattern:**
```lua
function Module:GetData(questId)
    if not questId then return nil end

    local questData = database[questId]
    if not questData then return nil end

    if not questData.title or not questData.giver then
        return nil
    end

    return questData
end
```

**Settings Access Safety:**
```lua
function Settings:GetOption(keys)
    if not self.db then
        self:InitializeDB()
        if not self.db then return nil end
    end

    local profile = self.db.char
    if type(keys) ~= "table" then return nil end

    for i = 1, safe_tablelen(keys) do
        if profile == nil then return nil end
        profile = profile[keys[i]]
    end

    return profile
end
```

## Logging

**Framework:** `DEFAULT_CHAT_FRAME:AddMessage()` (WoW 1.12 chat API)

**Patterns:**
- Debug mode controlled by `GLV.Debug` flag (set in `Core.lua`)
- Messages use color-coded prefixes: `|cFF00FFFF[Module Name]|r Message text`
- Common prefixes: `[Guide Loading]`, `[Quest Sync]`, `[Quest Tracker]`, `[Items]`, `[GuideLime]`, `[GuideLime XP]`
- Info messages in cyan (`|cFF00FFFF`), warnings in yellow (`|cFFFFFF00`)
- Conditional logging only when `GLV.Debug == true`:

```lua
if GLV.Debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Module]|r " .. message)
end
```

**Debug Helpers:**
- `DumpTable(tbl, indent)` in `Helpers/Helpers.lua` - prints table contents recursively when `GLV.Debug` is true
- Slash command `/glvminimap` triggers `MinimapPath:DebugDump()` for navigation path debugging

## Comments

**When to Comment:**
- Before each major function: describe purpose and parameters
- Complex algorithms: explain logic with inline comments (e.g., XP requirement calculations)
- Tag meanings documented in code: lists map tag codes to descriptions (e.g., `QA = "ACCEPT"`)
- Non-obvious WoW API usage explained: e.g., "ConfirmBinder hook for hearthstone bind detection"
- State machine transitions documented: event names and handler sequences

**JSDoc/TSDoc:**
- Not used - Lua 5.0 does not have standard documentation format
- Uses block comments for module descriptions:

```lua
--[[
Guidelime Vanilla - Minimap & World Map Path

Author: Grommey

Description:
Draws a dotted path on the minimap and/or world map from the player position
toward the navigation waypoint.
]]--
```

**Function Documentation:**
```lua
-- Initialize quest tracking, hook original functions and register event handlers
function QuestTracker:Init()
    ...
end

-- Get quest progress text for display (full objectives on separate lines)
function QuestTracker:GetQuestProgress(questId)
    ...
end
```

## Function Design

**Size:** Functions range from 5-50 lines for most utilities, larger functions (100+ lines) reserved for complex logic like parser functions and event handlers

**Parameters:**
- Module methods use `self` as first parameter via colon notation: `function Module:Method(param1, param2)`
- Multiple related parameters grouped in tables: `{tree, row, col}` for talent positions
- Nested keys for settings passed as arrays: `{"Guide", "Guides", guideId, "StepState"}`
- Event handlers typically receive no explicit parameters (use closure to access module state)

**Return Values:**
- Single return value is common: `return bestGuide` or `return nil`
- Multiple returns for status/result pairs: `return objectives, allComplete, numObjectives`
- Boolean true/false for completion states: `stepState[origIdx] = true`
- Empty table `{}` for "no result" rather than nil in some query functions

**Error Return Pattern:**
```lua
function Module:GetStatus()
    if not self.initialized then
        return nil  -- Signal failure
    end
    return statusValue
end
```

## Module Design

**Exports:**
- Modules export via global GLV singleton: `GLV.QuestTracker = QuestTracker` makes module public
- Public module object: `local QuestTracker = {}; GLV.QuestTracker = QuestTracker`
- Internal functions remain local: `local function disablePfQuestNodes() ... end`
- Public methods exposed via table: `function QuestTracker:Init() ... end`

**Barrel Files:**
- Not used - each module is loaded separately in `GuidelimeVanilla.toc`
- Loading order matters: Core systems load first (Core.lua, Settings.lua), then modules (Helpers, Core/*, Events/*)
- Main addon instance exported in Core.lua: `GLV.Addon = addon` (Ace2 instance)

**Module Initialization Pattern:**
```lua
function Module:Init()
    -- Set up state
    self.store = {}

    -- Register event handlers if GLV.Ace available
    if GLV.Ace then
        GLV.Ace:RegisterEvent("EVENT_NAME", function(params)
            self:OnEventName(params)
        end)
    end
end

-- Event handler
function Module:OnEventName(params)
    -- Handle event
end
```

**Inter-module Communication:**
- Via GLV global singleton: `GLV.QuestTracker.store`, `GLV.Settings:GetOption()`
- Event-driven updates: modules register event handlers that call other module methods
- Settings as shared state: all modules read/write via `GLV.Settings:GetOption()` and `GLV.Settings:SetOption()`
- Navigation updates: `GLV.GuideNavigation:UpdateWaypointForStep()`

## Lua 5.0 Compatibility

**Patterns used:**
- `table.getn(t)` instead of `#t` operator
- `string.gfind()` with fallback shimmed to `string.gmatch` if available
- `string.match()` implemented via `string.find()` with capture groups
- `table.unpack` shimmed from global `unpack`
- `getglobal(name)` for dynamic frame access (instead of `_G[name]`)
- `this` keyword in XML event handlers (not `self`)
- Frame API uses colon notation: `frame:SetWidth()`, `frame:GetChildren()`

**Safe Helper Functions:**
- `safe_strlen(str)` - type-safe string length
- `safe_sub(str, i, j)` - type-safe substring
- `safe_tablelen(t)` - count numeric keys in table
- `trim(str)` - remove whitespace (type-safe)
- `strsplit(delimiter, text)` - string split implementation

## WoW 1.12 API Patterns

**Frame Creation:**
- Use XML for static frames with event handlers
- Use `CreateFrame()` for dynamic frames in Lua
- Frame strata options: `BACKGROUND`, `LOW`, `MEDIUM`, `HIGH`, `DIALOG`
- Frame level for z-ordering within strata

**Global Access:**
- `_G["FrameName"]` for dynamic frame access
- `getglobal("FrameName")` alternative
- Frame names must be globally unique and start with addon prefix: `GLV_Main`, `GLV_Settings`

**Event Registration:**
- Via Ace2: `GLV.Ace:RegisterEvent("EVENT_NAME", callback)`
- Scheduled events: `GLV.Ace:ScheduleEvent(name, function, delay)`
- Repeating events: `GLV.Ace:ScheduleRepeatingEvent(name, function, interval)`
- Cancelling: `GLV.Ace:CancelScheduledEvent(name)`

**Hooks:**
- Via Ace2 AceHook: `GLV.Ace:Hook("OriginalFunctionName", hookFunction)`
- Used for quest dialogs, gossip frames, abandoning quests

---

*Convention analysis: 2026-02-09*
