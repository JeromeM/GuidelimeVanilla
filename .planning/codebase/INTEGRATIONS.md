# External Integrations

**Analysis Date:** 2026-02-09

## APIs & External Services

**Nampower Spell API:**
- **Service:** Turtle WoW Nampower mod - provides spell lookup by ID at runtime
- **What it's used for:** Spell learning detection and skill level validation for guide step completion
- **API Call:** `GetSpellNameAndRankForId(spellId)` returns spell name and rank string (e.g., "Apprentice", "Journeyman", "Expert", "Artisan")
- **Location:** `Core/Events/Character.lua:113-149`
- **Fallback:** If Nampower API not available, falls back to `GetSpellIdForName()` to check spellbook directly
- **Purpose:** Validates that player has learned required skills/spells before auto-completing `[LS]` (Learn Spell) tagged steps

**WoW Event System:**
- **Events hooked:** QUEST_DETAIL, QUEST_COMPLETE, QUEST_LOG_UPDATE, UNIT_QUEST_LOG_CHANGED, PLAYER_XP_UPDATE, PLAYER_LEVEL_UP, BAG_UPDATE, LEARNED_SPELL_IN_TAB, CHAT_MSG_LOOT, SPELLCAST_STOP, and more
- **Location:** `Core/Events/` directory (Quests.lua, Character.lua, Items.lua, Gossip.lua, Taxi.lua, Talents.lua)
- **Why:** Detects in-game state changes (quest completion, item collection, level-up, flight arrival)

**pfQuest Addon Integration (Optional):**
- **Service:** pfQuest addon (if installed)
- **What it's used for:** Minimap node detection and avoidance - automatically disables pfQuest nodes when guide paths are enabled to reduce minimap clutter
- **Integration:** Reads/modifies `pfQuest_config` table when available
- **Location:** `Core/MinimapPath.lua:55-90` (pfQuest integration functions)
- **State Saving:** Saves pfQuest config state before disabling, restores original settings when guide paths are disabled
- **Config keys toggled:** `minimapnodes`, `showspawn`, `showcluster`, `showspawnmini`, `showclustermini`, `routes`
- **Safe:** Only modifies pfQuest if it exists and was actually enabled before addon interaction
- **How it works:** When minimap or world map path is enabled, saves pfQuest state and disables its nodes; when both paths disabled, restores original config and calls `pfMap:UpdateMinimap()` and `pfMap:UpdateNodes()`

## Data Storage

**Databases:**
- **Type:** Embedded Lua table format (ShaguDB)
- **Location:** `Assets/db/`
  - Quests: `Assets/db/enUS/quests.lua`
  - NPCs: `Assets/db/enUS/units.lua`
  - Items: `Assets/db/enUS/items.lua`
  - Zones: `Assets/db/enUS/zones.lua`
  - Objects: `Assets/db/objects.lua`, `Assets/db/areatrigger.lua`
- **Client:** Loaded at addon init via XML manifest
- **Connection:** No connection needed - all data embedded as compiled Lua tables in VGDB global
- **Structure:**
  ```lua
  VGDB["quests"]["enUS"][questId] = {
    ["T"] = "Title",
    ["O"] = "Objectives",
    ["D"] = "Description",
    ["start"] = {["U"] = {npcId}},  -- Quest giver
    ["end"] = {["U"] = {npcId}}     -- Turn-in NPC
  }
  VGDB["units"]["data"][npcId] = {["coords"] = {{x, y, zoneId}, ...}}
  VGDB["items"]["data"][itemId] = {["U"] = {...}, ["O"] = {...}}  -- Drop sources
  ```

**Character Settings:**
- **Type:** WoW SavedVariablesPerCharacter via AceDB
- **Variable:** `GuidelimeVanillaDB`
- **Location:** `%APPDATA%\World of Warcraft\WTF\Account\AccountName\Realm\Character\SavedVariables\GuidelimeVanilla.lua` (file location in WoW)
- **Client:** AceDB-2.0
- **Management:** `GLV.Settings` object provides `GetOption()` and `SetOption()` API for nested key access
- **Scope:** Per-character, survives `/reload`, persists across sessions
- **Key tables stored:**
  - `CharInfo` - Character identity (name, realm, faction, race, class)
  - `Guide` - Active guide pack, current guide, step state, visited NPC tracking
  - `QuestTracker` - Accepted quest IDs, completed quest IDs
  - `TaxiTracker` - Learned taxi node IDs
  - `Automation` - Auto-accept/turnin/flight settings
  - `Talents` - Active templates per class, respec completion state, toast position

**File Storage:**
- None used - addon is read-only, all assets embedded

**Caching:**
- None external - all data cached in memory during session
- Item icon texture fetching: Queries WoW item database at step load time via `GetItemIcon(itemId)` and caches result in step data

## Authentication & Identity

