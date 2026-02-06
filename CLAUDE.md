# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GuideLime Vanilla is a World of Warcraft Classic (1.12) addon that provides an enhanced guide system with automatic quest tracking, autonomous navigation, and smart UI management. It's a port of the Guidelime addon adapted for Vanilla WoW (TurtleWoW private server).

## Development Environment

- **Target**: WoW Classic 1.12 (Turtle WoW)
- **Language**: Lua 5.0 (no modern Lua features like `#` operator, use `table.getn()`)
- **Testing**: Load addon in WoW, use `/reload` to test changes
- **Debug Mode**: Set `GLV.Debug = true` in Core.lua for verbose logging

## IMPORTANT: Git Workflow

**NEVER forget to run the agents before pushing:**
1. `claude-md-updater` - After each commit to update CLAUDE.md
2. `readme-feature-sync` - Before pushing to sync README with implemented features
3. `version-bump-prepush` - Before pushing to increment the addon version

These agents MUST be run in this order before any `git push` operation.

## Slash Commands

The addon registers `/glv` and `/guidelime` commands with the following subcommands:

- `/glv show` - Show the guide window (brings it back after hiding)
- `/glv hide` - Hide the guide window (shows chat message with reopen instructions)
- `/glv settings` - Open the settings window

**Close Button Behavior:**
- The close button (X) on the main guide window now hides the window instead of navigating steps
- When closed, displays: "|cFF6B8BD4[GuideLime]|r Guide window hidden. Type |cFFFFFF00/glv show|r to display it again."
- Functions used: `GLV_HideGuideFrame()`, `GLV_ShowGuideFrame()`, `GLV_ToggleSettings()`

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
- `GLV.ItemTracker` - Item collection tracking (auto-completes [CI] steps)
- `GLV.CharacterTracker` - XP/level tracking
- `GLV.TaxiTracker` - Flight path tracking
- `GLV.GossipTracker` - Gossip dialog tracking
- `GLV.TalentTracker` - Talent suggestion tracking (level-up notifications, talent frame highlights)
- `GLV.GuideNavigation` - Arrow navigation and guide transitions (arrow display, next guide button)
- `GLV.CurrentGuide` - Currently loaded guide data (includes `.clickToNext` and `.next` for guide chaining)
- `GLV.CurrentDisplaySteps` - Filtered/displayed steps array
- `GLV.loadedGuides` - Table of registered guides organized by pack: `GLV.loadedGuides[packName][guideId]`
- `GLV.guidePackAddons` - Maps pack names to addon names for metadata lookup: `GLV.guidePackAddons["Pack Name"] = "AddonName"`
- `GLV.guidePackStartingGuides` - Maps pack names to race-to-guide mappings: `GLV.guidePackStartingGuides[packName][race] = "Guide Name"`
- `GLV.TalentTemplates` - Registered talent templates: `GLV.TalentTemplates[class][templateName] = {type, talents, respec?}`
- `GLV.DefaultTalentTemplates` - Default template per class: `GLV.DefaultTalentTemplates["WARRIOR"] = "Arms (Icy Veins)"`
- `GLV:GetTemplateTalents(template, class)` - Helper that resolves correct talents table based on respec state

### Data Flow

1. **Guide Pack Installation**: External addon loads with `Dependencies: GuidelimeVanilla`
2. **Guide Registration**: Pack calls `GLV:RegisterGuide(text, group)` to register guides
3. **Pack Selection**: User selects pack in Settings > Guides, stored in `{"Guide", "ActivePack"}`
4. **Guide Loading**: `GLV:LoadGuide(group, id)` parses guide, creates UI steps
5. **Event Tracking**: Hooks on quest accept/complete trigger `QuestTracker:HandleQuestAction()`
6. **UI Updates**: `GLV:RefreshGuide()` redraws steps, `updateStepColors()` handles highlighting

### Settings System

Access settings via nested key arrays:
```lua
GLV.Settings:GetOption({"Guide", "Guides", guideId, "StepState"})
GLV.Settings:SetOption(value, {"Guide", "CurrentGuide"})
```

**Guide Pack Settings**:
- `{"Guide", "ActivePack"}` - Currently selected guide pack name (nil if none selected)
- `{"Guide", "Guides", guideId, "VisitedTARs", stepIndex}` - Per-step visited NPC tracking (persists across /reload)

