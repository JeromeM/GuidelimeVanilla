<div align="center">

# GuideLime Vanilla

## ⚠️ **$\color{rgb(255,0,0)}{\textsf{WORK IN PROGRESS}}$** ⚠️

</div>

A World of Warcraft Classic (1.12) addon providing an enhanced guide system with automatic quest tracking and autonomous navigation.

## Requirements

- **[Nampower](https://github.com/pepopo978/nampower)** - Required for spell learning detection and other advanced features

## Guide Packs

GuidelimeVanilla is a guide engine - guides are provided as separate addons:

| Guide Pack | Description |
|------------|-------------|
| **[GuidelimeVanilla_Sage](https://github.com/JeromeM/GuidelimeVanilla_Sage)** | Sage 1-60 Alliance leveling guides |
| **[GuidelimeVanilla_Bustea](https://github.com/JeromeM/GuidelimeVanilla_Bustea)** | (BETA) Bustea 1-60 Horde leveling guides |

Install GuidelimeVanilla + a guide pack addon, then select your guide pack in **Settings > Guides**.

## Screenshots

#### Guide Full Screen :
![Full Screen](Assets/images/screen1.png)

#### Guide Window :
![Guide](Assets/images/screen2.png) ![Guide2](Assets/images/screen2b.png)

#### Arrow :
![Arrow](Assets/images/screen3.png) ![Hearthstone](Assets/images/screen3b.png) ![Nextguide](Assets/images/screen3c.png)

## Features

### 📚 Smart Guide System
- **Dynamic Step Management**: Automatically tracks completed and active quest steps
- **Checkbox Interface**: Visual progress tracking with clickable checkboxes
- **Step Highlighting**: Active steps highlighted with distinctive yellow color
- **Auto-scrolling**: Automatically scrolls to show the current active step
- **Ongoing Steps**: Special steps stay pinned at top (in blue) while you continue the guide - perfect for "kill X mobs" objectives that span multiple steps
- **XP Tracking**: Shows progress for grind/XP requirement steps
- **Guide Pack System**: Install guide packs as separate addons
- **Faction Filtering**: Guide dropdown automatically filters guides by your character's faction (Alliance/Horde) and race based on `[GA]` tag

### 🗺️ Autonomous Navigation System
- **Custom Arrow Display**: Built-in navigation arrow (no TomTom needed!)
- **Automatic Waypoints**: Creates waypoints for quest objectives automatically
- **Multi-waypoint Navigation**: Steps with multiple `[G]` coordinate tags create sequential waypoints that auto-advance when you reach each destination (within 5 yards)
- **Smart Coordinate Selection**: Automatically selects the best location based on step type (quest giver, turn-in NPC, or objective area)
- **Flexible Coordinate Formats**: Supports both `[G x,y Zone]` and `[G x, y, Zone]` coordinate formats
- **Zone-Aware Navigation**: Arrow automatically hides when in different zones and updates when you enter the correct zone
- **Quest Objectives Display**: Shows kill/collect progress directly on the navigation frame
- **Real-time Distance Updates**: Color-coded distance indicators (green=close, yellow=medium, red=far)
- **Interactive Navigation Icons**: Navigation frame displays context-specific clickable icons:
  - **Hearthstone Icon**: Click to use hearthstone on hearthstone steps, auto-completes after cast
  - **Trainer Icon**: Shows trainer icon for `[T]` train steps
  - **Equip Item Icon**: Shows items that need to be equipped
  - **Next Guide Button**: Clickable button on final step to load next guide
- **Movable Frame**: Hold Shift + drag to reposition the arrow

### 🎯 Quest Tracking
- **Automatic Progress**: Checks off steps when quests are accepted, completed, or turned in
- **Individual Objective Tracking**: Track specific quest objectives using `[QC questId,objectiveIndex]` syntax for granular progress tracking
- **Multi-step Support**: Handles steps with multiple quest actions
- **Quest State Persistence**: Saves progress between sessions
- **Smart Quest Matching**: Improved handling of multi-part quests with identical names
- **Automation Settings**: Optional automation features available in Settings > Guides:
  - **Auto Accept Quests**: Automatically accepts quests when on a quest accept step
  - **Auto Turnin Quests**: Automatically turns in quests when on a quest turnin step (skips if reward choice required)
  - **Auto Take Flights**: Automatically takes flights when on a flight path step
- **Flight Path Tracking**: Automatically detects discovered flight paths and flight destinations
- **Hearthstone Tracking**: Click the hearthstone icon in navigation frame on hearthstone steps to use hearthstone, step auto-completes after cast. Binding location matching now checks inn name, subzone, and zone for improved accuracy
- **Spell Learning Tracking**: Automatically completes learn spell steps when you train skills or spells (uses Nampower API for profession tier verification)
- **Item Collection Tracking**: Automatically completes collect item steps when you acquire the required items in your bags
- **Equipment Tracking**: Automatically completes equip item steps when you equip the specified items
- **Quest Abandonment Handling**: Properly updates state when quests are abandoned
- **XP Progress Bars**: Visual colored progress bars for grind/XP requirement steps showing current progress

### 🎨 User Interface
- **Clean Design**: Organized interface with consistent styling
- **Clickable Icons**: Special action icons (Hearthstone, items to use)
- **Color-coded Steps**: Visual distinction between step types and states
- **Quest Tags**: Colored markers for accept and turnin steps
- **Display Settings**: Customizable UI scaling available in Settings > Display:
  - **Guide Text Scale** (0.8-1.5): Adjust the size of guide step text
  - **Navigation Scale** (0.8-1.5): Adjust the size of the navigation arrow frame
  - **Auto-reload**: UI automatically reloads when display settings are changed for instant effect

## Installation

1. Download and extract to `World of Warcraft/Interface/AddOns/`
2. Rename folder to `GuidelimeVanilla` (remove `-master` if needed)
3. Restart WoW or `/reload`

## Usage

1. Select a guide from the dropdown menu
2. Follow the steps - checkboxes update automatically
3. Navigation arrow guides you to objectives
4. Click checkboxes manually if needed

## Creating Custom Guide Packs

Guide packs are separate addons that register guides with GuidelimeVanilla.

### Guide Pack Structure

```
GuidelimeVanilla_MyGuides/
├── GuidelimeVanilla_MyGuides.toc
├── init.lua
├── Guide_Zone1.lua
└── Guide_Zone2.lua
```

### Example .toc file

```
## Interface: 11200
## Title: Guidelime Vanilla - My Guides
## Notes: Custom leveling guides
## Dependencies: GuidelimeVanilla

init.lua
Guide_Zone1.lua
Guide_Zone2.lua
```

### Example init.lua

```lua
local GLV = LibStub("GuidelimeVanilla")
if not GLV then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[My Guides]|r GuidelimeVanilla is required!")
    return
end

-- Optional: Register starting guides for automatic guide selection per race
GLV:RegisterStartingGuides("My Guides", {
    ["Human"] = "Elwynn Forest",
    ["Dwarf"] = "Dun Morogh",
    ["Gnome"] = "Dun Morogh",
    ["NightElf"] = "Teldrassil",
    ["Orc"] = "Durotar",
    ["Troll"] = "Durotar",
    ["Tauren"] = "Mulgore",
    ["Undead"] = "Tirisfal Glades",
})
```

### Example Guide File

```lua
local GLV = LibStub("GuidelimeVanilla")
GLV:RegisterGuide([[
[N 1-10 My Zone Guide]
[GA Alliance]
[D Guide description\\Line 2\\Line 3]

Accept quest example step
Complete quest objectives step
Turn in quest step
]], "My Guides", "GuidelimeVanilla_MyGuides")  -- Third parameter is optional addon name for metadata
```

### Guide Pack API Reference

**`GLV:RegisterGuide(guideText, groupName, addonName)`**
- `guideText`: The guide content with tagged format
- `groupName`: The guide pack name (e.g., "My Guides")
- `addonName`: (Optional) The addon folder name for metadata lookup

**`GLV:RegisterStartingGuides(packName, raceMapping)`**
- `packName`: The guide pack name (must match the groupName used in RegisterGuide)
- `raceMapping`: Table mapping race names to starting guide names
- Race names: `Human`, `Dwarf`, `Gnome`, `NightElf`, `Orc`, `Troll`, `Tauren`, `Undead`
- Guide names must match the `[N]` tag name in your guides

### Guide Formatting Tips

- **Line Breaks**: Use `\\` (double backslash) to create line breaks in step text and descriptions
- **Special Tags**: The guide format uses bracketed tags to indicate actions (quest accept, turnin, navigation targets, etc.)
- **Multiple Actions**: A single step can contain multiple quest actions that all need completion
- **TOC Notes**: Add a `## Notes:` line in your .toc file - it will be displayed in the guide pack selection dropdown

For detailed guide syntax documentation, see the [TAGS.md](TAGS.md) file.

## Acknowledgments

- **Sage** - 1-60 Alliance leveling guides
- **Shagu** - Quest/NPC/Item databases (ShaguDB)
- **Astrolabe** - Coordinate management library
- **Original Guidelime** - Inspiration

## Support

Issues or feature requests? [Open a ticket on GitHub](https://github.com/JeromeM/GuidelimeVanilla/issues)

---

**Happy questing!**

