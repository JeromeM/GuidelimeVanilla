# Guide Tags Reference

This document describes all available tags for writing GuideLime Vanilla guides.

## Table of Contents

- [Guide Header Tags](#guide-header-tags)
- [Quest Tags](#quest-tags)
- [Navigation Tags](#navigation-tags)
- [Step Modifier Tags](#step-modifier-tags)
- [Action Tags](#action-tags)
- [Progress Tags](#progress-tags)
- [Formatting Tips](#formatting-tips)

---

## Guide Header Tags

These tags define guide metadata and should appear at the beginning of your guide.

| Tag | Description | Example |
|-----|-------------|---------|
| `[N level-level Name]` | **Guide name and level range** (required) | `[N 1-11 Elwynn Forest]` |
| `[D description]` | Guide description (supports `\\` for line breaks) | `[D By Sage\\Version 1.0]` |
| `[GA faction]` | Faction filter (Alliance/Horde) | `[GA Alliance]` |
| `[NX level-level Name]` | Link to next guide (shows clickable button on last step) | `[NX 11-15 Westfall]` |

---

## Quest Tags

Tags for quest-related actions. Quest IDs can be found in database addons or online databases.

| Tag | Description | Example |
|-----|-------------|---------|
| `[QA id]` | **Accept quest** - Creates a yellow `!` marker | `[QA 783]` |
| `[QC id]` | **Complete quest** - Track quest objectives | `[QC 783]` |
| `[QT id]` | **Turn in quest** - Creates a yellow `?` marker | `[QT 783]` |
| `[QS id]` | **Skip quest** - Mark quest as skipped | `[QS 783]` |
| `[Q id]` | **Quest reference** - Display quest name inline (no checkbox) | `[Q 783] is a prerequisite` |

### Multi-part Quests

For quests with multiple parts sharing the same name, add a comma and part number:

```
[QA 123,1] Accept first part
[QT 123,1] Turn in first part
[QA 124,2] Accept second part
```

### Multiple Quests Per Step

You can combine multiple quest tags in a single step:

```
[QT 100][QA 101] Turn in "Old Quest" and accept "New Quest"
```

---

## Navigation Tags

Tags that control the navigation arrow and waypoints.

| Tag | Description | Example |
|-----|-------------|---------|
| `[G x,y Zone Name]` | **Go to coordinates** | `[G 45.5,62.3 Elwynn Forest]` |
| `[TAR id]` | **Target NPC/mob** - Shows NPC name and sets waypoint | `[TAR 823]` |
| `[P name]` | **Get flight path** - Discover a flight master | `[P Stormwind]` |
| `[F name]` | **Fly to** - Take flight to destination (auto-completes) | `[F Ironforge]` |

### Coordinate Format

Coordinates use the format `x,y` where:
- `x` = horizontal position (0-100)
- `y` = vertical position (0-100)
- Zone name must match exactly (case-sensitive)

The `[G]` tag supports two formats:
- `[G 44,57 Dun Morogh]` (space before zone name)
- `[G 44.0, 76.1, Mulgore]` (comma before zone name)

### Multi-waypoint Navigation

You can include multiple `[G]` tags in a single step to create a sequence of waypoints. The navigation arrow will automatically advance to the next waypoint when you reach the current one (within 5 yards):

```
[G 50,50 Elwynn Forest][G 60,60 Elwynn Forest][G 70,70 Elwynn Forest] Follow the road east
```

---

## Step Modifier Tags

Tags that modify how steps behave.

| Tag | Description | Example |
|-----|-------------|---------|
| `[O]` | **Ongoing step** - Pins step at top (blue) while you continue | `[O][QC 50] Kill 10 wolves` |
| `[OC]` | **Optional/Complete with next** - Groups with following step | `[OC] Pick up items along the way` |
| `[A class/race]` | **Applies to** - Shows step only for specific class/race | `[A Mage] Train spells` |

### Class/Race Filtering

The `[A]` tag supports:
- Classes: Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock, Druid
- Races: Human, Dwarf, Night Elf, Gnome, Orc, Undead, Tauren, Troll

Multiple values can be comma-separated:
```
[A Mage, Warlock] Visit the magic trainer
[A Dwarf, Gnome] Take the tram to Ironforge
```

---

## Action Tags

Tags for specific player actions.

| Tag | Description | Example |
|-----|-------------|---------|
| `[H destination]` | **Use hearthstone** - Shows hearthstone icon, auto-completes | `[H Stormwind]` |
| `[S location]` | **Set hearthstone** - Bind at innkeeper | `[S Goldshire]` |
| `[T]` | **Train skills/spells** - Shows trainer icon in navigation | `[T] Train new spells` |
| `[UI itemId]` | **Use item** - Shows clickable item icon | `[UI 5571] Use item` |
| `[R]` | **Repair** - Reminder to repair gear | `[R] Repair at vendor` |
| `[V]` | **Vendor** - Reminder to sell items | `[V] Sell junk` |

### Equip Items

To show an equip item icon, use `[UI]` with "Equip" in the step text:
```
[UI 1234] Equip your new sword
```

---

## Progress Tags

Tags for tracking progress requirements.

| Tag | Description | Example |
|-----|-------------|---------|
| `[XP level]` | **Reach level** | `[XP 10] Grind to level 10` |
| `[XP level.percent]` | **Reach level with XP percentage** | `[XP 9.5] Get halfway to 10` |
| `[XP level-xp]` | **Reach level minus XP needed** | `[XP 10-200] Almost level 10` |
| `[XP level+xp]` | **Reach level plus extra XP** | `[XP 10+500] Buffer XP` |
| `[CI itemId]` | **Collect item** | `[CI 2589] Collect Linen Cloth` |
| `[CI itemId,count]` | **Collect specific amount** | `[CI 2589,20] Collect 20 Linen Cloth` |
| `[LE SP spellId]` | **Learn spell** - Auto-completes when learned | `[LE SP 133] Learn Fireball` |
| `[SP spellId]` | **Display spell name** - Shows spell name inline | `Use [SP 1515] on target` |

### XP Tag Formats

| Format | Meaning | Example |
|--------|---------|---------|
| `[XP 5]` | Reach level 5 | `[XP 5] Grind to 5` |
| `[XP 5.5]` | Level 5 + 50% XP | `[XP 5.5] Halfway to 6` |
| `[XP 5.75]` | Level 5 + 75% XP | `[XP 5.75] Almost 6` |
| `[XP 5-100]` | 100 XP away from level 5 | `[XP 5-100] Nearly there` |
| `[XP 5+200]` | Level 5 + 200 extra XP | `[XP 5+200] Buffer` |

---

## Formatting Tips

### Line Breaks

Use `\\` (double backslash) to create line breaks within steps:

```
Take the boat to Auberdine\\Craft bandages while you wait
```

### Step Structure

A typical step combines multiple tags:

```
[G 42,65 Westfall][QT 109][QA 110] Turn in "The Westfall Stew" and accept "Poor Old Blanchy"
```

### Color Coding

Tags automatically apply colors:
- Quest names: Gold/Yellow
- NPCs/Targets: Light blue
- Items: Purple
- Locations: Green

### Complete Example

```lua
GLV:RegisterGuide([[
[N 1-6 Northshire Valley]
[GA Alliance]
[D Sage's leveling guide for Humans\\Start zone: Northshire Abbey]

[QA 783] Accept "A Threat Within"
[G 48,42 Elwynn Forest][QT 783][QA 7] Turn in and accept "Kobold Camp Cleanup"
[O][QC 7] Kill Kobold Vermin (0/10)
[QA 5261] Accept "Eagan Peltskinner"
[G 48,40 Elwynn Forest][TAR 823][QT 5261] Turn in to Eagan
[XP 2] Grind to level 2 if needed
[A Mage, Warlock, Priest] Train spells at the abbey
[QT 7][QA 15] Turn in "Kobold Camp Cleanup", accept "Investigate Echo Ridge"
[NX 6-11 Elwynn Forest]
]], "Sage Alliance")
```

---

## Quick Reference Card

| Category | Tags |
|----------|------|
| **Header** | `[N]` `[D]` `[GA]` `[NX]` |
| **Quests** | `[QA]` `[QC]` `[QT]` `[QS]` `[Q]` |
| **Navigation** | `[G]` `[TAR]` `[P]` `[F]` |
| **Modifiers** | `[O]` `[OC]` `[A]` |
| **Actions** | `[H]` `[S]` `[T]` `[UI]` `[R]` `[V]` |
| **Progress** | `[XP]` `[CI]` `[LE SP]` `[SP]` |