**Automation Settings** (Settings > Guides):
- `{"Automation", "AutoAcceptQuests"}` - Auto-accept quests when current step has `[QA]` tag
- `{"Automation", "AutoTurninQuests"}` - Auto-turnin quests when current step has `[QT]` tag (skips if reward choice required)
- `{"Automation", "AutoTakeFlight"}` - Auto-take flight when current step has `[F]` tag

**Display Settings** (Settings > Display):
- `{"UI", "GuideTextScale"}` - Scale multiplier for guide step text (0.8-1.5, default 1.0)
- `{"UI", "NavigationScale"}` - Scale multiplier for navigation arrow frame (0.8-1.5, default 1.0)

**Talent Settings** (Settings > Talents):
- `{"Talents", "Enabled"}` - Enable talent suggestions (default true)
- `{"Talents", "ShowToast"}` - Show toast notification on level-up (default true)
- `{"Talents", "HighlightTalent"}` - Highlight suggested talent in talent frame (default true)
- `{"Talents", "ActiveTemplate", class}` - Active template name for a class (e.g., `{"Talents", "ActiveTemplate", "MAGE"}`)
- `{"Talents", "RespecDone", class}` - Boolean tracking respec state per class (nil = pre-respec phase 1, true = post-respec phase 2)
- `{"Talents", "LastShownLevel"}` - Last level where talent toast was shown (used to prevent duplicate popups)
- `{"Talents", "ToastPositionX"}` - X offset from screen center for toast notification (nil = default centered position)
- `{"Talents", "ToastPositionY"}` - Y offset from screen center for toast notification (nil = default centered position)

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
- **Multi-waypoint Mode**: Automatically advances to next waypoint when reaching current destination (within 5 yards)
- **Equip Item Mode**: Shows item icon with "Equip" instruction when step contains equip action
- **Hearthstone Mode**: Shows hearthstone icon for `[H]` steps with click-to-use functionality and auto-complete after cast
- **Next Guide Mode**: Shows clickable "Next Guide" button when on last step with `[NX]` tag

**Multi-waypoint Navigation:**
- Steps with multiple `[G]` or `[TAR]` tags create waypoint sequences
- Navigation automatically advances to next waypoint when player reaches current one
- Tracks progress: `allWaypoints[]`, `currentWaypointIndex`, `currentStepData`
- Distance threshold: 5 yards (`WAYPOINT_REACH_DISTANCE`)

**Ordered Waypoint Navigation:**
- TAR targets are visited in sequence, then automatically transition to quest objectives (QC/QT/QA)
- Visited TARs are persisted in settings to survive `/reload`
- TARs on lines with quest tags (QA/QC/QT) are skipped - the quest system handles navigation
- When last TAR is reached, navigation recalculates to find remaining quest objectives
- Waypoint metadata includes: `type`, `npcId`, `questId`, `actionType` for smart transitions

**Quest Objective Tracking:**
- Stores `currentObjectiveIndex` (nil for whole quest, 1/2/3 for specific objective)
- `GetCurrentQuestAction()` returns action, questId, actionType, and objectiveIndex
- Coordinates are filtered by objective index when navigating to `[QC id,objectiveIndex]` steps
- Individual objective completion triggers `HandleQuestAction()` with objectiveIndex parameter

Key methods:
- `GuideNavigation:ShowNextGuide(nextGuideName)` - Display next guide button and parse/load guide on click
- `GuideNavigation:HideNextGuide()` - Return to arrow mode
- `GuideNavigation:ShowEquipItem(itemId)` - Display equip item icon
- `GuideNavigation:HideEquipItem()` - Return to arrow mode
- `GuideNavigation:ShowHearthstone(destination)` - Display hearthstone icon with click handler, auto-completes step after ~12s cast
- `GuideNavigation:HideHearthstone()` - Return to arrow mode
- `GuideNavigation:CompleteCurrentStep()` - Mark current step complete and advance to next step
- `GuideNavigation:ApplyScale(scale)` - Apply scale multiplier to navigation frame (from settings or manual value)
- `GuideNavigation:GetQuestStatus(questId)` - Check if quest is in log and complete status (uses QuestTracker data first, falls back to quest log name matching)

