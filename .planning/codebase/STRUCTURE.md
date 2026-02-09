# Codebase Structure

**Analysis Date:** 2026-02-09

## Directory Layout

```
GuideLimeVanilla/
├── Core.lua                            # Addon initialization, Ace2 setup, event listeners
├── Settings.lua                        # Settings manager with nested key access
├── GuidelimeVanilla.toc                # Addon manifest (interface version, dependencies, file load order)
│
├── Core/                               # Core gameplay logic
│   ├── GuideLibrary.lua                # Guide registration, pack management, dropdown population
│   ├── GuideParser.lua                 # Tag parsing, step extraction, XP requirement parsing
│   ├── GuideWriter.lua                 # Step UI rendering, checkboxes, highlighting, text scaling
│   ├── GuideNavigation.lua             # Arrow navigation, multi-waypoint sequencing, XP/next guide display
│   ├── MinimapPath.lua                 # Minimap/world map dotted path rendering, pfQuest integration
│   │
│   └── Events/                         # Event-driven step auto-completion modules
│       ├── Quests.lua                  # Quest accept/complete/turnin tracking, objective indices
│       ├── Character.lua               # XP/level tracking for [XP] steps, talent level-up
│       ├── Items.lua                   # Item collection tracking for [CI] tags
│       ├── Gossip.lua                  # NPC dialog, hearthstone bind/arrival for [H]/[S] tags
│       ├── Taxi.lua                    # Flight path tracking and auto-take for [F] tags
│       ├── Equipment.lua               # Equipment tracking (minimal)
│       └── Talents.lua                 # Talent suggestions, toast notifications, frame highlighting
│
├── Helpers/                            # Utility modules
│   ├── DBTools.lua                     # VGDB queries (quests, NPCs, items, zones)
│   ├── Colors.lua                      # Color palette definitions
│   └── Helpers.lua                     # General helper functions
│
├── Frames/                             # UI frame definitions and handlers
│   ├── MainFrame.xml                   # Guide window frame (320x400, movable, scroll content)
│   ├── SettingsFrame.xml               # Settings window (600x450, dark theme, card layout, left menu)
│   ├── TalentPopup.xml                 # Talent toast notification and highlight overlay
│   └── Frames.lua                      # UI functions (show/hide/toggle), event handlers, dropdown init
│
├── TalentTemplates/                    # Class-specific talent recommendation trees
│   ├── Warrior.lua
│   ├── Paladin.lua
│   ├── Hunter.lua
│   ├── Rogue.lua
│   ├── Priest.lua
│   ├── Shaman.lua
│   ├── Mage.lua
│   ├── Warlock.lua
│   └── Druid.lua
│
├── Assets/                             # External libraries and game databases
│   ├── libs/                           # Ace2 framework and helper libraries
│   │   ├── LibStub/                    # Module registration system
│   │   ├── AceLibrary/                 # Ace2 loader
│   │   ├── AceAddon-2.0/               # Addon lifecycle (OnInitialize, OnEnable)
│   │   ├── AceDB-2.0/                  # Database persistence
│   │   ├── AceEvent-2.0/               # Event registration and hooking
│   │   ├── AceHook-2.1/                # Function hook system
│   │   ├── AceConsole-2.0/             # Slash command system
│   │   ├── AceOO-2.0/                  # Object-oriented patterns
│   │   ├── Astrolabe/                  # Map coordinate system (Minimap/World map conversion)
│   │   └── libs.xml                    # Library load order manifest
│   │
│   ├── db/                             # ShaguDB database (quest/NPC/item/zone data)
│   │   ├── initdb.xml                  # Database load order
│   │   ├── quests.lua                  # Quest data (titles, objectives, turn-in NPCs)
│   │   ├── units.lua                   # NPC names and locations (x, y, zoneId)
│   │   ├── items.lua                   # Item locations and drop sources
│   │   ├── objects.lua                 # Game object (door, chest, etc.) locations
│   │   ├── zones.lua                   # Zone names and IDs
│   │   ├── areatrigger.lua             # Zone transition points
│   │   └── enUS/                       # English locale overrides
│   │       ├── quests.lua
│   │       ├── units.lua
│   │       ├── items.lua
│   │       └── zones.lua
│   │
│   └── images/                         # UI textures and icons
│
├── Textures/                           # Addon-specific textures
│   ├── NavArrows                       # Arrow animation frames (108 total for smooth rotation)
│   ├── closed_lock                     # Lock button textures
│   └── [other UI textures]
│
└── .planning/                          # GSD planning documents
    └── codebase/
        ├── ARCHITECTURE.md
        └── STRUCTURE.md
```

