# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

GuideLime Vanilla is a World of Warcraft Classic (1.12) addon providing an enhanced guide system with automatic quest tracking, autonomous navigation, and smart UI management. Port of Guidelime for Vanilla WoW (TurtleWoW private server).

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
- `QuestTracker` - Quest accept/complete/turnin tracking, auto-accept/turnin automation
- `ItemTracker` - `[CI]` item collection tracking (BAG_UPDATE)
- `CharacterTracker` - XP/level tracking, spell/skill learning detection (`[LE]`)
- `TaxiTracker` - Flight path tracking and automation (`[F]`/`[P]`)
- `GossipTracker` - Gossip dialog, hearthstone bind/use detection (`[H]`/`[S]`)
- `TalentTracker` - Talent suggestions, level-up toasts, talent frame highlighting
- `GuideNavigation` - **Orchestrator**: frame creation, arrow rendering, update loop, delegates to NavigationModes and WaypointResolver
- `NavigationModes` - Display modes (equip, use item, hearthstone, next guide, XP bar) + death/corpse navigation
- `WaypointResolver` - Coordinate resolution (7-priority system), quest status, step descriptions
- `MinimapPath` - Minimap/world map dotted path rendering, pfQuest integration with state persistence

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

### Navigation System (3-file split)

**GuideNavigation.lua** (orchestrator):
- Creates nav frame, manages arrow rendering at 50 FPS
- `UpdateWaypointForStep(stepData)` - Entry point: auto-skips impossible QT steps, then delegates to WaypointResolver/NavigationModes
- `CheckAutoSkipTurnins(stepData)` - Auto-completes steps with `[QT]` when quest not in player's log
- Multi-waypoint tracking: auto-advances when player reaches waypoint (5 yard threshold)
- Delegate methods maintain external API compatibility

**NavigationModes.lua** (display modes):
- Show/Hide methods for: EquipItem, UseItem, Hearthstone, NextGuide, XPProgress
- Death navigation: captures corpse position on death, blue-tinted arrow to body, restores state on resurrection
- Receives nav frame via `SetNavigationFrame(frame)`

**WaypointResolver.lua** (pure logic, no UI):
- `ResolveWaypoints(stepData)` returns `{waypoints, description, specialMode, specialModeData, questId, actionType, objectiveIndex, useItemId}`
- 7-priority resolution: explicit [G] coords > ordered TAR+quest NPCs > legacy TAR > quest DB coords > line coords > step coords > quest objectives
- `GetQuestStatus(questId)` - Checks QuestTracker store first, falls back to quest log name matching
- `GetCurrentQuestAction(stepData)` - Returns first uncompleted action (QT > QA > QC priority)

### Database (VGDB)

Quest/NPC/Item data from ShaguDB in `Assets/db/`:
- `VGDB.quests.data[id]` - Quest data: `.start.U` (giver NPCs), `.end.U` (turnin NPCs), `.obj` (objectives)
- `VGDB.units.data[id]` - NPC data: `.coords[n] = {x, y, zoneId, ?}`
- `VGDB.items.data[id]` - Item drop sources
- `VGDB.zones[locale][id]` - Zone name translations
- `GetNPCCoordinates(npcId)` prefers coordinates in player's current zone (multi-spawn NPCs)

### Settings Keys (commonly used)

