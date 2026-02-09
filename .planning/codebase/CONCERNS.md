# Codebase Concerns

**Analysis Date:** 2026-02-09

## Tech Debt

**Monolithic Navigation System:**
- Issue: `GuideNavigation.lua` is 1,746 lines with 40+ public methods, handling arrow rendering, multi-waypoint sequences, XP progress, next guide transitions, hearthstone automation, and frame management all in one module
- Files: `Core/GuideNavigation.lua`
- Impact: Difficult to test individual features in isolation, hard to modify waypoint logic without affecting unrelated systems, high cognitive load for maintenance
- Fix approach: Extract waypoint sequencing logic into separate `WaypointSequencer` module, move frame management to dedicated `NavigationUI` module, create separate handler for each navigation mode (arrow, XP, hearthstone, etc.)

**Large, Complex Conditional Trees in Event Handlers:**
- Issue: `QuestTracker:HandleQuestAction()` (lines 241-361) has deeply nested conditionals with multiple loop iterations and state checks, making logic flow hard to follow and prone to edge case bugs
- Files: `Core/Events/Quests.lua` lines 241-361
- Impact: New quest-related bugs likely to emerge, difficult to add quest features safely, hard to debug unexpected step completions
- Fix approach: Break into focused handler functions (`_handleQuestCompletion()`, `_handleQuestAcceptance()`, `_validateObjectiveMatch()`) with clear contracts, add comprehensive test coverage for quest matching edge cases

**Database Query Chains Without Error Accumulation:**
- Issue: `GetQuestAllCoords()` (lines 262-537 in DBTools.lua) chains 12+ deep VGDB lookups (quest → NPC → coords → items → units, etc.) with local guards but no centralized validation, leading to partial results if any intermediate step fails silently
- Files: `Helpers/DBTools.lua` lines 262-537
- Impact: Navigation may succeed with incomplete/incorrect coordinates if database entries are malformed or missing, silent failures hard to detect
- Fix approach: Add structured error tracking with logging at each VGDB access, create `CoordResult` type with `{coords, warnings, source}` to track data quality, return early with debug info if critical path fails

**pfQuest Integration Assumptions:**
- Issue: `MinimapPath.lua` lines 55-108 assumes `pfQuest_config` global exists and is mutable, directly modifies its state without versioning checks or API validation
- Files: `Core/MinimapPath.lua` lines 55-108
- Impact: If pfQuest changes API or is unloaded mid-session, state restoration may fail silently or cause pfQuest to malfunction, no recovery mechanism
- Fix approach: Wrap pfQuest access in try-catch style checks, test for presence of expected config keys before modifying, add explicit reversion on addon unload or pfQuest disable

## Known Bugs

**Nil Waypoint Z-coordinate in Zone Transitions:**
- Symptoms: Navigation frame hides unexpectedly when stepping between zones, "waypoint.z nil" appears in debug minimap output
- Files: `Core/GuideNavigation.lua` lines 457-463, `Core/MinimapPath.lua` lines 195-198
- Trigger: Player crosses zone boundary while waypoint data was cached with unresolved zone name (e.g., waypoint from [G] tag with zoneName but z not yet populated)
- Workaround: Reload guide (`/glv show` after hiding, then reload) to recalculate waypoints with correct zone context
- Root cause: Waypoint zone resolution deferred to first navigation update; if player zones before update runs, waypoint.z remains nil. Secondary fix exists (lines 457-463) but doesn't fully prevent race condition.

**Quest Matching Inconsistency Across Name-Based Lookups:**
- Symptoms: Auto-turnin or auto-accept may fail for quests with special characters or multiple names, quest completion detection matches wrong quest when quest names collide
- Files: `Core/Events/Quests.lua` lines 540-567 (QuestNamesMatch uses 3 fallback patterns), `Helpers/DBTools.lua` lines 155-176 (questNameCache)
- Trigger: Quest titles with punctuation (e.g., "A: Something" vs "A: Something..."), multi-part quest chains with same name, names that match after stripping punctuation
- Workaround: Rely on quest ID only, disable auto-accept/turnin for multi-part quests
- Root cause: No single canonical quest name format; VGDB, WoW quest log, and guide files may have different punctuation/formatting. QuestNamesMatch covers most cases but creates false positives for similar-named quests.

