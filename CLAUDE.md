# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GuideLime Vanilla is a World of Warcraft Classic (1.12) addon that provides an enhanced guide system with automatic quest tracking, autonomous navigation, and smart UI management. It's a port of the Guidelime addon adapted for Vanilla WoW (TurtleWoW private server).

## Development Environment

- **Target**: WoW Classic 1.12 (Turtle WoW)
- **Language**: Lua 5.0 (no modern Lua features like `#` operator, use `table.getn()`)
- **Testing**: Load addon in WoW, use `/reload` to test changes
- **Debug Mode**: Set `GLV.Debug = true` in Core.lua for verbose logging

## Architecture

### Core Module System

The addon uses LibStub for module registration and Ace2 libraries for core functionality:

```
GLV = LibStub("GuidelimeVanilla")  -- Main addon object, accessible everywhere
GLV.Addon = AceAddon instance     -- Ace2 addon with events, hooks, console, DB
```

Key global objects:
- `GLV.Settings` - Settings manager with nested key access
- `GLV.Parser` - Guide text parser
- `GLV.QuestTracker` - Quest event tracking
- `GLV.CharacterTracker` - XP/level tracking
- `GLV.TaxiTracker` - Flight path tracking
- `GLV.GossipTracker` - Gossip dialog tracking
- `GLV.GuideNavigation` - Arrow navigation and guide transitions (arrow display, next guide button)
- `GLV.CurrentGuide` - Currently loaded guide data (includes `.clickToNext` and `.next` for guide chaining)
- `GLV.CurrentDisplaySteps` - Filtered/displayed steps array

### Data Flow

1. **Guide Registration**: `GLV:RegisterGuide(text, group)` parses and stores guides
2. **Guide Loading**: `GLV:LoadGuide(group, id)` parses guide, creates UI steps
3. **Event Tracking**: Hooks on quest accept/complete trigger `QuestTracker:HandleQuestAction()`
4. **UI Updates**: `GLV:RefreshGuide()` redraws steps, `updateStepColors()` handles highlighting

### Settings System

Access settings via nested key arrays:
```lua
GLV.Settings:GetOption({"Guide", "Guides", guideId, "StepState"})
GLV.Settings:SetOption(value, {"Guide", "CurrentGuide"})
```

**Automation Settings** (Settings > Guides):
- `{"Automation", "AutoAcceptQuests"}` - Auto-accept quests when current step has `[QA]` tag
- `{"Automation", "AutoTurninQuests"}` - Auto-turnin quests when current step has `[QT]` tag (skips if reward choice required)
- `{"Automation", "AutoTakeFlight"}` - Auto-take flight when current step has `[F]` tag

**Display Settings** (Settings > Display):
- `{"UI", "GuideTextScale"}` - Scale multiplier for guide step text (0.8-1.5, default 1.0)
- `{"UI", "NavigationScale"}` - Scale multiplier for navigation arrow frame (0.8-1.5, default 1.0)

### Database (VGDB)

Quest/NPC/Item data from ShaguDB stored in `Assets/db/` folder:
- `VGDB.quests[locale][id]` - Quest data with `.T` (title), `.start`, `.end`, `.obj`
  - `.end` can have `.O` array for quests that turn in at objects instead of NPCs
  - `.start` can have `.O` array for quest-giving objects
- `VGDB.units.data[id]` - NPC coords in `.coords[n] = {x, y, zoneId}`
- `VGDB.items.data[id]` - Item coords and drop sources (`.U`, `.O`)
- `VGDB.zones[locale][id]` - Zone name translations

### Nampower API (Spells)

Spell data is retrieved via Nampower API instead of a local database:
- `GetSpellRec(spellId)` - Returns full spell record with fields: `name`, `rank`, `spellIconID`, `manaCost`, `school`, `spellLevel`, etc.
- `GetSpellNameAndRankForId(spellId)` - Returns spell name and rank string
- `GLV:getSpellName(id)` - Wrapper that uses GetSpellRec to get spell name
- `GLV:getSpellInfo(id)` - Returns table with name, rank, icon, manaCost, school, level

### Navigation System

The navigation frame displays different modes based on current step:
- **Arrow Mode** (default): Shows directional arrow to waypoint with distance/objective
- **Equip Item Mode**: Shows item icon with "Equip" instruction when step contains equip action
- **Hearthstone Mode**: Shows hearthstone icon for `[H]` steps with click-to-use functionality and auto-complete after cast
- **Next Guide Mode**: Shows clickable "Next Guide" button when on last step with `[NX]` tag

Key methods:
- `GuideNavigation:ShowNextGuide(nextGuideName)` - Display next guide button and parse/load guide on click
- `GuideNavigation:HideNextGuide()` - Return to arrow mode
- `GuideNavigation:ShowEquipItem(itemId)` - Display equip item icon
- `GuideNavigation:HideEquipItem()` - Return to arrow mode
- `GuideNavigation:ShowHearthstone(destination)` - Display hearthstone icon with click handler, auto-completes step after ~12s cast
- `GuideNavigation:HideHearthstone()` - Return to arrow mode
- `GuideNavigation:CompleteCurrentStep()` - Mark current step complete and advance to next step
- `GuideNavigation:ApplyScale(scale)` - Apply scale multiplier to navigation frame (from settings or manual value)

