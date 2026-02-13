# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

GuideLime Vanilla is a World of Warcraft Classic (1.12) addon providing an enhanced guide system with automatic quest tracking, autonomous navigation, and smart UI management. Port of Guidelime for Vanilla WoW (TurtleWoW private server). Supports embedded URLs in guide text with click-to-copy popup (workaround for WoW 1.12's lack of clickable hyperlinks).

## Development Environment

- **Target**: WoW Classic 1.12 (Turtle WoW)
- **Language**: Lua 5.0 (no `#` operator, no `string.gmatch`, use `table.getn()`, `string.gfind()`)
- **Testing**: `/reload` for existing file changes. New TOC entries require full game restart.
- **Debug Mode**: `GLV.Debug = true` in Core.lua

## IMPORTANT: Git Workflow

**NEVER forget to run the agents before pushing:**
1. `claude-md-updater` - After each commit to update CLAUDE.md
2. `readme-feature-sync` - Before pushing to sync README with implemented features
3. `version-bump-prepush` - Before pushing to increment the addon version

**Version bump rules:** 1-6 commits = patch Z, >6 commits = minor Y (reset Z)

## Architecture

### Module System

```
GLV = LibStub("GuidelimeVanilla")  -- Main addon object
GLV.Addon = AceAddon instance      -- Ace2 addon with events, hooks, console, DB
```

**Core modules** (on GLV namespace):
- `Settings` - Nested key access: `GetOption({"Guide", "CurrentGuide"})` / `SetOption(value, {...})`
- `Parser` - Guide text parser
- `QuestTracker` - Quest accept/complete/turnin tracking, quest sync via SyncQuestAcceptSteps. **Auto-accept/turnin currently disabled** (QUEST_DETAIL/QUEST_COMPLETE handlers commented out due to timing issues with rapid QT→QA sequences).
- `ItemTracker` - `[CI]` item collection tracking (BAG_UPDATE), checks ongoing steps via OngoingStepsManager
- `CharacterTracker` - XP/level tracking, spell/skill learning detection (`[LE]`), profession skill level tracking (`[SK]`)
- `TaxiTracker` - Flight path tracking and automation (`[F]`/`[P]`)
- `GossipTracker` - Gossip dialog, hearthstone bind/use detection (`[H]`/`[S]`)
- `TalentTracker` - Talent suggestions, level-up toasts, talent frame highlighting. Centralized TALENT_FRAMES table for multi-frame support (TalentFrame, TWTalentFrame, PlayerTalentFrame).
- `GuideNavigation` - **Orchestrator**: frame creation, arrow rendering, update loop, zone change handling (ZONE_CHANGED_NEW_AREA), delegates to NavigationModes and WaypointResolver
- `NavigationModes` - Display modes (equip, use item, hearthstone, next guide, XP bar, skill progress) + death/corpse navigation
- `WaypointResolver` - Coordinate resolution (7-priority system), quest status, step descriptions
- `MinimapPath` - Minimap/world map dotted path rendering, pfQuest integration. Uses `getglobal()` to reclaim existing named frames on `/reload` instead of creating orphans.

**Data objects**:
- `GLV.CurrentGuide` - Loaded guide (`.next` for chaining, `.clickToNext`)
- `GLV.CurrentDisplaySteps` / `CurrentDisplayStepsCount` / `CurrentDisplayToOriginal` - Step display state
- `GLV.loadedGuides[packName][guideId]` - All registered guides
- `GLV.TalentTemplates[class][templateName]` - Talent build templates

### Data Flow

1. Guide pack addon registers guides via `GLV:RegisterGuide(text, group)`
2. User selects pack in Settings > Guides, clicks Load
3. `GLV:LoadGuide()` parses guide, creates UI steps
4. Event trackers (quest/item/gossip/taxi) fire `HandleQuestAction()` on events
5. `GLV:RefreshGuide()` rebuilds UI (debounced 0.1s), calls `OnStepChanged()`

### Quest Tracking Architecture (Core/Events/Quests.lua)

**Two-method pattern** (separation of concerns):
- `MarkQuestAction(questId, title, actionType, objectiveIndex)` - Pure marking logic: iterates display steps, updates `stepQuestState` completion tracking. Returns `(stepMarked, multiActionStepFound)`. Does NOT trigger UI updates.
- `HandleQuestAction(questId, title, actionType, objectiveIndex)` - Calls `MarkQuestAction()`, then triggers `UpdateStepNavigation()` and UI refresh via `GLV:RefreshGuide()`.

**Objective batching** (prevents redundant UI updates):
- `CheckQuestObjectives()` batches multiple objective completions: loops through all objectives, calls `MarkQuestAction()` for each completed one, then calls `UpdateStepNavigation()` once with aggregated `anyStepMarked` and `anyMultiAction` flags.
- Quest accept/complete/turnin events call `HandleQuestAction()` directly (normal single-action flow).

**Navigation timer cleanup** (prevents stale navigation updates):
- When `RefreshGuide()` is called (which advances steps), any pending "GLV_NavigationUpdate" scheduled event is cancelled to prevent stale step references.
- For TURNIN actions, navigation update is delayed 0.5s and re-reads current step at execution time (via `ForceNavigationUpdate()`) instead of using captured stepData closure.

**Quest sync on guide load**:
- `SyncQuestAcceptSteps()` auto-completes `[QA]` steps for quests already in the player's log (handles quests accepted before addon/guide was loaded). Called during `OnQuestLogUpdate` with early-out when no unmarked QA steps exist. Stores `{title, timestamp}` format in store.Accepted (matches TrackAccepted format).

### Navigation System (3-file split)

**GuideNavigation.lua** (orchestrator):
- Creates nav frame, manages arrow rendering at 50 FPS
- Handles ZONE_CHANGED_NEW_AREA event for zone-based guide transitions
- `UpdateWaypointForStep(stepData)` - Entry point: auto-skips impossible QT steps, then delegates to WaypointResolver/NavigationModes
- `CheckAutoSkipTurnins(stepData)` - Auto-completes steps with `[QT]` when quest not in player's log
- Multi-waypoint tracking: auto-advances when player reaches waypoint (5 yard threshold)
- GOTO-to-UseItem transition: After reaching GOTO waypoint, shows use-item button if step has `[UI]` tag. Custom click handler uses item then advances to remaining waypoints (skipping GOTO coords). State tracked via `useItemShownAfterGoto` flag.
- Zone mismatch handling: GOTO waypoints hide navigation when player in wrong zone (no use-item fallback), other waypoint types show use-item icon if available
- Quest objective display: Uses `self.currentQuestId` (step-level quest context from WaypointResolver) to show progress for QC steps. Waypoint-level `currentWaypoint.questId` only exists for quest DB coordinates, not TAR waypoints.
- Delegate methods maintain external API compatibility

**NavigationModes.lua** (display modes):
- Show/Hide methods for: EquipItem, UseItem, Hearthstone, NextGuide, XPProgress, SkillProgress
- Skill progress: reuses XP bar for skill level tracking (green color, current/target display), updates on SKILL_LINES_CHANGED
- XP progress: blue progress bar for level requirements
- Death navigation: captures corpse position on death, blue-tinted arrow to body, restores state on resurrection (preserves XP/skill requirements)
- Receives nav frame via `SetNavigationFrame(frame)`

**WaypointResolver.lua** (pure logic, no UI):
- `ResolveWaypoints(stepData)` returns `{waypoints, description, specialMode, specialModeData, questId, actionType, objectiveIndex, useItemId}`
- 7-priority resolution: explicit [G] coords > ordered TAR+quest NPCs > legacy TAR > quest DB coords > line coords > step coords > quest objectives
- Special modes: "SKILL" for `[SK]` profession requirements, "XP" for level requirements, "HEARTHSTONE", "NEXT_GUIDE", "USE_ITEM", "EQUIP_ITEM"
- **Priority 1 (GOTO coords)**: Only collects `[G]` coordinates from main (non-OC) lines. OC line coords are preparatory hints and must not override quest NPC waypoints from Priority 2. OC coords remain available as fallback in Priority 6 (line coords).
- **TAR extraction**: Skips `[TAR]` targets on lines with `[QA]`/`[QT]` tags only. TARs on `[QC]` lines are navigation targets (the mob to kill), resolved via GetNPCCoordinates for closest spawn. Quest DB provides start/end NPC coords for QA/QT.
- `GetQuestStatus(questId)` - Checks QuestTracker store first, falls back to quest log name matching. For store.Completed entries, verifies quest is truly not in log before returning false (prevents false auto-skip of same-name chain quest turnins where store has wrong ID). Conservative return when name scan fails but quest tracked as accepted.
- `GetCurrentQuestAction(stepData)` - Returns first uncompleted action (QT > QA > QC priority)

### Database (VGDB)

Quest/NPC/Item data from ShaguDB in `Assets/db/`:
- `VGDB.quests.data[id]` - Quest data: `.start.U` (giver NPCs), `.end.U` (turnin NPCs), `.obj` (objectives)
- `VGDB.units.data[id]` - NPC data: `.coords[n] = {x, y, zoneId, ?}`
- `VGDB.items.data[id]` - Item drop sources
- `VGDB.zones[locale][id]` - Zone name translations
- `GetNPCCoordinates(npcId)` returns closest spawn: collects all NPC spawns in player's current zone, calculates distances using Astrolabe, returns nearest spawn. Prevents navigation to distant spawns when same mob has multiple locations in zone.

**TurtleWoW Overrides**:
- Base ShaguDB data is loaded first, then `*-turtle.lua` files override/extend with TurtleWoW-specific data
- Turtle files use `pfDB` global (pfQuest TurtleDB format) with "-turtle" suffixed keys: `pfDB[category]["data-turtle"]`, `pfDB[category]["enUS-turtle"]`
- `mergedb.lua` script copies pfDB entries into VGDB, replacing existing records. Entries with value "_" are deleted (removal marker).
- Covers: quests, units, items, objects, areatrigger (both data and enUS locale tables)
- `pfDB` is freed after merge to save memory
- **Loading order**: ShaguDB files → `initpfdb.lua` (creates pfDB) → Turtle override files → `mergedb.lua` (merges pfDB into VGDB, frees pfDB)
- **Requires full game restart** when Turtle override files are added/modified (new TOC entries)

### Settings Keys (commonly used)

```lua
{"Guide", "ActivePack"}                          -- Selected guide pack
{"Guide", "CurrentGuide"}                        -- Current guide ID
{"Guide", "Guides", guideId, "CurrentStep"}      -- Active step index
{"Guide", "Guides", guideId, "StepState"}        -- Step completion table
{"Guide", "Guides", guideId, "StepQuestState"}   -- Per-action completion tracking
{"Guide", "Guides", guideId, "VisitedTARs", idx} -- Visited NPCs per step
{"Automation", "AutoAcceptQuests"}               -- (UNUSED) Auto-accept setting, feature disabled
{"Automation", "AutoTurninQuests"}               -- (UNUSED) Auto-turnin setting, feature disabled
{"UI", "GuideTextScale"} / {"UI", "NavigationScale"} -- Scale multipliers
{"UI", "MinimapPath"} / {"UI", "WorldMapPath"}  -- Path rendering toggles
{"UI", "GuideHidden"}                            -- Window visibility state
{"Navigation", "CorpsePosition"}                 -- Persisted corpse pos {c,z,x,y}
{"Integration", "pfQuestSaved"}                  -- pfQuest config snapshot (survives /reload)
{"Talents", "ActiveTemplate", class}             -- Active talent template
```

## Guide Syntax

| Tag | Meaning | Example |
|-----|---------|---------|
| `[N x-y Name]` | Guide name and level range | `[N 1-11 Elwynn Forest]` |
| `[GA faction]` | Faction/race filter (comma-separated) | `[GA Alliance]` or `[GA Horde,Undead]` |
| `[QA id]` | Accept quest | `[QA783]` |
| `[QC id]` or `[QC id,objIdx]` | Complete quest (or specific objective, 1-based) | `[QC33,2]` |
| `[QT id]` | Turn in quest (auto-skipped if quest not in log) | `[QT783]` |
| `[TAR id]` | NPC/target reference | `[TAR823]` |
| `[G x,y Zone]` | Go to coordinates | `[G 44,57 Dun Morogh]` |
| `[A class/race]` | Class/race-specific step (see filtering logic below) | `[A Mage]` or `[A Dwarf, Human, Priest]` |
| `[XP level]` | XP requirement (formats: `[XP3]`, `[XP3-100]`, `[XP3.5]`) | `[XP4-290]` |
| `[T]` | Train at trainer | `[T] Learn skills` |
| `[LE id,Name]` | Learn spell/skill (auto-completes) | `[LE 1180,Two-Handed Swords]` |
| `[SK skill level]` | Skill/profession requirement (auto-completes when reached) | `[SK First Aid 40]` |
| `[CI id,count]` | Collect item (auto-completes on BAG_UPDATE) | `[CI1179,10]` |
| `[UI id]` | Use item (fallback icon when no coords) | `[UI2746]` |
| `[OC]` | Optional, completes with next. GOTO coords on OC lines are excluded from Priority 1 resolution (used only as fallback in Priority 6). | `[OC][G 50,60 Zone]Grind north` |
| `[NX x-y Name]` | Next guide link | `[NX 11-13 Westfall]` |
| `[P name]` | Get flight path | `[P Stormwind]` |
| `[H]` | Use hearthstone (auto-completes on arrival) | `[H] to Stormwind` |
| `[S location]` | Bind hearthstone (auto-completes on ConfirmBinder) | `[S Goldshire]` |
| `[F]` | Take flight | `[F] Fly to Ironforge` |

Multiple `[G]` or `[TAR]` tags per step create auto-advancing waypoint sequences.

**URL embedding**: HTTP/HTTPS URLs in guide text are automatically detected and replaced with blue `[Link]` placeholders. Clicking a step containing a URL opens a popup with the full URL pre-selected for Ctrl+C copying (WoW 1.12 workaround).

## Class/Race Filtering ([A] Tag)

The `[A]` tag supports mixed race and class filtering with AND logic:

- **Single tag with mixed types**: `[A Dwarf, Human, Priest]` = (Dwarf OR Human) AND Priest
  - Matches: Dwarf Priest, Human Priest
  - Rejects: Dwarf Warrior, Human Mage, Night Elf Priest
- **Multiple tags are AND'd**: `[A Dwarf, Human] [A Priest]` = (Dwarf OR Human) AND Priest (equivalent to above)
- **Single-type tags**: `[A Hunter]` matches any Hunter, `[A Dwarf, Gnome]` matches any Dwarf or Gnome

**Implementation**: Uses KNOWN_CLASSES lookup table (9 classes: warrior, paladin, hunter, rogue, priest, shaman, mage, warlock, druid) to separate entries within a tag. Races and classes are identified via lowercase matching, then AND'd together.

## Quest Matching

**IMPORTANT**: Auto-accept and auto-turnin features are currently **disabled** (QUEST_DETAIL/QUEST_COMPLETE event handlers commented out). The code remains for future re-enable once timing issues with rapid QT→QA sequences are resolved. Settings UI checkboxes are hidden.

- **ACCEPT**: Matches by exact quest ID from QUEST_DETAIL event
- **Name matching**: All functions use `QuestNamesMatch()` for consistent fuzzy matching:
  1. Case-insensitive exact match
  2. Normalized match: strips trailing dots (WoW ellipsis "...") and whitespace only
  3. Does NOT strip all punctuation (prevents false positives like "Find It: Gold" vs "Find It - Gold")
- **Quest chain handling**: Same-name quests (repeatable/chain quests like "The Tome of Divinity" or "Balance of Nature" 456/457) are resolved deterministically:
  - `GetQuestIDByName()` returns the smallest matching ID (first quest in chain)
  - `FindAcceptedIdByTitle()` returns the smallest accepted ID matching the name, **skips IDs in store.Completed** (ensures chain quests are processed in order: 456 first, then 457)
  - `GetExpectedQuestIdFromCurrentStep()` skips already-accepted IDs for ACCEPT actions, skips already-completed IDs for TURNIN actions
  - `GetQuestIdInCurrentStep()` checks current step + 2 steps ahead (lookahead for auto-accept/turnin when player is on preceding [G] step), skips already-accepted IDs for ACCEPT, skips already-completed IDs for TURNIN
  - `DoesQuestActionMatch()` uses strict ID matching only (no name fallback) to prevent false positives on same-name chain quests
  - `HookQuestAbandon()` checks store.Accepted first for consistent chain quest handling
  - Ensures correct quest is matched when accepting/turning in same-name chain quests
- **`GetQuestStatus()`**: Checks QuestTracker.store first, falls back to quest log with `QuestNamesMatch()`
- **Auto-skip**: Steps with `[QT]` where quest is not in log are automatically completed
- **Objective tracking**: `[QC id,objectiveIndex]` tracks individual objectives (1-based)
- **Multi-action steps**: Each action tracked independently in `StepQuestState`, step completes when all done

## Skill Tracking

- **Syntax**: `[SK SkillName Level]` - e.g., `[SK First Aid 40]`, `[SK Cooking 150]`
- **Auto-completion**: Steps auto-complete when player's skill reaches the required level
- **Real-time updates**: Tracked via SKILL_LINES_CHANGED event (fires when skills are trained/used)
- **Navigation display**: Shows green progress bar in nav frame with current/target level (e.g., "20 / 40")
- **Icon**: Trainer gossip icon (same as `[T]` train steps)
- **Data source**: `GetSkillLineInfo()` API scans all skill lines to find matching profession name
- **Death integration**: Skill progress bar is hidden during corpse navigation, restored on resurrection
- **Scheduled check**: `CheckSkillRequirements()` runs 3.5s after guide load to sync already-met requirements

## Key Files

| File | Purpose |
|------|---------|
| `Core.lua` | Addon initialization (~171 lines): LibStub setup, Ace2 initialization, slash commands (`/glv`, `/glvminimap`), minimap button, event registration |
| `Settings.lua` | Settings manager with nested key access |
| `Helpers/DBTools.lua` | DB queries (quest/NPC/item), spell name resolution. GetQuestIDByName() returns smallest matching ID for deterministic quest chain handling. GetNPCCoordinates() uses Astrolabe distance calculation to return closest spawn in player's zone. GetQuestAllCoords() filters unit/object objectives by questPart index when provided (so [QC id,3] only returns coords for objective 3). findClosestUnit() delegates to GetNPCCoordinates for zone-aware spawn resolution. |
| `Assets/db/initdb.xml` | Database loading order: ShaguDB → initpfdb.lua → Turtle overrides → mergedb.lua |
| `Assets/db/initpfdb.lua` | Initializes pfDB global for TurtleWoW override files |
| `Assets/db/mergedb.lua` | Merges pfDB (Turtle overrides) into VGDB, handles "_" deletion marker, frees pfDB |
| `Core/GuideParser.lua` | Tag parsing, step extraction, [A] tag filtering (KNOWN_CLASSES table for race/class separation), [SK] skill requirement parsing |
| `Core/GuideLibrary.lua` | Guide registration, pack management, multi-level dropdown, guide selection logic (LoadDefaultGuideForRace, FindStartingGuideForRace, FindBestGuideForLevel). RACE_ALIASES table maps TurtleWoW custom races (HighElf→NightElf) to standard races for starting guide resolution. FindBestGuideForLevel uses deterministic selection (sorted by minLevel, then name) to ensure consistent guide picks. |
| `Core/GuideWriter.lua` | UI creation, checkbox handling, step highlighting, XP display, URL detection/replacement (processURLs function) |
| `Core/GuideNavigation.lua` | Navigation orchestrator, arrow rendering, zone change event handling (ZONE_CHANGED_NEW_AREA), auto-skip QT |
| `Core/Navigation/NavigationModes.lua` | Display modes (equip, use item, hearthstone, next guide, XP bar [blue], skill progress [green]) + death navigation with state preservation |
| `Core/Navigation/WaypointResolver.lua` | 7-priority waypoint resolution, TAR extraction logic (skips TARs on QA/QT lines only, keeps TARs on QC lines for mob navigation), conservative GetQuestStatus with quest log verification for store.Completed entries. Returns specialMode for SKILL/XP/HEARTHSTONE/etc. |
| `Core/MinimapPath.lua` | Minimap/world map dotted paths, pfQuest integration, frame reuse pattern with getglobal() |
| `Core/Events/Quests.lua` | Quest hooks, MarkQuestAction (pure marking), HandleQuestAction (+ UI update), batched objective completions, SyncQuestAcceptSteps (auto-complete QA on load, stores {title, timestamp} format). **Auto-accept/turnin functions (OnQuestDetail/OnQuestComplete) and event handlers are commented out** due to timing issues with rapid QT→QA sequences. Navigation timer cleanup: cancels pending "GLV_NavigationUpdate" on RefreshGuide, uses ForceNavigationUpdate for TURNIN delays. DoesQuestActionMatch() uses strict ID matching only (no name fallback) to prevent false positives on same-name chain quests. FindAcceptedIdByTitle() returns smallest matching ID that is NOT in store.Completed (enables ordered chain quest processing: 456 before 457). GetExpectedQuestIdFromCurrentStep() and GetQuestIdInCurrentStep() check current + 2 steps ahead (lookahead), skip already-processed IDs (Accepted for QA, Completed for QT) for same-name chain quests. HookQuestAbandon() checks store.Accepted first. |
| `Core/Events/Character.lua` | XP tracking, spell learning detection (`[LE]`), skill level tracking (`[SK]`). Spellbook fallback for profession recipes. |
| `Core/Events/Items.lua` | [CI] item collection tracking, checks ongoing steps via OngoingStepsManager |
| `Core/Events/Gossip.lua` | [H]/[S] hearthstone detection |
| `Core/Events/Taxi.lua` | Flight path tracking |
| `Core/Events/Talents.lua` | Talent suggestions, toast notifications, TALENT_FRAMES centralized table |
| `Frames/Frames.lua` | UI functions, settings handlers, minimap button, URL copy popup (GLV:ShowURLPopup) |
| `Frames/*.xml` | Frame definitions (MainFrame, Settings, TalentPopup) |
| `TalentTemplates/*.lua` | Class talent builds (9 classes) |

## Lua 5.0 / WoW 1.12 Notes

```lua
table.getn(t)           -- NOT #t
string.gfind(s, pat)    -- NOT string.gmatch
string.find(s, pat)     -- NOT string.match (use captures)
getglobal("name")       -- For dynamic frame access
this                    -- Inside XML handlers, NOT self
pairs(t)                -- Non-deterministic iteration order, use explicit sorting
```

- No inline textures (`|T...|t`) in FontStrings - only `|cAARRGGBB` and `|r` work
- `IsShown()` may fail in scheduled events - use frame existence checks instead
- **Named frames persist through `/reload`**: The Lua state resets but `CreateFrame("...", "FrameName", ...)` frames remain visible. Always use `getglobal("FrameName") or CreateFrame(...)` pattern to reuse existing frames instead of creating orphans.
- **`pairs()` iteration order is non-deterministic**: When order matters (e.g., guide selection), collect into array and use `table.sort()` before processing
- New TOC entries require full game restart (not just `/reload`)

## Guide Pack API

```lua
-- In guide pack's init.lua:
local GLV = LibStub("GuidelimeVanilla")
GLV.guidePackAddons["Pack Name"] = "AddonFolderName"
GLV:RegisterStartingGuides("Pack Name", {["Human"] = "1-11 Elwynn Forest", ...})

-- In guide files:
GLV:RegisterGuide([[ [N 1-10 Zone] [GA Alliance] ... ]], "Pack Name")

-- Talent template API:
GLV:RegisterTalentTemplate(class, name, "leveling", {[10]={tree,row,col}, ...}, respec?)
```

Guide packs declare `## Dependencies: GuidelimeVanilla` in their .toc. Users must select and load packs via Settings > Guides. Dropdown auto-groups into submenus when >30 guides. Guides filtered by player faction/race via `[GA]` tag.

**TurtleWoW custom races**: RACE_ALIASES table in GuideLibrary.lua maps custom races to standard races for starting guide resolution (e.g., HighElf → NightElf). Guide packs can register custom race mappings directly, or fall back to the alias system if no direct mapping exists.