```lua
{"Guide", "ActivePack"}                          -- Selected guide pack
{"Guide", "CurrentGuide"}                        -- Current guide ID
{"Guide", "Guides", guideId, "CurrentStep"}      -- Active step index
{"Guide", "Guides", guideId, "StepState"}        -- Step completion table
{"Guide", "Guides", guideId, "StepQuestState"}   -- Per-action completion tracking
{"Guide", "Guides", guideId, "VisitedTARs", idx} -- Visited NPCs per step
{"Automation", "AutoAcceptQuests"}               -- Auto-accept [QA] steps
{"Automation", "AutoTurninQuests"}               -- Auto-turnin [QT] steps
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
| `[A class]` | Class-specific step | `[A Mage] [QA3104]` |
| `[XP level]` | XP requirement (formats: `[XP3]`, `[XP3-100]`, `[XP3.5]`) | `[XP4-290]` |
| `[T]` | Train at trainer | `[T] Learn skills` |
| `[LE id,Name]` | Learn spell/skill (auto-completes) | `[LE 1180,Two-Handed Swords]` |
| `[CI id,count]` | Collect item (auto-completes on BAG_UPDATE) | `[CI1179,10]` |
| `[UI id]` | Use item (fallback icon when no coords) | `[UI2746]` |
| `[OC]` | Optional, completes with next | `[OC]Grind north` |
| `[NX x-y Name]` | Next guide link | `[NX 11-13 Westfall]` |
| `[P name]` | Get flight path | `[P Stormwind]` |
| `[H]` | Use hearthstone (auto-completes on arrival) | `[H] to Stormwind` |
| `[S location]` | Bind hearthstone (auto-completes on ConfirmBinder) | `[S Goldshire]` |
| `[F]` | Take flight | `[F] Fly to Ironforge` |

Multiple `[G]` or `[TAR]` tags per step create auto-advancing waypoint sequences.

## Quest Matching

- **ACCEPT**: Matches by exact quest ID from QUEST_DETAIL event
- **COMPLETE/TURNIN**: ID first, name fallback for COMPLETE only
- **`GetQuestStatus()`**: Uses QuestTracker.store exclusively (no name fallback) to prevent same-name quest confusion
- **Auto-skip**: Steps with `[QT]` where quest is not in log are automatically completed
- **Objective tracking**: `[QC id,objectiveIndex]` tracks individual objectives (1-based)
- **Multi-action steps**: Each action tracked independently in `StepQuestState`, step completes when all done

## Key Files

| File | Purpose |
|------|---------|
| `Core.lua` | Init, slash commands (`/glv`, `/glvminimap`), minimap button |
| `Settings.lua` | Settings manager with nested key access |
| `Helpers/DBTools.lua` | DB queries (quest/NPC/item), spell name resolution |
| `Core/GuideParser.lua` | Tag parsing, step extraction |
| `Core/GuideLibrary.lua` | Guide registration, pack management, multi-level dropdown |
| `Core/GuideWriter.lua` | UI creation, checkbox handling, step highlighting, XP display |
| `Core/GuideNavigation.lua` | Navigation orchestrator, arrow rendering, auto-skip QT |
| `Core/Navigation/NavigationModes.lua` | Display modes + death navigation |
| `Core/Navigation/WaypointResolver.lua` | 7-priority waypoint resolution |
| `Core/MinimapPath.lua` | Minimap/world map dotted paths, pfQuest integration with validated state persistence |
| `Core/Events/Quests.lua` | Quest hooks, HandleQuestAction, auto-accept/turnin |
| `Core/Events/Character.lua` | XP tracking, spell learning detection |
| `Core/Events/Items.lua` | [CI] item collection tracking |
| `Core/Events/Gossip.lua` | [H]/[S] hearthstone detection |
| `Core/Events/Taxi.lua` | Flight path tracking |
| `Core/Events/Talents.lua` | Talent suggestions, toast notifications |
| `Frames/Frames.lua` | UI functions, settings handlers, minimap button |
| `Frames/*.xml` | Frame definitions (MainFrame, Settings, TalentPopup) |
| `TalentTemplates/*.lua` | Class talent builds (9 classes) |

## Lua 5.0 / WoW 1.12 Notes

```lua
table.getn(t)           -- NOT #t
string.gfind(s, pat)    -- NOT string.gmatch
string.find(s, pat)     -- NOT string.match (use captures)
getglobal("name")       -- For dynamic frame access
this                    -- Inside XML handlers, NOT self
```

- No inline textures (`|T...|t`) in FontStrings - only `|cAARRGGBB` and `|r` work
- `IsShown()` may fail in scheduled events - use frame existence checks instead
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
