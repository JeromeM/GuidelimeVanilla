# Testing Patterns

**Analysis Date:** 2026-02-09

## Test Framework

**Runner:**
- No automated test framework detected
- Manual testing via `/reload` command in WoW client
- Testing environment: Turtle WoW private server (WoW Classic 1.12)

**Assertion Library:**
- Not applicable - no automated testing framework

**Run Commands:**
```bash
# Manual testing workflow:
/reload              # Reload UI to test code changes
/glv show            # Show guide window
/glv hide            # Hide guide window
/glv settings        # Open settings window
/glvminimap          # Debug minimap path system
/glvtalent debug     # Toggle talent system debug mode
```

**Debug Mode:**
- Set `GLV.Debug = true` in `Core.lua` for verbose logging
- All debug messages use `DEFAULT_CHAT_FRAME:AddMessage()` with colored prefixes
- View debug output in WoW chat frame with color filtering

## Test File Organization

**Location:**
- No dedicated test files found
- No `*.test.lua` or `*.spec.lua` files in repository
- Testing conducted manually in WoW client

**Testing Approach:**
- Load addon in WoW
- Execute commands via slash commands (`/glv`, `/glvtalent`, etc.)
- Observe behavior in guide window, settings UI, minimap
- Check chat output for debug messages when `GLV.Debug = true`
- Verify event handlers fire correctly on quest accept/complete, level up, zone change

**Module Test Checklist (Manual):**

**Quest Tracking** (`Core/Events/Quests.lua`):
- Accept quest via NPC dialog
- Verify `[QA id]` step auto-completes if marked
- Complete quest objective
- Verify `[QC id]` or `[QC id,objectiveIndex]` auto-completes if marked
- Turn in quest
- Verify `[QT id]` step auto-completes if marked

**Character Events** (`Core/Events/Character.lua`):
- Gain XP and level up
- Verify `[XP level]` steps auto-complete when requirement met
- Verify level-up talent toast notification shows
- Learn skill at trainer
- Verify `[LE skillName]` steps auto-complete when learned

**Item Tracking** (`Core/Events/Items.lua`):
- Collect items in inventory
- Verify `[CI itemId,count]` steps auto-complete when item count reached

**Hearthstone** (`Core/Events/Gossip.lua`):
- Use hearthstone
- Verify `[H location]` steps auto-complete when arriving at destination
- Bind hearthstone at innkeeper
- Verify `[S location]` steps auto-complete when bind location matches

**Navigation** (`Core/GuideNavigation.lua`):
- Load guide with waypoint steps
- Verify arrow displays pointing toward waypoint
- Walk toward waypoint
- Verify navigation auto-advances to next waypoint when within 5 yards
- Verify multi-waypoint sequences auto-transition

**Minimap Path** (`Core/MinimapPath.lua`):
- Enable minimap path in Settings > Display
- Verify dotted path appears on minimap when in same zone as waypoint
- Open world map
- Verify dotted path appears on world map when viewing waypoint's zone
- Disable minimap path
- Verify pfQuest nodes restore if they were disabled

**Talent System** (`Core/Events/Talents.lua`):
- Set active talent template in Settings > Talents
- Level up character
- Verify level-up toast notification shows with suggested talent
- Open talent frame
- Verify suggested talent has green highlight
- Respec (if template supports respec)
- Verify phase 2 talents activate after respec level

## Test Structure

**Manual Testing Pattern:**

Event-driven verification uses this pattern in code:
```lua
function Module:Init()
    if GLV.Ace then
        GLV.Ace:RegisterEvent("EVENT_NAME", function(param)
            self:OnEventName(param)
        end)
    end
end

function Module:OnEventName(param)
    -- Verify: Check if condition met
    if not condition then
        if GLV.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Module]|r Failed: reason")
        end
        return
    end

    -- Execute: Do action
    self:CompleteAction()

    -- Report: Log success when debugging
    if GLV.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Module]|r Success: action completed")
    end
end
```