### Talent Suggestion System

The addon includes an intelligent talent suggestion system that helps players optimize their leveling builds:

**Features:**
- **Level-up Toast Notifications**: Shows non-intrusive fade-in/fade-out popup when gaining a talent point (4s default, 6s for respec messages)
- **Talent Frame Highlighting**: Adds green glow around suggested talent in the talent frame (works with both TalentFrame and TWTalentFrame)
- **Class-specific Templates**: Pre-configured talent builds from Icy Veins for all 9 classes
- **Template Registration API**: Custom templates can be added via addon API
- **Respec Support**: Templates can define a transition level for talent resets with automatic phase switching
- **Smart Detection**: Automatically detects which talent frame addon is active

**Talent Templates:**

Templates are stored per class with level-by-level talent assignments:
```lua
-- Basic template structure: {[level] = {tree, row, col}}
GLV.TalentTemplates["MAGE"]["Frost Single-Target (Icy Veins)"] = {
    type = "leveling",
    talents = {
        [10] = {1, 4, 1},  -- Arcane tree, row 4, column 1
        [11] = {1, 4, 1},  -- Same talent, rank 2
        [12] = {3, 1, 2},  -- Frost tree, row 1, column 2
        -- ... continues to level 60
    }
}

-- Template with respec support (optional)
GLV.TalentTemplates["WARRIOR"]["Arms with Respec"] = {
    type = "leveling",
    talents = {
        [10] = {1, 1, 1},  -- Phase 1 talents (pre-respec)
        -- ... up to respec level
    },
    respec = {
        respecAt = 40,  -- Level to trigger respec notification
        message = "Reset your talents at a class trainer!",  -- Custom message (optional)
        talents = {
            [40] = {2, 1, 1},  -- Phase 2 talents (post-respec)
            -- ... continues to level 60
        }
    }
}
```

**Respec System:**
- Templates can define an optional `respec` table with a transition level
- At the `respecAt` level, a gold toast notification prompts the player to reset talents
- After respec, `GetTemplateTalents()` switches to phase 2 talents automatically
- Respec state persists across `/reload` in `{"Talents", "RespecDone", class}` setting
- Changing template in settings resets the respec state
- 100% backward-compatible: respec parameter is optional

**Default Templates:**

All 9 classes now have complete leveling builds sourced from talents.turtlecraft.gg (TurtleWoW):

- **Warrior**: Arms (TurtleWoW)
- **Paladin**: Retribution (TurtleWoW)
- **Hunter**: Beast Mastery (TurtleWoW)
- **Rogue**: Combat Swords (TurtleWoW)
- **Priest**: Discipline (TurtleWoW)
- **Shaman**: Enhancement (TurtleWoW)
- **Mage**: Frost (TurtleWoW)
- **Warlock**: Affliction (TurtleWoW)
- **Druid**: Feral (TurtleWoW)

**Template Registration API:**
```lua
-- Register a custom talent template (basic)
GLV:RegisterTalentTemplate(class, name, templateType, talents)
-- class: "MAGE", "WARRIOR", etc. (uppercase)
-- name: Display name (e.g., "Frost AoE Leveling")
-- templateType: "leveling" or "endgame"
-- talents: Table of {[level] = {tree, row, col}}

-- Register a custom talent template with respec support
GLV:RegisterTalentTemplate(class, name, templateType, talents, respec)
-- respec: optional table {respecAt = level, message = "string", talents = {[level] = {tree, row, col}}}
-- Example: {respecAt = 40, message = "Reset your talents!", talents = {[40] = {2,1,1}, ...}}

-- Get all templates for a class
local templates = GLV:GetTalentTemplates(class, filterType)

-- Get template names for dropdowns
local names = GLV:GetTalentTemplateNames(class, filterType)

-- Get active template for current character
local activeTemplate = GLV:GetActiveTemplate(class)

-- Get correct talents table for a template (resolves respec phase)
local talents = GLV:GetTemplateTalents(template, class)
-- Returns phase 2 talents if respec is done, otherwise phase 1 talents
```