## Directory Purposes

**Root (./):**
- Purpose: Addon entry point and main logic
- Contains: Initialization (Core.lua), settings system (Settings.lua), manifest (GuidelimeVanilla.toc)
- Key files: `Core.lua` (start here for understanding bootstrap), `Settings.lua` (state management), `.toc` (load order)

**Core/:**
- Purpose: Core gameplay systems (guide loading, parsing, UI, navigation, event tracking)
- Contains: Guide management, step rendering, navigation arrow, event-driven auto-completion
- Key files: `GuideLibrary.lua` (guide registration), `GuideParser.lua` (tag extraction), `GuideWriter.lua` (step UI), `GuideNavigation.lua` (arrow + waypoint logic)

**Core/Events/:**
- Purpose: Event handlers for game condition detection and step auto-completion
- Contains: Isolated modules for quest, XP, items, gossip, flight paths, talents
- Key files: `Quests.lua` (quest tracking), `Character.lua` (XP tracking), `Items.lua` (item collection), `Gossip.lua` (hearthstone/NPCs), `Talents.lua` (suggestions)

**Helpers/:**
- Purpose: Utility and database query functions
- Contains: VGDB lookups, color definitions, general helpers
- Key files: `DBTools.lua` (quest/NPC/item/zone queries)

**Frames/:**
- Purpose: UI frame definitions and event handlers
- Contains: XML frame definitions (Main, Settings, Talent toast), UI management functions
- Key files: `MainFrame.xml` (guide window), `SettingsFrame.xml` (settings window), `Frames.lua` (UI functions)

**TalentTemplates/:**
- Purpose: Class-specific talent recommendation data
- Contains: Pre-configured talent builds per class with level-by-level suggestions and optional respec support
- Key files: `*.lua` (one file per class: Warrior.lua, Mage.lua, etc.)

**Assets/libs/:**
- Purpose: External framework libraries for addon system, database, events
- Contains: Ace2 libraries (AceAddon, AceDB, AceEvent), LibStub, Astrolabe (map coordinates)
- Key files: `libs.xml` (load manifest), individual lib folders

**Assets/db/:**
- Purpose: Quest/NPC/item/zone data from ShaguDB for navigation and objective lookup
- Contains: Locale-specific quest titles, NPC locations, item locations, zone names
- Key files: `initdb.xml` (load manifest), `quests.lua`, `units.lua`, `items.lua`, `zones.lua`

**Assets/images/:**
- Purpose: Pre-generated assets (not used in current codebase, placeholder for future features)
- Contains: Unused image files
- Key files: None currently used

**Textures/:**
- Purpose: UI textures for navigation arrow animation and button icons
- Contains: Arrow animation frames (108 PNGs), lock button textures
- Key files: `NavArrows` directory (arrow animation sequence)

## Key File Locations

**Entry Points:**

- `Core.lua`: Addon bootstrap - `addon:OnInitialize()` and `addon:OnEnable()` entry points for Ace2 framework initialization
- `Settings.lua`: Settings system initialization - `Settings:InitializeDB()` called from Core.lua
- `GuidelimeVanilla.toc`: Addon manifest - specifies load order (libs first, then db, then Core, Helpers, Frames, Events)

**Configuration:**

- `GuidelimeVanilla.toc`: Interface version (11200 for WoW 1.12), addon title/version/author, file load order
- `.toc` file defines: `## SavedVariablesPerCharacter: GuidelimeVanillaDB` for per-character persistence
- No `.env` or external config files (all config stored in Ace2 database)

**Core Logic:**

- `Core/GuideLibrary.lua`: Guide registration API, pack management functions (`GetActiveGuidePack()`, `RegisterGuide()`, `PopulateDropdown()`)
- `Core/GuideParser.lua`: Tag extraction logic (`Parser:ParseGuide()`, `Parser:ParseExperienceRequirement()`)
- `Core/GuideWriter.lua`: Step rendering (`GuideWriter:CreateSteps()`, `GuideWriter:RefreshGuide()`)
- `Core/GuideNavigation.lua`: Arrow navigation (`GuideNavigation:UpdateWaypoint()`, arrow texture rotation, multi-waypoint sequencing)
- `Core/MinimapPath.lua`: Path rendering (`MinimapPath:UpdateMinimap()`, `MinimapPath:UpdateWorldMap()`, pfQuest integration)