**State Verification:**
- Check persistent state in settings: `GLV.Settings:GetOption({"Guide", "Guides", guideId, "StepState"})`
- Inspect module state during execution: `GLV.QuestTracker.store`, `GLV.CurrentDisplaySteps`
- Use debug commands to dump state: `/glvminimap` for path state, `/glvtalent info` for talent state

**UI Verification:**
- Visual inspection of guide window
- Check step highlighting (completed steps appear with checkmark)
- Verify navigation arrow displays correct destination
- Check settings UI reflects saved options

## Mocking

**Framework:**
- Not applicable - no test framework

**Approach:**
- Manual environment setup in WoW client
- No mocking of WoW APIs (tests run against real game state)
- Mocking of addon objects for isolated testing not implemented

**What to Test:**
- Core algorithms independent of WoW state:
  - XP requirement parsing and validation (`Parser:ParseExperienceRequirement()`)
  - Guide text parsing (`Parser:ParseGuide()`)
  - Quest and item counting logic
  - Coordinate distance calculations
  - Talent template resolution

**Example Manual Test - XP Requirement Parsing:**
```lua
-- In interactive console or debug chat:
local req = GLV.Parser:ParseExperienceRequirement("3")
-- Returns: {type="level", targetLevel=3, text="Level 3", ...}

local req2 = GLV.Parser:ParseExperienceRequirement("3-100")
-- Returns: {type="level_minus", targetLevel=3, xpMinus=100, ...}

local req3 = GLV.Parser:ParseExperienceRequirement("3.5")
-- Returns: {type="level_percent", targetLevel=3, targetPercent=50, ...}
```

**What NOT to Mock:**
- WoW game APIs (`UnitLevel()`, `GetQuestLogTitle()`, `GetItemInfo()`)
- UI frame creation (`CreateFrame()`, `SetPoint()`)
- Player state (position, inventory, quest log)
- These are tested via live game interaction

## Fixtures and Factories

**Test Data:**
- No fixture files created
- Test guides registered dynamically in guide pack addons
- Guide pack system designed to allow easy guide registration:

```lua
-- Example: Guide pack addon registers test guide
local GLV = LibStub("GuidelimeVanilla")

GLV:RegisterGuide([[
[N 1-5 Test Zone]
[QA1] Start quest
[TAR100] Talk to NPC
[QC1] Complete quest
[QT1] Turn in
]], "Test Pack")
```

**Test Data Locations:**
- Live guides come from guide pack addons (separate addon repositories)
- Database fixtures in `Assets/db/` for quest/NPC/item lookups:
  - `Assets/db/enUS/quests.lua` - Quest name/ID mappings
  - `Assets/db/enUS/units.lua` - NPC coordinate data
  - `Assets/db/enUS/items.lua` - Item ID data

## Coverage

**Requirements:**
- No coverage targets enforced
- Not applicable - no automated testing framework

**Manual Coverage Assessment:**

**Well-Tested Areas:**
- Quest event hooks (QUEST_DETAIL, QUEST_COMPLETE, QUEST_LOG_UPDATE)
- Character level-up and XP tracking
- Navigation waypoint calculation and auto-advancement
- Guide parsing and step filtering
- Settings persistence

**Under-Tested Areas:**
- Error recovery paths (network issues, missing database entries)
- Edge cases: simultaneous multiple completions, rapid quest chains
- UI scaling with extreme multiplier values
- Minimap dot calculation at map zone boundaries
- pfQuest integration when pfQuest config malformed
- Frame strata transitions while guide window open

**Test Coverage Gaps:**

**Quest Tracking** - Gaps:
- Same-name quests with different IDs (partial coverage via quest ID fallback)
- Multi-objective quests completing out of order (covered via `objectiveIndex`)
- Quest chains where NPC turns in different quest than accepted (minimal testing)