**Key Methods:**
- `TalentTracker:Init()` - Initialize talent tracking system, hook into PLAYER_LEVEL_UP
- `TalentTracker:ShowToast(talentName, talentIcon, treeIndex, customMessage)` - Display toast with fade animation (4s default, 6s for custom messages)
- `TalentTracker:HideToast()` - Hide and reset toast frame
- `TalentTracker:UpdateTalentHighlights()` - Highlight suggested talent in talent frame (uses GetTemplateTalents for correct phase)
- `TalentTracker:ClearTalentHighlight()` - Remove highlight overlay
- `TalentTracker:GetSuggestedTalent(level)` - Get talent suggestion for a level
- `TalentTracker:DetectTalentFrame()` - Detect active talent frame (TalentFrame or TWTalentFrame)
- `TalentTracker:OnLevelUp(newLevel)` - Handle level-up event, detect respec transitions, show toast notifications
- `GLV:GetTemplateTalents(template, class)` - Resolve correct talents table based on respec state (phase 1 or 2)

**Slash Commands:**
- `/glvtalent` - Show talent system info
- `/glvtalent debug` - Toggle debug mode
- `/glvtalent highlight` - Force show talent highlight
- `/glvtalent toast` - Force show level-up toast
- `/glvtalent info` - Show current template, suggestions, and respec phase (if applicable)

**UI Frames:**
- `GLV_TalentToast` - Toast notification frame with fade animation (movable, draggable)
  - Contains `GLV_TalentToastIcon` for talent icon display
  - Contains `GLV_TalentToastText` for talent suggestion text
  - Contains `GLV_TalentToastMessage` for custom respec messages (hidden by default, gold text)
- `GLV_TalentHighlight` - Green glow overlay for talent frame buttons
- Both frames defined in `Frames/TalentPopup.xml`

**Settings Integration:**
- Talent settings page in Settings > Talents
- Enable/disable system, toast notifications, and talent highlights independently
- Template selection dropdown per character class
- "Move Notification" button to reposition toast notification (drag to desired location, click to confirm)
- Toast position saved as center-offset coordinates and persists across sessions
- Respec state automatically resets when changing templates
- Settings persist per character

**Toast Position Functions:**
- `GLV_StartMoveToastNotification()` - Enter move mode for toast frame (shows drag instructions)
- `GLV_ConfirmToastPosition()` - Confirm and save new toast position
- `GLV_TalentToast_SavePosition()` - Save toast position to settings (center-offset coordinates)
- `GLV_TalentToast_RestorePosition()` - Restore saved position on addon load

## Guide Syntax

Guides use tagged format parsed by `GuideParser.lua`:

| Tag | Meaning | Example |
|-----|---------|---------|
| `[N x-y Name]` | Guide name and level range | `[N 1-11 Elwynn Forest]` |
| `[GA faction]` | Alliance/Horde/Race filter (comma-separated) | `[GA Alliance]` or `[GA Horde,Undead]` |
| `[QA id]` | Accept quest | `[QA783]` |
| `[QC id]` or `[QC id,objectiveIndex]` | Complete quest (or specific objective) | `[QC33]` or `[QC33,2]` |
| `[QT id]` | Turn in quest | `[QT783]` |
| `[TAR id]` | NPC/target reference | `[TAR823]` |
| `[G x,y Zone]` | Go to coordinates (multiple per step creates waypoint sequence) | `[G 44,57 Dun Morogh]` or `[G 44.0, 76.1, Mulgore]` |
| `[A class]` | Class-specific step (prepends "Class :" at line start) | `[A Mage] [QA3104]` |
| `[XP level]` | XP requirement (auto-generates text if none provided) | `[XP4-290]` or `[XP3]` or `[XP3.5]` |
| `[T]` | Train at trainer (shows trainer icon) | `[T] Learn skills` |
| `[CI id,count]` | Collect item (auto-completes when items in bags) | `[CI1179,10]` |
| `[OC]` | Optional, completes with next | `[OC]Grind north` |
| `[NX x-y Name]` | Link to next guide (shows clickable button on last step) | `[NX 11-13 Westfall]` |
| `[P name]` | Get flight path | `[P Stormwind]` |
| `[H]` | Use hearthstone | `[H] to Stormwind` |

**Tag Details:**

