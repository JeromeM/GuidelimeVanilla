# Architecture

**Analysis Date:** 2026-02-09

## Pattern Overview

**Overall:** Modular event-driven architecture using Ace2 frameworks (AceAddon, AceEvent, AceDB) with LibStub module registration.

**Key Characteristics:**
- Single global module (`GLV`) accessible throughout addon via LibStub
- Event-driven tracker modules that hook game events and automation workflows
- Layered separation: Core parsing/navigation/UI, Event tracking, Database querying
- Settings-based state management persisting per-character
- Guide packs as external addon dependencies that register guides via `GLV:RegisterGuide()`

## Layers

**Initialization & Settings (Core):**
- Purpose: Bootstrap addon, initialize Ace2 framework, load per-character database
- Location: `Core.lua`, `Settings.lua`
- Contains: Addon startup hooks (OnInitialize, OnEnable), character info tracking, default settings structure
- Depends on: LibStub, AceLibrary, Ace2 modules (AceAddon, AceDB, AceEvent, AceHook)
- Used by: All other modules access GLV and Settings for state/persistence

**Guide Management (Core):**
- Purpose: Register guides from external packs, manage dropdown, load/unload guides, apply faction/race filters
- Location: `Core/GuideLibrary.lua`
- Contains: Guide registration API, pack management functions, dropdown population with multi-level submenu support, starting guide mapping per race
- Depends on: Settings (for active pack, faction/race filters)
- Used by: Guide Writer (UI), Guide Parser (during load), Guide packs (registration via `GLV:RegisterGuide()`)

**Guide Parsing (Core):**
- Purpose: Extract structured steps from guide text, parse tags ([QA], [G], [XP], etc.), generate step metadata
- Location: `Core/GuideParser.lua`
- Contains: Tag extraction logic, XP requirement parsing, multi-waypoint detection, item icon lookup with tooltip queries
- Depends on: VGDB (quest/item/NPC database)
- Used by: Guide Writer (UI creation), Guide Navigation (multi-waypoint sequencing)

**UI Rendering (Core):**
- Purpose: Display guide steps with step highlighting, XP progress, ongoing pinned steps, scale/text customization
- Location: `Core/GuideWriter.lua`
- Contains: Frame creation for steps/lines/checkboxes, highlighting system, text scaling, ongoing step manager
- Depends on: Parser (step structure), Settings (text scale preference), Character Tracker (XP display for ongoing steps only)
- Used by: Main guide window, Quest/Character/Item tracking callbacks

**Navigation & Pathfinding (Core):**
- Purpose: Display directional arrow to waypoint, handle multi-waypoint auto-advancement, guide chaining with [NX] tags, XP progress bar for active steps, next guide button
- Location: `Core/GuideNavigation.lua`
- Contains: Astrolabe-based arrow rotation, multi-waypoint sequencing (auto-advance at 5 yard distance), visited NPC persistence, frame scaling, XP/Hearthstone/Equip item display modes
- Depends on: Astrolabe (map coordinates), Settings (navigation scale, visited TAR state)
- Used by: Quest/Character/Gossip trackers (waypoint updates), MinimapPath (current waypoint data), Core.lua (zone change refresh)

**Minimap & World Map Paths (Core):**
- Purpose: Draw dotted paths on minimap (8 dots) and world map (12 dots) toward active waypoint
- Location: `Core/MinimapPath.lua`
- Contains: Dot pool management, Astrolabe coordinate conversion, pfQuest node integration/disabling, update loop (0.15s interval), world map zone detection
- Depends on: Astrolabe (coordinates), Settings (path enable/disable flags), Guide Navigation (current waypoint data)
- Used by: Settings UI (toggle handlers), Guide Navigation (waypoint queries)