**Multiple Objective Completion Firing Same Step Completion:**
- Symptoms: Step marked complete multiple times (performance hit), RefreshGuide called redundantly, step navigation jumps ahead unexpectedly
- Files: `Core/Events/Quests.lua` lines 188-201, CheckQuestObjectives doesn't prevent re-firing for already-completed objectives
- Trigger: Quest with 3+ objectives; completing objectives 1→2→3 in rapid succession, each triggers HandleQuestAction separately
- Workaround: Objectives currently throttled at 0.5s via OnQuestLogUpdate, but individual objective completion events not deduplicated
- Root cause: `previousQuestStates` tracks objectives but doesn't skip re-processing; each new objective completion causes full step validation loop

**Minimap Dots Not Hidden on Addon Reload:**
- Symptoms: Minimap dots remain visible after `/reload`, sometimes overlap/flicker if update runs before dots are properly initialized
- Files: `Core/MinimapPath.lua` lines 45-46 (updateFrame and state not persisted across reload), no OnDisable hook
- Trigger: `/reload` UI while navigation is active and minimap path is enabled
- Workaround: Manually click minimap path toggle off, then reload, then back on
- Root cause: Update frame scheduled at addon load (Core.lua line 70, 2.5s delay) may run before MinimapPath:Init() completes if addon loads quickly; dot pool created but updateFrame not started

**Talent Frame Detection May Fail for Custom Talent Mods:**
- Symptoms: Talent highlighting doesn't appear, talent toasts show but talent frame never highlights, custom talent frames (e.g., TWTalentFrame, ElvUI talent UI) not recognized
- Files: `Core/Events/Talents.lua` lines 200-220 (DetectTalentFrame checks only TalentFrame and TWTalentFrame)
- Trigger: Using ElvUI, custom talent UI addon, or other talent frame replacements
- Workaround: None - feature silently disables, use `/glvtalent highlight` command to manually verify
- Root cause: Hard-coded frame name checks; no dynamic frame detection or addon-provided API integration

## Security Considerations

**pfQuest Config Direct Mutation Without Version Check:**
- Risk: If pfQuest addon changes its config table structure or API in an update, GuideLime's direct mutation could corrupt pfQuest data or break its functionality
- Files: `Core/MinimapPath.lua` lines 55-108
- Current mitigation: Config changes are saved/restored in same session, user can re-enable pfQuest features manually
- Recommendations: Add pfQuest version detection before accessing config, implement safer integration using pfQuest events/hooks instead of direct global mutation, add safety checks for all saved state keys before restoration

**VGDB Database Lookups Without Validation:**
- Risk: Malformed VGDB data (negative coordinates, invalid zone IDs, circular references in unit lookups) could cause navigation to invalid locations or infinite loops
- Files: `Helpers/DBTools.lua` lines 35-61 (findClosestUnit), lines 262-537 (GetQuestAllCoords with 12+ nested lookups)
- Current mitigation: Coordinate validation checks for `coordSet[1] and coordSet[2] and coordSet[3]` but doesn't validate ranges (e.g., x,y in 0-100 range), no loop depth limit
- Recommendations: Validate coordinate ranges (0 ≤ x,y ≤ 100), add unit lookup depth counter to prevent infinite recursion, sanitize zone IDs against known zone range, add VGDB version/integrity marker