- **[G] formats**: Supports both `x,y Zone` and `x, y, Zone` (with comma before zone name). Coordinates are hidden from guide text display but still used for navigation.
- **[A] display**: Text shows as "Mage : [Rest of step text]" at line start with class color
- **[XP] formats**:
  - `[XP3]` → "Level 3"
  - `[XP3-100]` → "Level 3 (-100 XP)"
  - `[XP3+500]` → "Level 3 (+500 XP)"
  - `[XP3.5]` → "Level 3 (50%)"
  - `[XP3 Custom text]` → "Custom text" (overrides default)
- **[QC] objective tracking**:
  - `[QC id]` → Completes when entire quest is done
  - `[QC id,objectiveIndex]` → Completes when specific objective is done (e.g., `[QC150,1]` for first objective of quest 150)
  - Objective indices are 1-based (1, 2, 3, etc.)
  - Navigation automatically targets coordinates for the specific objective
- **[CI] collect item tracking**:
  - `[CI id,count]` → Auto-completes when player has count or more of item id in bags
  - Example: `[CI1179,10]` completes when player has 10+ of item 1179
  - Only validates the current active step (prevents duplicate [CI] tags from completing simultaneously)
  - Triggers on BAG_UPDATE events with 0.3s delay for batch processing
- **[H] hearthstone usage**:
  - `[H]` → Auto-completes when player uses hearthstone and arrives at destination matching bind location
  - Example: `[H] to Stormwind` completes after hearthstone cast to Stormwind
  - Only validates the current active step (prevents duplicate [H] tags from completing simultaneously)
  - Triggers on SPELLCAST_STOP event with 1.0s delay for teleport completion
  - Bind location matching is case-insensitive and supports partial matches
- **[S] hearthstone binding**:
  - `[S location]` → Auto-completes when player binds hearthstone to the required location
  - Example: `[S Goldshire]` completes after binding hearthstone at Goldshire inn
  - Only validates the current active step (prevents duplicate [S] tags from completing simultaneously)
  - Matches against inn name, current subzone, or current zone (case-insensitive, partial match)
  - Triggers on ConfirmBinder hook with 0.5s delay
- **Multi-waypoint**: Multiple `[G]` or `[TAR]` tags in one step create auto-advancing waypoint sequence

## Key Files

- `Core.lua` - Addon initialization, character loading, checks for active pack (no auto-loading), slash command registration (`/glv`, `/guidelime`)
- `Core/GuideParser.lua` - Tag parsing, step extraction, item icon caching with tooltip queries
- `Core/GuideLibrary.lua` - Guide registration, pack management, dropdown, loading
- `Core/GuideWriter.lua` - UI creation, checkbox handling, highlighting, text scaling, fresh item texture fetching
- `Core/GuideNavigation.lua` - Arrow navigation using Astrolabe, multi-waypoint auto-advancement, next guide button for guide transitions, frame scaling
- `Core/Events/Quests.lua` - Quest hooks, state tracking, objective tracking with objectiveIndex, automation (auto-accept/turnin), QuestTracker data cleanup on turnin, ForceNavigationUpdate() for rapid quest sequences
- `Core/Events/Items.lua` - Item collection tracking, BAG_UPDATE event handling, current-step-only validation for [CI] tags, auto-completion when item count requirements met
- `Core/Events/Gossip.lua` - Gossip/NPC dialog tracking, hearthstone bind detection (matches inn name, subzone, or zone), auto-gossip/auto-turnin logic, current-step-only validation for [H] and [S] tags
- `Core/Events/Taxi.lua` - Flight path tracking and automation (auto-take flights)
- `Core/Events/Talents.lua` - Talent suggestion system, level-up tracking, toast notifications, talent frame highlighting, template management
- `Frames/Frames.lua` - UI functions including `GLV_UpdateGuidePackNotes()`, `GLV_LoadSelectedGuidePack()`, `GLV_UnloadCurrentGuide()`, `GLV_ShowGuideFrame()`, `GLV_HideGuideFrame()`, talent settings UI, toast position functions
- `Frames/MainFrame.xml` - Main window frame definition, close button wired to `GLV_HideGuideFrame()` (hides window instead of navigating)
- `Frames/TalentPopup.xml` - Toast notification frame and talent highlight overlay definitions
- `Frames/SettingsFrame.xml` - Settings UI including talent settings page
- `TalentTemplates/*.lua` - Class-specific talent templates (9 files, one per class)
- `Helpers/DBTools.lua` - Database query functions (quest/NPC/item/object lookups), quest NPC name lookup (`GetQuestTurninNPCName()`, `GetQuestAcceptNPCName()`)

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