**Event Trackers (Core/Events/):**
- Purpose: Hook game events and handle step auto-completion when conditions are met
- Modules:
  - `Quests.lua`: Quest accept/complete/turnin detection via QUEST_DETAIL/QUEST_COMPLETE/QUEST_LOG_UPDATE; auto-accept/turnin automation; objective index tracking
  - `Character.lua`: XP/level tracking for [XP] steps; talent suggestions (calls TalentTracker:OnLevelUp)
  - `Items.lua`: BAG_UPDATE hook for [CI] collect item auto-completion
  - `Gossip.lua`: NPC dialog tracking for auto-turnins; hearthstone bind/arrival detection for [H]/[S] steps; ConfirmBinder hook
  - `Taxi.lua`: Flight path auto-taking for [F] tags; GOSSIP_SHOW/TAXI_NODE_STATUS hooks
  - `Equipment.lua`: Equipment tracking (minimal implementation)
  - `Talents.lua`: Talent suggestion system with level-up toast notifications and talent frame highlighting
- Location: `Core/Events/*.lua`
- Contains: Ace2 event registration, throttling logic, step validation (only current step checked to prevent duplicates), state storage
- Depends on: Settings (current step, automation flags, step completion state), VGDB (NPC lookup for coordinates)
- Used by: Guide Writer (refresh on completion), Character Tracker (XP display refresh)

**Talent Suggestion System (Events & UI):**
- Purpose: Provide class-specific talent recommendations on level-up with toast notifications and talent frame highlighting
- Location: `Core/Events/Talents.lua`, `TalentTemplates/*.lua`, `Frames/TalentPopup.xml`
- Contains: Template registration per class, respec support (phase transitions), toast animation, talent frame detection and highlighting, level-up tracking
- Depends on: Settings (active template, respec state, toast position), Character Tracker (level-up event)
- Used by: Settings UI (template selection, move toast button), Character Tracker event handler

**Database Querying (Helpers):**
- Purpose: Query VGDB for quest/NPC/item/zone data; find coordinates for navigation objectives
- Location: `Helpers/DBTools.lua`
- Contains: Quest lookup (by ID or name), NPC coordinate queries (closest unit in zone), item location lookups, zone name translations
- Depends on: VGDB (ShaguDB format: quests, units, items, zones, areatriggers)
- Used by: Guide Navigation (objective coordinates), Quest Tracker (NPC lookup), Guide Parser (item icon fetch)

**Utilities (Helpers):**
- Purpose: Color definitions and general helper functions
- Location: `Helpers/Colors.lua`, `Helpers/Helpers.lua`
- Contains: Color palettes for UI, text formatting utilities
- Depends on: None
- Used by: Guide Writer, UI frames

**UI Frames & Settings (Frames):**
- Purpose: Main guide window, settings window, talent toast notification, frame state management
- Location: `Frames/Frames.lua`, `Frames/MainFrame.xml`, `Frames/SettingsFrame.xml`, `Frames/TalentPopup.xml`
- Contains: UI functions (show/hide/toggle), display settings change tracking, reload confirmation, frame strata application, checkbox font initialization, dropdown initialization, tooltip management, talent toast positioning
- Depends on: Settings (UI state, display options), Guide Writer (scroll frame child for steps)
- Used by: Core.lua (frame setup), Event handlers (refresh/hide calls), Settings interactions (handlers)

## Data Flow

**Guide Load Flow:**

1. External guide pack addon loads and calls `GLV:RegisterGuide(text, "Pack Name")`
2. Guide registered in `GLV.loadedGuides["Pack Name"][guideId]` with parsed metadata (name, level range, faction filter)
3. User selects pack in Settings > Guides and clicks Load
4. `GLV:PopulateDropdown()` builds main dropdown from `GLV.loadedGuides[activePack]`, filtered by player faction/race
5. User selects guide from dropdown
6. `GLV:LoadGuide()` calls `Parser:ParseGuide()` to extract steps
7. `GuideWriter:CreateSteps()` builds UI frames for each step with checkboxes and icons
8. `GuideNavigation:Init()` displays arrow to first waypoint
9. `MinimapPath:Init()` creates dot pools and starts update loop

**Step Completion Flow:**