## Guide Syntax

Guides use tagged format parsed by `GuideParser.lua`:

| Tag | Meaning | Example |
|-----|---------|---------|
| `[N x-y Name]` | Guide name and level range | `[N 1-11 Elwynn Forest]` |
| `[GA faction]` | Alliance/Horde filter | `[GA Alliance]` |
| `[QA id]` | Accept quest | `[QA783]` |
| `[QC id]` | Complete quest | `[QC33]` |
| `[QT id]` | Turn in quest | `[QT783]` |
| `[TAR id]` | NPC/target reference | `[TAR823]` |
| `[A class]` | Class-specific step | `[A Mage] [QA3104]` |
| `[XP level]` | XP requirement | `[XP4-290]` |
| `[OC]` | Optional, completes with next | `[OC]Grind north` |
| `[NX x-y Name]` | Link to next guide (shows clickable button on last step) | `[NX 11-13 Westfall]` |
| `[P name]` | Get flight path | `[P Stormwind]` |
| `[H]` | Use hearthstone | `[H] to Stormwind` |

## Key Files

- `Core.lua` - Addon initialization, character loading, quest sync
- `Core/GuideParser.lua` - Tag parsing, step extraction
- `Core/GuideLibrary.lua` - Guide registration, dropdown, loading
- `Core/GuideWriter.lua` - UI creation, checkbox handling, highlighting, text scaling
- `Core/GuideNavigation.lua` - Arrow navigation using Astrolabe, next guide button for guide transitions, frame scaling
- `Core/Events/Quests.lua` - Quest hooks, state tracking, automation (auto-accept/turnin), ForceNavigationUpdate() for rapid quest sequences
- `Core/Events/Taxi.lua` - Flight path tracking and automation (auto-take flights)
- `Helpers/DBTools.lua` - Database query functions (quest/NPC/item/object lookups)

## Lua 5.0 Compatibility Notes

```lua
-- Use these patterns for Vanilla WoW compatibility:
table.getn(t)           -- NOT #t
string.gfind(s, pat)    -- NOT string.gmatch
string.find(s, pat)     -- NOT string.match (use captures with string.find)
getglobal("name")       -- For dynamic frame access
this                    -- Inside XML event handlers, NOT self
```

## WoW 1.12 UI Limitations

- **No inline textures in text**: The `|Tpath:size|t` escape sequence does NOT work in WoW 1.12. To show icons inline with text, you must create separate Texture/Button frames and position them manually, or use colored text characters as substitutes.
- **Limited escape sequences**: Only `|cAARRGGBB` (color) and `|r` (reset) work reliably in FontStrings.
- **Frame methods in scheduled events**: Methods like `IsShown()` may fail when called within scheduled events (e.g., functions queued with `this:Schedule()`). When calculating UI positions in scheduled contexts, rely on frame existence and height checks rather than visibility state.

## Quest Matching

The addon handles multi-part quests (same name, different IDs) with fallback matching:
- `GetQuestIDByName(name)` returns first matching quest ID
- `GetQuestStatus(questId)` and `GetQuestProgress(questId)` fall back to name-based matching if exact ID not found
- `QuestTracker:HandleQuestAction()` matches quest tags by ID first, then falls back to name matching for multi-part quests
- Quest completion detection supports both `isComplete == 1` (numeric) and `isComplete == true` (boolean)
- This ensures quest chains like "In Defense of the King's Lands" work correctly across different quest IDs

## Guide Pack Architecture

Guides are distributed as separate addons (guide packs) that depend on GuidelimeVanilla:

### How Guide Packs Work

1. Guide pack addon declares `## Dependencies: GuidelimeVanilla` in its .toc
2. Pack's init.lua gets GLV reference: `local GLV = LibStub("GuidelimeVanilla")`
3. Each guide file calls `GLV:RegisterGuide(text, "Pack Name")`
4. Guides are stored in `GLV.loadedGuides["Pack Name"][guideId]`
5. User selects active pack in Settings > Guides

### Guide Pack Management Functions

```lua
GLV:GetAvailableGuidePacks()     -- Returns list of installed pack names
GLV:GetActiveGuidePack()         -- Returns currently selected pack name
GLV:SetActiveGuidePack(name)     -- Set active pack and refresh dropdown
GLV:ShowNoGuideMessage()         -- Display "no guides" message in UI
```

### Creating a Guide Pack Addon

```
GuidelimeVanilla_MyPack/
├── GuidelimeVanilla_MyPack.toc
├── init.lua
└── Guide_Zone.lua
```

**init.lua:**
```lua
local GLV = LibStub("GuidelimeVanilla")
if not GLV then return end
```

**Guide file:**
```lua
local GLV = LibStub("GuidelimeVanilla")
GLV:RegisterGuide([[
[N 1-10 Zone Name]
[GA Alliance]
...
]], "My Pack Name")
```