**Testing:**

- No dedicated test files
- Debug mode: Set `GLV.Debug = true` in `Core.lua` for verbose logging to chat frame
- Manual testing: Load addon in WoW, use `/reload` to test changes, check chat messages

**Event Tracking:**

- `Core/Events/Quests.lua`: Quest completion hooks (`HookQuestAccept`, `HookQuestComplete`, QUEST_LOG_UPDATE handler)
- `Core/Events/Character.lua`: Level-up tracking (PLAYER_LEVEL_UP event, calls TalentTracker:OnLevelUp)
- `Core/Events/Items.lua`: BAG_UPDATE event handler for item collection completion
- `Core/Events/Gossip.lua`: Gossip NPC tracking, hearthstone bind/arrival detection (ConfirmBinder hook, SPELLCAST_STOP event)
- `Core/Events/Taxi.lua`: Flight path detection (GOSSIP_SHOW, TAXI_NODE_STATUS events)
- `Core/Events/Talents.lua`: Talent suggestions with respec phase detection

**Database:**

- `Assets/db/quests.lua`: Quest data structured as `VGDB.quests[locale][questId] = {T=title, .start=npcId, .end=npcId, .obj=objectives}`
- `Assets/db/units.lua`: NPC data structured as `VGDB.units.data[npcId] = {name, coords=[[x, y, zoneId], ...]}`
- `Assets/db/items.lua`: Item locations and drop sources
- `Assets/db/zones.lua`: Zone name translations by locale
- Accessed via `Helpers/DBTools.lua` helper functions

**UI:**

- `Frames/MainFrame.xml`: Guide window frame (320x400 pixels, centered, draggable, contains scroll frame for steps)
- `Frames/SettingsFrame.xml`: Settings window (600x450 pixels, dark theme, left menu tabs, card-based content areas)
- `Frames/TalentPopup.xml`: Toast notification and talent highlight overlay (fade animations, draggable, repositionable)
- `Frames/Frames.lua`: UI management functions (show/hide/toggle), dropdown initialization, display settings handlers

**Talent System:**

- `Core/Events/Talents.lua`: Main talent tracking module (level-up detection, phase transitions)
- `TalentTemplates/Warrior.lua` through `TalentTemplates/Druid.lua`: Class-specific talent trees (9 files, one per class)
- `Frames/TalentPopup.xml`: Toast frame definition (fade in/out, custom messages for respec)
- Settings: `{"Talents", "ActiveTemplate", class}`, `{"Talents", "RespecDone", class}`, `{"Talents", "ShowToast"}`, etc.

## Naming Conventions

**Files:**

- `*.lua`: Game logic, modules, helpers
- `*.xml`: UI frame definitions (WoW-specific XML format)
- `*.toc`: Addon manifest (exactly one per addon)
- Template files in `TalentTemplates/` use ClassName.lua (e.g., Mage.lua, Warrior.lua)

**Directories:**

- `Core/`: Core gameplay modules (no subdirs except Events)
- `Core/Events/`: Event-driven trackers (one module per game event type)
- `Helpers/`: Utility functions (prefixed with directory scope)
- `Frames/`: UI frame definitions and handlers (XML + Lua)
- `TalentTemplates/`: Class-specific data (no subdirs)
- `Assets/`: External libraries and databases (sorted by type: libs, db, images)

**Functions:**

- Global functions used in XML: `GLV_*` prefix (e.g., `GLV_ShowGuideFrame()`, `GLV_ToggleSettings()`, `GLV_OnMenuLeave()`)
- Module methods: `ModuleName:MethodName()` (e.g., `QuestTracker:Init()`, `GuideNavigation:UpdateWaypoint()`)
- Private functions: `local function_name()` (no global scope)
- Ace2 hooks: `Hook*` naming (e.g., `HookQuestAccept`, `HookQuestComplete`)

**Variables:**

- Global module: `GLV` (LibStub registered)
- Settings: `GLV.Settings` with nested key array access (e.g., `{"Guide", "CurrentGuide"}`)
- Database: `GLV.Ace.db.char` (underlying Ace2 database)
- State tables: `GLV.loadedGuides`, `GLV.CurrentDisplaySteps`, `GLV.TalentTemplates`, `GLV.DefaultTalentTemplates`