1. Event fires (quest accept, item collected, hearthstone arrived, etc.)
2. Event handler in `Core/Events/*.lua` detects change via game API query
3. Handler calls `GLV.CurrentDisplaySteps` validation to check if current step condition is met
4. If condition matched: `StepState[origIdx]` marked complete in Settings, `GuideWriter:RefreshGuide()` called
5. Active step highlighted changes to next uncompleted step
6. Navigation arrow updates to next waypoint (or switches to XP progress bar if [XP] tag)
7. Any ongoing steps (pinned with [O] tag) remain visible at top

**Multi-Waypoint Navigation Flow:**

1. Current step contains multiple [G] or [TAR] tags
2. `GuideNavigation:UpdateWaypointForStep()` extracts all waypoints into `allWaypoints[]`
3. Navigation displays arrow to `allWaypoints[currentWaypointIndex]`
4. Player moves toward waypoint
5. On every update frame (0.02s), distance to current waypoint checked against `WAYPOINT_REACH_DISTANCE` (5 yards)
6. When reached: `currentWaypointIndex` incremented, arrow updates to next waypoint
7. When all waypoints exhausted: step auto-completes or transitions to quest objectives (if [QC]/[QT] tags present)

**Event-Driven Tracker Pattern (all Event modules):**

1. Event handler registers via `GLV.Ace:RegisterEvent()`
2. On event fire: validate only `currentStep` (not all uncompleted steps) to prevent multi-trigger
3. Query game API (quest log, bag inventory, hearthstone bind location) to detect change
4. If condition matches current step: update Settings and call `GLV:RefreshGuide()`
5. Throttling/delays applied to prevent redundant checks (e.g., 0.5s quest log throttle, 1.0s hearthstone delay)

**State Management:**

Settings structure:
- `{"Guide", "ActivePack"}` - Currently selected pack name
- `{"Guide", "CurrentGuide"}` - Currently loaded guide ID
- `{"Guide", "Guides", guideId, "CurrentStep"}` - Active step index
- `{"Guide", "Guides", guideId, "StepState"}` - Completion state per step: `{[stepIdx] = true}` for completed
- `{"Guide", "Guides", guideId, "VisitedTARs", stepIdx}` - Persistent TAR NPC tracking: `{[npcId] = true}`
- `{"QuestTracker", "Accepted"}` - Quests in log: `{[questId] = questTitle}`
- `{"Automation", "*"}` - Auto-accept/turnin/flight flags (boolean)
- `{"UI", "*"}` - Scale, text scale, path toggles, frame strata, frame position
- `{"Talents", "*"}` - Enabled, active template, respec state, toast position

## Key Abstractions

**GLV (Global Module):**
- Purpose: Single entry point for all addon functions, registered via LibStub for external packs
- Examples: `GLV:RegisterGuide()`, `GLV:LoadGuide()`, `GLV:GetActiveGuidePack()`, `GLV.Settings`, `GLV.GuideNavigation`
- Pattern: Namespaced module with nested submodules for trackers (QuestTracker, CharacterTracker, etc.)

**Settings System:**
- Purpose: Nested key-based access to per-character database without Ace2 API calls
- Examples: `Settings:GetOption({"Guide", "Guides", id, "StepState"})`, `Settings:SetOption(value, path)`
- Pattern: Wrapper around `GLV.Ace.db.char` with default merging and nested table safety

**Event Trackers:**
- Purpose: Isolated modules that detect specific game conditions and auto-complete steps
- Examples: `QuestTracker`, `CharacterTracker`, `ItemTracker`, `GossipTracker`
- Pattern: `{Init(), private event handlers, public validation methods}` with local state

**Waypoint Objects:**
- Purpose: Represent navigation destination with metadata for smart transitions
- Structure: `{type="quest"|"npc", x, y, zoneId, npcId, questId, actionType, currentObjectiveIndex}`
- Used by: Navigation for arrow display, MinimapPath for dot positioning, Quest Tracker for objective filtering