**No Rate Limiting on Event Handler Loops:**
- Risk: Pathological quest data (e.g., 1000+ quest objectives) could cause frame freezes, quest tracker's nested for-loops over steps/questTags can cause frame lag
- Files: `Core/Events/Quests.lua` lines 269-328 (nested for loops with no iteration limit), lines 84-96 (quest log iteration)
- Current mitigation: Throttle on `lastQuestLogUpdate` at 0.5s, but no per-quest iteration limit
- Recommendations: Add max iteration counters per loop (e.g., max 100 questTags per step), implement progressive processing using scheduled events for large quest logs (>50 entries), add frame performance monitoring to warn if iteration time exceeds 50ms

**Unhandled Ace2 Hook Failures:**
- Risk: If Ace2 hooks fail to apply (e.g., target function doesn't exist or is already hooked), HookQuestAccept/HookQuestComplete may never fire, breaking quest automation without warning
- Files: `Core/Events/Quests.lua` lines 33-35
- Current mitigation: None - hook failures silent, no error callback
- Recommendations: Check hook return value, log warning if hook fails, implement fallback event-based quest detection if hooks unavailable

## Performance Bottlenecks

**Quest Log Iteration on Every QUEST_LOG_UPDATE Event:**
- Problem: `OnQuestLogUpdate()` iterates over ALL quest log entries every time event fires, calls CheckQuestObjectives for every quest even if nothing changed
- Files: `Core/Events/Quests.lua` lines 66-102, registers on QUEST_LOG_UPDATE and UNIT_QUEST_LOG_CHANGED with 0.5s throttle
- Current capacity: Tested with ~20 quests, acceptable performance; at 50+ quests, iteration time may exceed 50ms
- Improvement path: Implement quest log diffing (compare previous state hash before iterating), use GetNumQuestLogEntries to skip unchanged entries, move heavy objective checks to scheduled events if >30 quests in log

**Database Lookups Without Caching (except questNameCache):**
- Problem: `GetQuestAllCoords()` performs fresh lookups on every waypoint calculation, including iterating all NPC/item/object coordinates. No caching of resolved coordinates
- Files: `Helpers/DBTools.lua` lines 262-537, `Core/GuideNavigation.lua` lines 950-1100 calls GetQuestAllCoords on every step change
- Current capacity: Single coordinate lookup takes <10ms for typical quest (1-3 objectives); navigation updates at 0.02s interval, acceptable with 1-2 quests, lag noticeable with 3+ simultaneous quest objectives
- Improvement path: Implement coordinate result cache with quest ID key (invalidate on zone change), lazy-load objective coordinates (load only visible objective, not all), profile with `/gsd profile-code` to find actual bottleneck

**MinimapPath Update Loop at 0.15s Interval:**
- Problem: `MinimapPath` updates minimap and world map dots every 0.15s (6.67 FPS), runs Astrolabe calculations for all 8+12 dots even if no zone change
- Files: `Core/MinimapPath.lua` lines 44, 175-273 (UpdateMinimap), lines 279+ (UpdateWorldMap)
- Current capacity: Acceptable on modern systems; on older machines or with heavy addons, may contribute 2-5ms per frame
- Improvement path: Reduce update frequency to 0.25-0.5s, only recalculate when player moves >1 yard or zone changes (detect with Astrolabe position history), cache Minimap zoom and size to avoid repeated getter calls

**Repeated String Parsing in Guide Writer Text Scaling:**
- Problem: `applyTextScale()` (GuideWriter.lua line 52) calls GetFont() and SetFont() for every FontString on every guide refresh, parsing font file path string for every step line
- Files: `Core/GuideWriter.lua` lines 52-61, 245-250 (applies scale to all text frames)
- Current capacity: Acceptable for guides with <50 steps; guides with 100+ steps may have 200+ FontStrings, scaling all takes ~20ms per refresh
- Improvement path: Cache GetFont() result (font never changes, only multiplier), apply scale once at initial creation instead of on every update, use stylesheet-style font size configuration

**Ongoing Steps Rendering Full Step Data Every Refresh:**
- Problem: `UpdateOngoingObjectivesDisplay()` reconstructs entire pinned section layout on every guide refresh, even if no ongoing steps changed
- Files: `Core/GuideWriter.lua` lines 750-880 (renders all pinned steps with all their content)
- Current capacity: 2-3 ongoing steps acceptable, 5+ shows noticeable slowdown
- Improvement path: Track which steps changed, only re-render modified pinned steps, use frame pooling and reuse instead of create/destroy

## Fragile Areas

**Waypoint Type Detection Logic:**
- Files: `Core/GuideNavigation.lua` lines 350, 527, 598
- Why fragile: Waypoint type is inferred from presence of questId, npcId, objectId, itemId fields rather than explicit type field, making it easy to create waypoints with ambiguous types (e.g., npcId + itemId), code paths diverge based on type in multiple places
- Safe modification: Always set explicit waypoint.type field, validate type against schema before using waypoint, centralize type-based branching into single switch function
- Test coverage: No unit tests for waypoint type combinations; edge case: waypoint with both npcId and itemId should only use npcId, untested

**Step Completion State Machine:**
- Files: `Core/Events/Quests.lua` lines 250-361 (HandleQuestAction), `Core/GuideWriter.lua` lines 966-1100 (rendering step state)
- Why fragile: Multiple state tables track completion (stepState, stepQuestState, previousQuestStates, CheckQuestObjectives), step considered complete when stepQuestState has all actionKeys true, but actionKey construction is fragile (questId + tag + objectiveIndex string concatenation, line 279-282)
- Safe modification: Create StepCompletionTracker class with canonical state schema, validate all mutations through single interface, log state transitions for debugging
- Test coverage: No tests for multi-quest-tag steps, state transitions not verified, race between multiple quest events can corrupt state

**Settings Nested Key Array Access:**
- Files: `Core/GuideNavigation.lua` lines 41-64 (getVisitedNPCs, saveVisitedNPC, clearVisitedNPCs), `Settings.lua` (Settings:GetOption/SetOption)
- Why fragile: Settings accessed via nested arrays like `{"Guide", "Guides", currentGuideId, "VisitedTARs", currentStepIndex}`, no schema validation, missing intermediate keys silently return nil, spelling mistakes create new settings entries
- Safe modification: Define Settings schema upfront, validate all paths at startup, wrap all nested access in guard functions that verify parent keys exist, use constants for key names (not string literals)
- Test coverage: Settings not tested; guide ID/step index validation missing, can create orphaned settings entries if guide is deleted

**CurrentDisplaySteps Array Mapping to UI Frames:**
- Files: `Core/GuideWriter.lua` lines 500-600 (creates frames), `Core/Events/Quests.lua` lines 263-266 (uses CurrentDisplayToOriginal mapping)
- Why fragile: Mapping between display steps array, original steps array, and UI frame names is done via parallel arrays (CurrentDisplaySteps, CurrentDisplayToOriginal, CurrentDisplayHasCheckbox) with no schema, frame names constructed as strings `"GLV_MainScrollFrameScrollChild_Step" .. guideId .. "_" .. displayIndex`
- Safe modification: Create Step object with {displayIndex, originalIndex, frameRef, hasCheckbox} schema, validate all three arrays stay in sync at creation/update, use frame references instead of string names
- Test coverage: No tests for display/original mapping, frame reference tracking, easy to corrupt with out-of-order updates

**Talent Frame Detection and Highlighting:**
- Files: `Core/Events/Talents.lua` lines 200-220 (DetectTalentFrame), line 250+ (UpdateTalentHighlights)
- Why fragile: Hard-coded check for TalentFrame or TWTalentFrame names, if either doesn't exist or is hidden, detection fails silently, highlighting only works on detected frame with no error reporting
- Safe modification: Implement talent frame registry where addons can register their frame, provide fallback detection via IsVisible() polling with timeout, cache detected frame reference and revalidate periodically
- Test coverage: No tests for frame detection, custom talent UI not tested, silent failure if frame not found

## Scaling Limits

**Quest Tracker State for Large Guide Packs:**
- Current capacity: Settings stores `{QuestTracker}` with Accepted/Completed quest dicts; tested with ~50 concurrent quests, settings serialization becomes slow >200 quests
- Limit: At ~500 concurrent quests, settings save/load takes >1s, causes UI freeze
- Scaling path: Implement quest log pruning (remove completed quests after 1 hour), move quest tracking to memory-only cache with periodic checkpoint saves instead of full rewrite, use quest ID ranges instead of full dict for fast checks

**Display Steps Rendering:**
- Current capacity: Guide with ~100 steps renders smoothly; at 200 steps, scroll performance degraded
- Limit: At ~300 steps, frame allocation fails or causes Lua memory spike
- Scaling path: Implement virtual scrolling (only render visible steps + buffer), lazy-load step data from guide on scroll, split mega-guides into multi-part chains with [NX] transitions

**Minimap Dot Pool:**
- Current capacity: 8 dots on minimap, 12 on world map; adequate for navigation
- Limit: Not a hard limit, but more dots would increase update overhead linearly
- Scaling path: If need to support multiple simultaneous waypoints, implement dynamic pool size based on waypoint count

**VGDB Database Size:**
- Current capacity: ShaguDB covers all vanilla zones, ~10MB uncompressed with locale data
- Limit: At full TurtleWoW custom content expansion (new zones, dungeons), database size could hit 50MB+
- Scaling path: Implement lazy-loading of zone-specific data on first load, compress zone data files, cache most-used queries (coordinates) in addon memory

## Dependencies at Risk

**ShaguDB (Assets/db/):**
- Risk: Database is manually maintained; if coordinates become stale due to server content changes (quest givers moved, zone adjustments), guides will navigate to wrong locations with no warning
- Impact: Affects all quest-based navigation, could lead to player confusion or guide failures
- Migration plan: Implement coordinate verification system that logs mismatches when player reaches waypoint (distance, NPC ID validation), create update notification when VGDB is outdated, consider fetching updates from online service

**Astrolabe Library:**
- Risk: External dependency used for coordinate calculations and minimap position mapping; if library has bugs or incompatibilities with custom TurtleWoW maps/zones, navigation fails silently
- Impact: Minimap path rendering and zone detection depend entirely on Astrolabe; any failure breaks navigation
- Migration plan: Wrap Astrolabe calls in try-catch style validation, implement fallback coordinate system using raw zone lookups, test with custom TurtleWoW content to verify zone compatibility

**Ace2 Libraries (AceAddon, AceEvent, AceHook, etc.):**
- Risk: Old Ace2 (2005 era) no longer maintained; WoW API changes or deprecations could break hooks or event registration
- Impact: Quest automation, event-driven features all depend on Ace2 functioning correctly
- Migration plan: Document which Ace2 features are critical (AceAddon, AceEvent, AceHook), test each against current WoW API, plan replacement with custom wrappers for critical hooks if Ace2 breaks

## Missing Critical Features

**Waypoint Radius Detection:**
- Problem: Navigation only marks waypoint reached at 5 yards; some objectives (quest zones, item drops scattered over large area) should complete at 50+ yards or after time duration
- Blocks: Guides for multi-zone quests (e.g., "explore 5 locations") can't be auto-completed without manual step advance
- Fix: Add waypoint properties `{type, radius, duration}` to support variable completion conditions

**Coordinate Validation Against Server State:**
- Problem: No verification that NPC/quest is still at stored coordinates; guide navigates to old location if quest NPC moved or was removed
- Blocks: Guide reliability suffers if server changes content without updating database
- Fix: When reaching waypoint, query live NPC data to verify location, fallback to closest alternative if mismatch detected

**Cross-Guide Waypoint Persistence:**
- Problem: Visited TAR list cleared when switching guides; if guide chains use [NX] transitions, doesn't remember which TAR NPCs already visited
- Blocks: Long quest chains spanning multiple guides have player visit same NPCs twice if switching between guides
- Fix: Store visited TAR list per-pack instead of per-guide, inherit in chained guides via [NX] tag

**Guide Compatibility Matrix:**
- Problem: No way to verify guide is compatible with current character (level, class, faction); players load wrong guides
- Blocks: New players can't self-select appropriate guides, confusion about which pack/guide to use
- Fix: Add guide metadata `{minLevel, maxLevel, allowedClasses, faction}` and validation on load with warning UI

**Performance Profiling UI:**
- Problem: No built-in way to measure which systems (quest tracking, minimap updates, navigation) consume CPU; addon feels slow but can't diagnose cause
- Blocks: Optimizations are guesswork instead of data-driven
- Fix: Add `/glv perf` command showing per-module CPU usage and frame time contribution

## Test Coverage Gaps

**Quest Matching with Special Characters:**
- What's not tested: Quest names with colons, dashes, parentheses, question marks; multi-part quest chains with same base name; quest name case sensitivity
- Files: `Core/Events/Quests.lua` lines 540-567 (QuestNamesMatch), lines 649-679 (GetQuestIdInCurrentStep)
- Risk: Auto-accept/turnin fails silently for non-ASCII names, quest completion detection matches wrong quest
- Priority: High - affects core automation feature used by all guides

**Waypoint Zone Transitions:**
- What's not tested: Player crossing zone boundary while navigation active, waypoint from [G] tag with unresolved zone name, zone context not matching Astrolabe zone list
- Files: `Core/GuideNavigation.lua` lines 300-350 (GetCoordinatesForStep), lines 457-463 (deferred zone resolution), `Core/MinimapPath.lua` lines 195-205 (zone mismatch checks)
- Risk: Navigation arrow hides unexpectedly, minimap dots don't render, player loses guidance mid-quest
- Priority: High - affects navigation reliability across zone boundaries

**Multi-Waypoint Auto-Advancement:**
- What's not tested: Player reaching waypoint, advancing to next, reaching that, then stepping back or re-arriving at first waypoint; transition flag (hasTriggeredTransition) not clearing on distance changes
- Files: `Core/GuideNavigation.lua` lines 574-612 (waypoint arrival logic), lines 26-37 (waypoint tracking state)
- Risk: Waypoint sticks on "reached" state, next waypoint auto-advance doesn't trigger, player can get stuck waiting for manual step advance
- Priority: Medium - affects guides with multiple [G] or [TAR] tags per step

**Ongoing Steps and Step Completion Interaction:**
- What's not tested: Marking ongoing step complete while it's pinned to top of guide, deactivating ongoing step vs completing step, pinned step stays after guide refresh
- Files: `Core/GuideWriter.lua` lines 69-88 (OngoingStepsManager), `Core/Events/Quests.lua` lines 342-344 (Deactivate on completion)
- Risk: Pinned steps not clearing properly, ongoing steps stuck in UI, memory not freed if step references not cleared
- Priority: Medium - affects users who use ongoing steps feature

**XP Progress Display Edge Cases:**
- What's not tested: Level-up while XP bar displayed, relogging at required XP level, XP requirement types (level vs level_plus vs percent) all calculating correctly, xpBar visibility state after step advance
- Files: `Core/GuideNavigation.lua` lines 1466-1513 (XP progress), `Core/Events/Character.lua` (XP update events)
- Risk: XP bar shows wrong values, doesn't turn green on completion, displays from previous step incorrectly
- Priority: Medium - affects leveling guides that use [XP] tags

**pfQuest Integration State Restoration:**
- What's not tested: pfQuest config saving/restoring with partial saves (addon unload mid-save), enabling minimap path when pfQuest is disabled, re-enabling pfQuest after path toggle
- Files: `Core/MinimapPath.lua` lines 55-117 (disablePfQuestNodes, restorePfQuestNodes)
- Risk: pfQuest config corrupted or not restored, nodes stay hidden after disabling path feature
- Priority: Low - edge case, works for most users, but silent failures possible