## Where to Add New Code

**New Feature (e.g., new automation tag):**

1. **Parser**: Add tag constant in `Core/GuideParser.lua` `codes` table (e.g., `NEW_FEATURE = "NEW_FEATURE"`)
2. **Event handler**: Create or modify module in `Core/Events/*.lua` to detect condition and call step completion
3. **UI**: If needed, add rendering in `Core/GuideWriter.lua` (e.g., special icons for new tag)
4. **Navigation**: If needs waypoint interaction, add to `Core/GuideNavigation.lua` display mode system
5. **Tests**: Manually test in WoW with debug mode enabled

**New Component/Module (e.g., new tracker type):**

1. **Create module file**: `Core/Events/NewTracker.lua`
2. **Follow pattern**: Copy structure from existing tracker (e.g., `Quests.lua`)
3. **Implement Init()**: Register events with `GLV.Ace:RegisterEvent()`
4. **Add to bootstrap**: Call `GLV.NewTracker:Init()` in `Core.lua` `addon:OnEnable()`
5. **Export to GLV**: Add `GLV.NewTracker = NewTracker` at module top

**Utilities (e.g., new helper function):**

- Shared utilities: Add to `Helpers/Helpers.lua`
- Database queries: Add to `Helpers/DBTools.lua` (wrap VGDB lookups)
- Color schemes: Add to `Helpers/Colors.lua`

**UI Enhancements (e.g., new settings option):**

1. **Add setting**: Define in `Settings.lua` defaults table (nested structure under appropriate key)
2. **Add frame**: Add UI elements in `Frames/SettingsFrame.xml` within appropriate card section
3. **Add handler**: Implement handler function in `Frames/Frames.lua` (e.g., `GLV_OnNewSettingChange()`)
4. **Apply change**: Load setting on addon init and apply immediately or on next guide load

**New Talent Template (new class or alternative build):**

1. **Create file**: `TalentTemplates/ClassName.lua`
2. **Copy structure**: Reference existing template (e.g., Mage.lua) for required format
3. **Register template**: Call `GLV:RegisterTalentTemplate(class, name, type, talents)` at file load
4. **Update defaults**: Add to `GLV.DefaultTalentTemplates[class]` in appropriate module

## Special Directories

**backup_2025-08-27_12-26-10/:**
- Purpose: Old backup of codebase from August 2025 (not active)
- Generated: Yes (manual backup, not auto-generated)
- Committed: Yes (tracked in git)
- Note: Ignore during development (old code, may have bugs)

**.planning/:**
- Purpose: GSD planning documents and orchestrator state
- Generated: Yes (created by GSD agents)
- Committed: Yes (planning docs committed to track project state)
- Contains: `codebase/` (ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, CONCERNS.md) and `plans/` (task breakdowns)

**.vs/:**
- Purpose: Visual Studio metadata (IDE cache, debug config)
- Generated: Yes (auto-generated by Visual Studio)
- Committed: No (should be in .gitignore)
- Note: Not used for development, safe to delete

**.claude/:**
- Purpose: Claude Code integration metadata (agents, plans)
- Generated: Yes (created by Claude agents)
- Committed: Yes (tracks agent state and execution history)

---

## Quick Navigation

| Need to... | Look at... |
|-----------|-----------|
| Understand addon lifecycle | `Core.lua` (OnInitialize, OnEnable) |
| Add a new automation tag | `Core/GuideParser.lua` (codes table) + `Core/Events/*.lua` (tracker) |
| Find quest data | `Assets/db/quests.lua` or `Helpers/DBTools.lua:GetQuestInfo()` |
| Find NPC locations | `Assets/db/units.lua` or `Helpers/DBTools.lua:FindClosestUnit()` |
| Render guide steps | `Core/GuideWriter.lua:CreateSteps()` |
| Show navigation arrow | `Core/GuideNavigation.lua:UpdateWaypoint()` |
| Change UI appearance | `Frames/SettingsFrame.xml` (layout) or `Frames/Frames.lua` (logic) |
| Track a new event | Create new file in `Core/Events/` following `Quests.lua` pattern |
| Add talent template | Create new file in `TalentTemplates/` or add to existing `Core/Events/Talents.lua` |
| Debug issue | Set `GLV.Debug = true` in `Core.lua`, check chat output with `/reload` |