The addon uses different matching strategies for quest actions to handle WoW 1.12 API limitations:

**ACCEPT Actions (`[QA]` tags):**
- Matches by exact quest ID only (from QUEST_DETAIL event)
- No name fallback - the event provides the precise quest ID being offered
- Most reliable since we know exactly which quest is being accepted

**COMPLETE/TURNIN Actions (`[QC]`, `[QT]` tags):**
- Matches by quest ID first
- Falls back to name matching in `HandleQuestAction()` for detecting completion
- **IMPORTANT**: `GetQuestStatus(questId)` uses QuestTracker data ONLY (no name fallback) to prevent false matches on same-name quests
- Quests are removed from `store.Accepted` when turned in to prevent stale data

**Quest Objective Tracking:**
- `[QC id,objectiveIndex]` tracks individual quest objectives (1-based index)
- Objective completion fires `HandleQuestAction()` with both questId and objectiveIndex
- Steps match only if both questId and objectiveIndex match (or both are nil for whole quest)
- Navigation system passes objectiveIndex to `GetQuestAllCoords()` for precise coordinate filtering

**Helper Functions:**
- `GetQuestIDByName(name)` returns first matching quest ID from VGDB
- `GetQuestStatus(questId)` checks QuestTracker.store first, falls back to quest log name matching for untracked quests
- `QuestTracker:HandleQuestAction(questId, title, actionType, objectiveIndex)` applies matching strategy
- Quest completion detection supports both `isComplete == 1` (numeric) and `isComplete == true` (boolean)
- `GetQuestTurninNPCName(questId)` returns turn-in NPC name from quest database
- `GetQuestAcceptNPCName(questId)` returns quest giver NPC name from quest database

**Same-Name Quest Handling:**
- Multiple quests can share the same name (e.g., "In Defense of the King's Lands")
- QuestTracker stores exact IDs in `store.Accepted[questId]` when quest is accepted
- `GetQuestStatus()` relies exclusively on this stored data to avoid ID confusion
- Quests are removed from Accepted when turned in, preventing false "in log" matches

This strategy ensures multi-part quest chains work correctly while maintaining precision for automation.

## Item Collection Tracking

The addon includes automatic tracking for "Collect Item" steps using the `[CI]` tag:

**Behavior:**
- `ItemTracker:CheckCollectItems()` validates ONLY the current active step (not all uncompleted steps)
- This prevents duplicate `[CI]` tags (e.g., `[CI1179,10]` appearing in multiple steps) from auto-completing simultaneously
- Matches the same single-step validation pattern used by QuestTracker

**Event Handling:**
- Listens to `BAG_UPDATE` events via Ace2 event system
- Uses 0.3s scheduled delay after bag updates to batch process multiple rapid inventory changes
- Initial check scheduled 3s after addon load to ensure guide is fully loaded

**Key Methods:**
- `ItemTracker:Init()` - Initialize item tracking, register BAG_UPDATE event, schedule initial check
- `ItemTracker:GetItemCount(itemId)` - Count total of item across all bags (0-4)
- `ItemTracker:OnBagUpdate()` - Handle bag update event with 0.3s delay
- `ItemTracker:CheckCollectItems()` - Validate current step's collect item requirements and auto-complete if met

**Step Completion:**
- Checks all `collectItems` entries in current step's lines
- Only completes step when ALL collect item requirements are met
- Marks step complete in `StepState` and triggers `RefreshGuide()` to update UI
- Debug message: "|cFF00FFFF[Items]|r Auto-completed: Collect items step (step N)"

**Important Notes:**
- Only checks `currentStep` from settings, not entire `CurrentDisplaySteps` array
- Skips already completed steps (checks `stepState[origIdx]`)
- Uses `CurrentDisplayToOriginal` mapping to track step state correctly

## Hearthstone Step Validation

The addon includes automatic tracking for hearthstone-related steps using `[H]` and `[S]` tags:

**Behavior:**
- `GossipTracker:CheckHearthstoneArrival()` validates ONLY the current active step (not all uncompleted steps)
- `GossipTracker:CheckHearthstoneBind()` validates ONLY the current active step (not all uncompleted steps)
- This prevents duplicate `[H]` or `[S]` tags (e.g., multiple `[H Goldshire]` steps) from auto-completing simultaneously
- Matches the same single-step validation pattern used by QuestTracker and ItemTracker

**Event Handling:**
- Listens to `SPELLCAST_STOP` event to detect hearthstone cast completion
- Uses 1.0s scheduled delay after cast to allow teleport to complete
- Hooks `ConfirmBinder` function to detect when hearthstone is bound at an innkeeper
- Initial check scheduled 3s after addon load to ensure guide is fully loaded

**Key Methods:**
- `GossipTracker:Init()` - Initialize gossip tracking, register events, hook ConfirmBinder
- `GossipTracker:OnSpellcastStop()` - Handle spell cast stop event with 1.0s delay
- `GossipTracker:CheckHearthstoneArrival()` - Validate current step's `[H]` tag after hearthstone use
- `GossipTracker:CheckHearthstoneBind()` - Validate current step's `[S]` tag after setting hearthstone

**Step Completion:**
- `[H]` steps: Auto-complete when player arrives at destination matching bind location
- `[S]` steps: Auto-complete when player binds hearthstone to the required location
- Bind location matching is case-insensitive and supports partial matches against:
  - Inn name (from `GetBindLocation()`)
  - Current subzone (from `GetSubZoneText()`)
  - Current zone (from `GetZoneText()`)
- Marks step complete in `StepState` and triggers `RefreshGuide()` to update UI

**Important Notes:**
- Only checks `currentStep` from settings, not entire `CurrentDisplaySteps` array
- Skips already completed steps (checks `stepState[origIdx]`)
- Uses `CurrentDisplayToOriginal` mapping to track step state correctly
- Debug message: "|cFF00FFFF[GuideLime]|r Hearthstone arrived at [destination]"
- Debug message: "|cFF00FFFF[GuideLime]|r Hearthstone bound to [location] (zone: [subzone]) - step completed!"

## Guide Pack Architecture

Guides are distributed as separate addons (guide packs) that depend on GuidelimeVanilla:

### How Guide Packs Work

1. Guide pack addon declares `## Dependencies: GuidelimeVanilla` in its .toc
2. Pack's init.lua gets GLV reference: `local GLV = LibStub("GuidelimeVanilla")`
3. Pack registers its addon name for metadata: `GLV.guidePackAddons["Pack Name"] = "AddonName"`
4. Each guide file calls `GLV:RegisterGuide(text, "Pack Name")`
5. Guides are stored in `GLV.loadedGuides["Pack Name"][guideId]`
6. User selects active pack in Settings > Guides dropdown
7. User clicks "Load" button to activate the pack
8. Main dropdown populates with guides from active pack only

### Guide Pack Management Functions

```lua
GLV:GetAvailableGuidePacks()              -- Returns list of installed pack names
GLV:GetActiveGuidePack()                  -- Returns currently selected pack name
GLV:SetActiveGuidePack(name)              -- Set active pack and refresh dropdown
GLV:ShowNoGuideMessage()                  -- Display "no guides" message in UI
GLV:RegisterStartingGuides(pack, mapping) -- Register race-to-guide mappings for a pack
GLV:GetStartingGuideForRace(pack, race)   -- Get starting guide name for a race in a pack
GLV:PopulateDropdown(group)               -- Populate dropdown with guides, filtered by player faction/race
```

### Multi-level Dropdown System

WoW 1.12's UIDropDownMenu has a hard limit of 32 buttons per level. Guide packs with many guides now use multi-level submenus to avoid overflow:

**Behavior:**
- **≤30 guides**: Flat dropdown list (original behavior)
- **>30 guides**: Guides are grouped into level range submenus (Levels 1-10, 11-20, 21-30, etc.)

**Implementation:**
- Helper functions in `Core/GuideLibrary.lua`:
  - `filterGuides(guides, playerFaction, playerRace)` - Pre-filter guides by player faction/race
  - `getGuideDisplayName(guideData)` - Build display name with level range
  - `groupGuidesByLevelRange(sortedGuides)` - Group guides into level buckets