**Auth Provider:**
- None - WoW handles authentication to Turtle WoW server
- Character identity obtained via WoW API at addon load: `UnitName()`, `UnitClass()`, `UnitRace()`, `UnitFactionGroup()`, `GetRealmName()`
- This data stored in settings under `CharInfo` table

## Monitoring & Observability

**Error Tracking:**
- None external
- Errors logged to WoW chat via `DEFAULT_CHAT_FRAME:AddMessage()`
- Debug mode: `GLV.Debug = true` enables verbose logging in `Core.lua`

**Logs:**
- In-game chat logs only
- Messages prefixed with color codes (e.g., `|cFF6B8BD4[GuideLime]|r`)
- Example: `"|cFF6B8BD4[GuideLime]|r Quest completed: [questName]"`

## CI/CD & Deployment

**Hosting:**
- Git repository (GitHub or local)
- Distribution: Addon folder copied to `Interface\AddOns\GuidelimeVanilla\` in WoW installation

**CI Pipeline:**
- None automated
- Pre-push agents (user-run, not CI/CD):
  - `claude-md-updater` - Updates CLAUDE.md after commits
  - `readme-feature-sync` - Syncs README with implemented features before push
  - `version-bump-prepush` - Increments version before pushing (patch for ≤6 commits, minor for >6 commits)

**Version Management:**
- Version stored in `.toc` file: `## Version: 0.7.2`
- Read at runtime via `GetAddOnMetadata(_ADDON_NAME, "Version")`
- Displayed in chat on addon load and in window title

## Addon Dependencies

**Soft Dependencies (Optional):**
- **pfQuest** - If installed, guide path rendering will auto-disable its nodes to reduce clutter
  - Location checked: `Core/MinimapPath.lua:56` - `if not pfQuest_config then return end`
  - Impact if missing: No impact - addon works fully without pfQuest installed

**No Hard Dependencies:**
- All required libraries (LibStub, Ace libs, Astrolabe) are bundled in `Assets/libs/`
- No external addons required

**Guide Packs (Soft Dependencies):**
- Guides distributed as separate addons that depend on GuidelimeVanilla
- Example dependency line in guide pack `.toc`: `## Dependencies: GuidelimeVanilla`
- Guide packs register themselves via: `GLV.guidePackAddons["Pack Name"] = "AddonName"`
- User must manually select and load pack via Settings > Guides (no auto-loading)

## Webhooks & Callbacks

**Incoming:**
- None - addon is single-player local only

**Outgoing:**
- None - addon makes no external network calls

**Internal Event System:**
- Event-driven architecture via Ace2 event system
- Events: QUEST_DETAIL, QUEST_COMPLETE, QUEST_LOG_UPDATE, PLAYER_XP_UPDATE, PLAYER_LEVEL_UP, BAG_UPDATE, LEARNED_SPELL_IN_TAB, CHAT_MSG_LOOT, SPELLCAST_STOP, ConfirmBinder hook
- Handlers in `Core/Events/` modules register callbacks via `GLV.Ace:RegisterEvent()`
- Custom triggers: Guide step completion hooks when conditions met (quest complete, item collected, spell learned, level requirement reached, hearthstone arrival, etc.)

## Function Hooking

**WoW Function Hooks (via AceHook-2.1):**
- Location: `Core/Events/Quests.lua:33-35`
- Hooks:
  - `QuestDetailAcceptButton_OnClick` - Capture quest accept event, log quest ID
  - `QuestRewardCompleteButton_OnClick` - Capture quest turn-in event, log completion
  - `AbandonQuest` - Capture quest abandonment, remove from tracker
- Purpose: Validate quest automation and step completion detection

**FrameXML Hooks (via AceHook-2.1):**
- Location: `Core/Events/Gossip.lua`
- Hook: `ConfirmBinder` - Detect hearthstone bind at innkeeper
- Purpose: Auto-complete `[S location]` (Set Hearthstone) steps when player binds at inn

## Compatibility Layers

**TomTom Replacement:**
- Addon previously supported TomTom but now has autonomous navigation system
- Comments indicate code origin: "A lot of this code has been copied from TomTom, pfQuest"
- Location: `Core/GuideNavigation.lua:10`
- No TomTom dependency - pure Astrolabe-based implementation with custom arrow rendering

**Talent Frame Detection:**
- Supports both vanilla `TalentFrame` and TWTalent addon `TWTalentFrame`
- Auto-detection at runtime: `_G["TalentFrame"] or _G["TWTalentFrame"]`
- Location: `Core/Events/Talents.lua:200+`

**Spell API Fallback Chain:**
- Primary: Nampower `GetSpellNameAndRankForId(spellId)` for detailed spell info
- Secondary: Vanilla `GetSpellIdForName(spellName)` to check if spell in spellbook
- Tertiary: Skill line matching via `GetSkillLineInfo()` and `GetNumSkillLines()`
- Purpose: Robust spell learning detection across different spell types (combat spells, professions, etc.)

---

*Integration audit: 2026-02-09*