**Guide Metadata:**
- Purpose: Cached parsed guide structure avoiding re-parsing on every load
- Structure: `{name, minLevel, maxLevel, faction, steps=[{text, tags={}, isCompletionStep, lines=[]}]}`
- Stored in: `GLV.loadedGuides[packName][guideId]`

## Entry Points

**Addon Initialization:**
- Location: `Core.lua` -> `addon:OnInitialize()` -> `addon:OnEnable()`
- Triggers: WoW addon load sequence
- Responsibilities: Settings init, Ace2 framework setup, slash command registration, event tracker initialization (delayed 2.0s-2.5s for Navigation/MinimapPath)

**Main Guide Window:**
- Location: `Frames/MainFrame.xml` -> `GLV_Main` frame
- Triggers: `/glv show`, user interaction, auto-load on login
- Responsibilities: Display steps, manage scroll frame, handle checkbox clicks, show step descriptions

**Settings Window:**
- Location: `Frames/SettingsFrame.xml` -> `GLV_Settings` frame
- Triggers: `/glv settings`, settings button click
- Responsibilities: Pack selection/loading, automation toggles, display preferences (scale, paths, frame strata), talent template selection, move toast notification

**Guide Pack Registration (External):**
- Location: External addon `init.lua` calls `GLV:RegisterGuide(guideText, "Pack Name")`
- Triggers: External addon load
- Responsibilities: None - GLV handles registration into `GLV.loadedGuides`

**Event Handlers (Automatic):**
- Location: `Core/Events/*.lua` -> `Tracker:Init()` registers handlers
- Triggers: Game events (QUEST_DETAIL, BAG_UPDATE, QUEST_LOG_UPDATE, ZONE_CHANGED_NEW_AREA, PLAYER_LEVEL_UP, etc.)
- Responsibilities: Detect conditions, validate step, trigger auto-completion

**Navigation Updates:**
- Location: `Core/GuideNavigation.lua` -> Update frame script (OnUpdate)
- Triggers: Every 0.02s (50 FPS)
- Responsibilities: Rotate arrow texture toward waypoint, calculate distance, check if waypoint reached

**Minimap Path Updates:**
- Location: `Core/MinimapPath.lua` -> Update frame script (OnUpdate)
- Triggers: Every 0.15s (6.67 FPS) when minimap or world map paths enabled
- Responsibilities: Calculate dot positions along path from player to waypoint, update frame positions

## Error Handling

**Strategy:** Graceful degradation with fallbacks and error suppression via nil checks.

**Patterns:**
- Nil checks before table access: `if GLV.CurrentDisplaySteps and GLV.CurrentDisplaySteps[currentStep] then`
- Fallback defaults in Settings access: `GetOption(path) or defaultValue`
- Safe frame lookups: `local frame = _G["FrameName"]` with existence checks before method calls
- Try-catch via scheduled events: Errors in event handlers logged but don't crash addon (Ace2 event system handles)
- VGDB fallbacks: If database queries fail, navigation falls back to manual player positioning

## Cross-Cutting Concerns

**Logging:**
- Debug mode: `GLV.Debug = true` in Core.lua enables verbose messages
- Chat output: Uses `DEFAULT_CHAT_FRAME:AddMessage()` for all user-facing notifications
- Pattern: `if GLV.Debug then ... end` guards for development output

**Validation:**
- Step completion: Validate ONLY current step (Settings `CurrentStep` index) to prevent duplicate triggers
- Quest matching: Match by exact ID when available, fallback to name matching for untracked quests
- Objective filtering: When [QC id,objectiveIndex] used, filter coordinates by objective index

**Authentication:**
- None - addon is pure client-side, no external authentication
- Player identity: Stored from UnitName/UnitClass/UnitRace/UnitFactionGroup on login

**Performance:**
- Event throttling: Quest log updates throttled to 0.5s minimum interval
- Scheduled delays: Tracker inits delayed 1-2.5s after load to avoid race conditions
- Dot updates: Minimap path updates only every 0.15s (6.67 FPS) vs. navigation 0.02s
- Zone change debounce: 0.5s delay before navigation refresh after zone change