**Item Tracking** - Gaps:
- Items with zero count requirement (defined but never tested)
- Bank/vault item access (current implementation checks bags only)
- Rapid bag updates causing race conditions (0.3s throttle helps but untested)

**Navigation** - Gaps:
- Waypoint coordinates outside map bounds
- Swimming vs ground distance calculation (uses 2D Euclidean, ignores elevation)
- Multi-zone waypoint sequences where player teleports between zones

**Minimap Path** - Gaps:
- Astrolabe conversion for unknown zone IDs
- World map path rendering when player moves rapidly
- pfQuest state restore if config changed externally while path enabled

## Debugging Tools

**Slash Commands:**

```bash
/glvminimap          # Show minimap path debug info
                     # Displays: path state, waypoint data, pfQuest integration status

/glvtalent           # Show talent system help

/glvtalent debug     # Toggle talent system debug mode
                     # Prints debug messages for talent detection and highlighting

/glvtalent highlight # Force show talent highlight (for testing)

/glvtalent toast     # Force show level-up toast (for testing)

/glvtalent info      # Show current template, suggestions, respec phase
```

**Debug Output Patterns:**

**Guide Loading:**
```
|cFF00FFFF[Guide Loading]|r Selected guide: 1-11 Elwynn Forest for level 1
|cFF00FFFF[Guide Loading]|r No suitable guide found for level 60
```

**Quest Tracking:**
```
|cFF00FFFF[Quest Sync]|r Auto-checked: Defeat the Goretusks
|cFF00FFFF[Quest Sync]|r Synchronized 3 quest accepts with journal
```

**Item Collection:**
```
|cFF00FFFF[Items]|r Auto-completed: Collect items step (step 5)
```

**Hearthstone:**
```
|cFF00FFFF[GuideLime]|r Hearthstone arrived at Stormwind
|cFF00FFFF[GuideLime]|r Hearthstone bound to Goldshire - step completed!
```

**XP Tracking:**
```
|cFF00FFFF[GuideLime XP]|r Starting XP check timer
|cFF00FFFF[GuideLime XP]|r Stopping XP check timer
```

**Minimap Path:**
```
|cFF00FFFF[MinimapPath DEBUG]|r Minimap enabled
|cFF00FFFF[MinimapPath DEBUG]|r Waypoint: zone_id=1, x=100, y=200, distance=50.5
|cFF00FFFF[MinimapPath DEBUG]|r pfQuest integration: [enabled/disabled]
```

## Event-Driven Testing Approach

The addon uses event-driven architecture which requires testing via game events:

**Quest Events:**
- `QUEST_DETAIL` - Accept quest dialog opens (hook `QuestDetailAcceptButton_OnClick`)
- `QUEST_COMPLETE` - Turn-in dialog opens (hook `QuestRewardCompleteButton_OnClick`)
- `QUEST_LOG_UPDATE` - Quest log changes (manual check via `GetNumQuestLogEntries()`)
- `UNIT_QUEST_LOG_CHANGED` - Unit quest log changed

**Character Events:**
- `PLAYER_XP_UPDATE` - XP gained
- `PLAYER_LEVEL_UP` - Level increased
- `LEARNED_SPELL_IN_TAB` - Spell learned

**Inventory Events:**
- `BAG_UPDATE` - Bag contents changed (throttled to 0.3s)

**Navigation Events:**
- `ZONE_CHANGED_NEW_AREA` - Player entered new zone (schedules 0.5s delay for Astrolabe update)

**Hearthstone Events:**
- `SPELLCAST_STOP` - Hearthstone cast complete (schedules 1.0s check)
- Hook `ConfirmBinder` - Hearthstone bind dialog accepted

**Testing Strategy:**
1. Trigger WoW game event (e.g., accept quest, gain XP)
2. Event handler executes with game state intact
3. Check resulting guide step state changes
4. Verify chat messages logged with `GLV.Debug`
5. Inspect UI updates in guide window

---

*Testing analysis: 2026-02-09*