- `PopulateDropdown()` checks guide count and switches mode automatically
- Multi-level mode uses `hasArrow = 1` for submenus and `UIDROPDOWNMENU_MENU_LEVEL`/`UIDROPDOWNMENU_MENU_VALUE` for navigation
- Level 1 shows range categories (e.g., "Levels 1-10 (15)"), Level 2 shows individual guides

**Constants:**
- `DROPDOWN_MAX_BUTTONS = 30` - Threshold for switching to multi-level mode (set below WoW's 32-button limit for safety)

### Faction/Race Filtering

The guide dropdown automatically filters guides based on the player's current faction and race:

- Guides with `[GA Alliance]` only appear for Alliance characters
- Guides with `[GA Horde]` only appear for Horde characters
- Guides with `[GA Horde,Undead]` only appear for Horde characters AND specifically for Undead players
- Guides without a `[GA]` tag appear for all factions/races

The filtering uses player data from settings:
- `{"CharInfo", "Faction"}` - Player's faction ("Alliance" or "Horde")
- `{"CharInfo", "Race"}` - Player's race ("Human", "Dwarf", "Night Elf", "Gnome", "Orc", "Troll", "Tauren", "Undead")

When a guide is registered via `GLV:RegisterGuide()`, the `faction` field is extracted from the guide's `[GA]` tag and stored in the guide metadata. The dropdown population function then parses this comma-separated faction string to determine visibility.

### Starting Guide System

Guide packs can register race-specific starting guides to automatically suggest appropriate guides for new characters:

**Registration:**
```lua
GLV:RegisterStartingGuides("Pack Name", {
    ["Human"] = "1-11 Elwynn Forest",
    ["Dwarf"] = "1-11 Dun Morogh",
    ["Night Elf"] = "1-11 Teldrassil",
    ["Gnome"] = "1-11 Dun Morogh",
    ["Orc"] = "1-12 Durotar",
    ["Troll"] = "1-12 Durotar",
    ["Tauren"] = "1-12 Mulgore",
    ["Undead"] = "1-12 Tirisfal Glades"
})
```

**Usage:**
```lua
local race = UnitRace("player")
local guideName = GLV:GetStartingGuideForRace("Pack Name", race)
-- Returns guide name or nil if no mapping exists
```

**Key Points:**
- Race names must match WoW API strings exactly (case-sensitive)
- Guide names should match the display name in the guide's `[N]` tag
- Multiple races can map to the same starting guide
- Optional feature - packs work fine without starting guide registration

### Creating a Guide Pack Addon

```
GuidelimeVanilla_MyPack/
├── GuidelimeVanilla_MyPack.toc
├── init.lua
└── Guide_Zone.lua
```

**GuidelimeVanilla_MyPack.toc:**
```
## Interface: 11200
## Title: Guidelime Vanilla - My Pack
## Notes: Description of your guide pack
## Author: Your Name
## Version: 1.0.0
## Dependencies: GuidelimeVanilla
```

**init.lua:**
```lua
local GLV = LibStub("GuidelimeVanilla")
if not GLV then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[My Pack]|r GuidelimeVanilla is required!")
    return
end

-- Register addon name for metadata lookup
GLV.guidePackAddons = GLV.guidePackAddons or {}
GLV.guidePackAddons["My Pack Name"] = "GuidelimeVanilla_MyPack"

-- Register starting guides for each race (optional but recommended)
GLV:RegisterStartingGuides("My Pack Name", {
    ["Human"] = "1-11 Elwynn Forest",
    ["Dwarf"] = "1-11 Dun Morogh",
    ["Night Elf"] = "1-11 Teldrassil",
    -- Add more races as needed
})

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[My Pack]|r Loaded successfully")
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

**Important Notes:**
- Pack name in `GLV.guidePackAddons` must match the group name used in `RegisterGuide()`
- Addon name in metadata must match the .toc filename (without .toc extension)
- Users must manually select and load the pack via Settings > Guides (no auto-loading)
- Main guide dropdown is disabled until a pack is loaded
- Starting guide registration is optional but recommended for automatic guide selection based on character race
- Race names must match WoW API race strings: "Human", "Dwarf", "Night Elf", "Gnome", "Orc", "Troll", "Tauren", "Undead"
- Guide names in starting guide mappings should match the guide display names (without level ranges if possible)
