# Technology Stack

**Analysis Date:** 2026-02-09

## Languages

**Primary:**
- Lua 5.0 - WoW 1.12 addon scripting language (no modern Lua features like `#` operator, use `table.getn()`)

**Markup:**
- XML 1.0 - UI frame definitions (WoW FrameXML)

## Runtime

**Environment:**
- World of Warcraft Classic 1.12 (Turtle WoW private server)
- Interface version: 11200

**Constraints:**
- Lua 5.0 (pre-5.1): Use `table.getn()` not `#`, `string.gfind()` not `string.gmatch()`, `string.find()` for pattern matching, `getglobal()` for dynamic frame access
- WoW 1.12 UI limitations: No inline textures (`|Tpath:size|t` escape sequence not supported), limited escape sequences (only `|cAARRGGBB` for color and `|r` for reset), frame methods in scheduled events may fail (use existence/height checks instead of `IsShown()`)

## Frameworks

**Core:**
- LibStub - Addon library registration and loading system
- AceLibrary 2.0 - Ace framework base (AceAddon-2.0, AceConsole-2.0, AceDB-2.0, AceHook-2.1, AceEvent-2.0, AceOO-2.0)

**Routing/Navigation:**
- Astrolabe - Coordinate calculation and mapping library (ported from TomTom, provides coordinate system for minimap/world map rendering)

## Key Dependencies

**Critical:**
- LibStub v1 - Module registration and global library access
  - Location: `Assets/libs/LibStub/LibStub.lua`
  - Used for: `local GLV = LibStub("GuidelimeVanilla")`

**Framework/Infrastructure:**
- AceAddon-2.0 - Addon lifecycle management (OnInitialize, OnEnable)
  - Location: `Assets/libs/AceAddon-2.0/AceAddon-2.0.lua`
  - Why: Provides event system, database management, slash command registration

- AceEvent-2.0 - Event registration and handling
  - Location: `Assets/libs/AceEvent-2.0/AceEvent-2.0.lua`
  - Why: Hooks into WoW events (QUEST_DETAIL, PLAYER_XP_UPDATE, BAG_UPDATE, etc.)

- AceDB-2.0 - Character-specific database storage
  - Location: `Assets/libs/AceDB-2.0/AceDB-2.0.lua`
  - Why: Persists settings per character via SavedVariablesPerCharacter

- AceHook-2.1 - Function hooking for quest tracker and UI integration
  - Location: `Assets/libs/AceHook-2.1/AceHook-2.1.lua`
  - Why: Intercepts quest accept/complete/abandon actions

- AceConsole-2.0 - Slash command parsing
  - Location: `Assets/libs/AceConsole-2.0/AceConsole-2.0.lua`
  - Why: Provides `/glv` and `/guidelime` command system

- AceOO-2.0 - Object-oriented programming utilities
  - Location: `Assets/libs/AceOO-2.0/AceOO-2.0.lua`
  - Why: Used by other Ace libraries for class/mixin support

**Navigation/Mapping:**
- Astrolabe - Coordinate transformation for minimap/world map path rendering
  - Location: `Assets/libs/Astrolabe/Astrolabe.lua`
  - Why: Converts zone coordinates to minimap pixel positions, calculates distances between waypoints

## Data Storage

**In-Game Database (VGDB):**
- Embedded ShaguDB format quest/NPC/item/zone database
  - Quest data: `Assets/db/enUS/quests.lua` - Quest titles, descriptions, objectives, turn-in/accept NPC IDs
  - NPC data: `Assets/db/enUS/units.lua` - NPC locations by zone with x,y,z coordinates
  - Item data: `Assets/db/enUS/items.lua` - Item locations and drop sources
  - Zone data: `Assets/db/enUS/zones.lua` - Zone ID to name mappings
  - Object data: `Assets/db/objects.lua`, `Assets/db/areatrigger.lua` - Quest object locations
  - Locale: English US (enUS) - extensible to other locales via `Assets/db/enUS/` directory structure

- Data structure: Lua tables organized by ID with nested fields
  ```lua
  VGDB["quests"]["enUS"][questId] = {
    ["T"] = "Quest Title",
    ["O"] = "Objectives",
    ["D"] = "Description",
    ["start"] = {["U"] = {npcId}},  -- Quest giver NPC
    ["end"] = {["U"] = {npcId}}     -- Quest turn-in NPC
  }
  VGDB["units"]["data"][npcId] = {["coords"] = {{x, y, zoneId}, ...}}
  ```

**Character Settings (SavedVariablesPerCharacter):**
- Variable: `GuidelimeVanillaDB` - Character-specific settings via AceDB
- Scope: Per-character, persists across `/reload`
- Managed by: `GLV.Settings` object in `Settings.lua`
- Structure: Nested tables with access via `GLV.Settings:GetOption({"key", "path"})`
- Key settings:
  - `CharInfo` - Character name, realm, faction, race, class
  - `UI` - Window position, scale, text scale, navigation scale, frame strata
  - `Guide` - Active pack, current guide, current step, step state, visited NPC tracking
  - `QuestTracker` - Accepted/completed quests, objective tracking state
  - `Automation` - Auto-accept, auto-turnin, auto-flight flags
  - `Talents` - Active templates per class, respec state, toast position
  - `TaxiTracker` - Known taxi node IDs

## Configuration

**Environment:**
- No external environment variables required
- WoW API used at runtime: `GetRealmName()`, `UnitName()`, `UnitClass()`, `UnitRace()`, `UnitFactionGroup()`, `GetLocale()`
- Debug mode: Set `GLV.Debug = true` in `Core.lua` for verbose logging

**Initialization:**
- Addon loads in order: Libs (LibStub, Ace libs, Astrolabe) → DB (VGDB quests/units/items/zones) → Core logic → Frames → Talent templates
- Loading sequence in `.toc` file: `Assets\libs\libs.xml` → `Assets\db\initdb.xml` → `Core.lua` → `Settings.lua` → Helpers → Core modules → Frames → Talent templates

## Platform Requirements

**Development:**
- WoW Classic 1.12 client (Turtle WoW)
- Text editor or IDE for Lua/XML editing (no compilation required)
- Testing via `/reload` command in-game

**Production (Runtime):**
- WoW Classic 1.12 client
- Addon folder placed in: `Interface\AddOns\GuidelimeVanilla\`
- No external dependencies - all libraries bundled
- No internet connection required (all data embedded)

---

*Stack analysis: 2026-02-09*
