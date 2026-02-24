# Plan: Optional pfQuest + Completed-Quest Sync

## Goal

When a user loads a guide after already having done some quests (or uses pfQuest’s journal of completed quests), automatically mark **already-done** quest steps so the guide starts at the right place.

- **[QA]** steps: mark done if the quest is **in log** (current) **or already completed** (turned in).
- **[QT]** steps: mark done if the quest is **not in log** because it was **already turned in** (bulk sync on guide load, not only when the step becomes current).

pfQuest remains **optional**: if present, use `pfQuest_history`; otherwise use GuideLime’s `store.Completed` only.

---

## Data Sources

| Source | When populated | Use for |
|--------|----------------|--------|
| **Quest log** | WoW API | Quest in progress (in log) → [QA] done |
| **QuestTracker.store.Completed** | Our turn-in hook | Quest turned in (this session or persisted) → [QA] and [QT] done |
| **pfQuest_history** (optional) | pfQuest on turn-in | Same as Completed; use when pfQuest is loaded |

**Helper:** “Is quest completed (turned in)?” = `store.Completed[questId]` **or** (`pfQuest_history` and `pfQuest_history[questId]`).

---

## 1. QA sync: also treat “already completed” as done

**File:** `Core/Events/Quests.lua`  
**Function:** `SyncQuestAcceptSteps()`

**Current behavior:** Mark [QA] only when the quest is **in the quest log**.

**Change:** After building `inLogIds`, also consider “completed”:

1. Add a helper (local or on QuestTracker), e.g. `QuestTracker:IsQuestCompleted(questId)`:
   - Return true if `self.store.Completed[numId]`.
   - If global `pfQuest_history` exists and `pfQuest_history[questId]` is set, return true.
   - Otherwise false.

2. In the loop that marks QA steps (where we currently check `if inLogIds[numId]`), also mark when **not** in log but **completed**:
   - `if inLogIds[numId] then` → keep current logic (mark ACCEPT, update store.Accepted).
   - `elseif self:IsQuestCompleted(numId) then` → call `MarkQuestAction(numId, <title or "">, "ACCEPT")` (title can be from DB or empty; matching uses questId). Do **not** add to store.Accepted (quest is gone from log).

3. Use the same `anyStepMarked` / `anyMultiAction` and existing `UpdateStepNavigation` + optional `CheckCurrentStepXPRequirements` so UI and current step update.

**Multi-action:** No change. Each [QA] is still one action key; step completes when all actions (QA + any QT/QC on the step) are done.

---

## 2. QT sync: bulk-mark turn-in steps from “completed” list

**File:** `Core/Events/Quests.lua`  
**New function:** e.g. `QuestTracker:SyncTurninStepsFromCompleted()`

**Behavior:**

1. If `not GLV.CurrentDisplaySteps` then return.
2. Load `currentGuideId`, `stepQuestState`, `stepState`, `diToOrig` (same pattern as SyncQuestAcceptSteps).
3. For each display step with `step.questTags`:
   - For each `questTag` where `questTag.tag == "TURNIN"`:
     - If this action is already marked in `stepQuestState[origIdx][BuildActionKey(questTag)]`, skip.
     - If quest is **not** in log and **is** completed (same `IsQuestCompleted(questId)`), then:
       - Set `stepQuestState[origIdx][BuildActionKey(questTag)] = true`.
       - Set `anyStepMarked = true` (and if step has multiple quest tags, set `anyMultiAction` as needed).
4. For each step that had any update, check `AreAllActionsDone(stepQuestState, origIdx, step.questTags)`; if true, set `stepState[origIdx] = true`.
5. Persist: `GLV.Settings:SetOption(stepQuestState, {...})` and `SetOption(stepState, {...})`.
6. If any step was marked, call `UpdateStepNavigation(true, anyMultiAction, "TURNIN")` and optionally `CheckCurrentStepXPRequirements`, then `GLV:RefreshGuide()` so checkboxes and current step update.

**Optional:** Only run SyncTurninStepsFromCompleted when “completed” source exists: e.g. `if not self.store.Completed or not next(self.store.Completed) then if not pfQuest_history or not next(pfQuest_history) then return end end` (pseudocode). Avoids work when there’s nothing to sync.

**Multi-action:** Handled by per-action keys and `AreAllActionsDone`; steps with e.g. [QT2281] [QA2282] complete only when both actions are done (QA can be filled by SyncQuestAcceptSteps or in-log/completed logic).

---

## 3. When to run the sync

| Trigger | Sync QA (enhanced) | Sync QT (new) |
|--------|--------------------|----------------|
| **OnQuestLogUpdate** | Yes (existing call to SyncQuestAcceptSteps) | Yes, call SyncTurninStepsFromCompleted after SyncQuestAcceptSteps (or in same pass) so new turn-ins are reflected quickly. |
| **Guide load** | Yes (existing: LoadGuide → … → SyncQuestAcceptSteps in GuideLibrary) | Yes, call SyncTurninStepsFromCompleted **after** guide steps are built and **after** SyncQuestAcceptSteps so all steps exist and QA is already synced. |

**Suggested call sites:**

- **Core/Events/Quests.lua** – `OnQuestLogUpdate`: after `self:SyncQuestAcceptSteps()`, call `self:SyncTurninStepsFromCompleted()`.
- **Core/GuideLibrary.lua** – `LoadGuide`: after `GLV.QuestTracker:SyncQuestAcceptSteps()` (both call sites around 537 and 557), call `GLV.QuestTracker:SyncTurninStepsFromCompleted()`.

No new events needed; reuse existing triggers.

---

## 4. pfQuest detection (optional)

- Use a **runtime check**: e.g. `if pfQuest_history and type(pfQuest_history) == "table" then ... end` inside `IsQuestCompleted` and (if desired) at the start of SyncTurninStepsFromCompleted.
- Do **not** add pfQuest as a dependency in the .toc; addon must work without it.
- Same pattern as existing pfQuest use (e.g. MinimapPath and `pfQuest_config`): check for global, use if present, else rely on store.Completed only.

---

## 5. Helper: IsQuestCompleted(questId)

**Location:** `Core/Events/Quests.lua` (QuestTracker).

**Logic:**

- `local numId = tonumber(questId); if not numId then return false end`
- If `self.store.Completed[numId]` then return true.
- If `pfQuest_history` exists and `pfQuest_history[numId]` is set (or `pfQuest_history[questId]` if key can be string), return true.
- Return false.

**Edge cases:**

- Same-name chain: we key by questId; store and pfQuest_history are per-ID, so correct.
- Don’t rely on quest name for this helper; ID is enough.

---

## 6. Order of operations on guide load

1. Load guide, parse, create steps (existing).
2. Restore StepState / StepQuestState from saved (existing).
3. **SyncQuestAcceptSteps** (existing): marks [QA] for quests in log; **with change**, also for quests that are completed (store.Completed or pfQuest_history).
4. **SyncTurninStepsFromCompleted** (new): marks [QT] for quests not in log but completed.
5. Recompute current step (UpdateStepNavigation or equivalent) and refresh UI (RefreshGuide) if anything was marked.

This order ensures multi-action steps (e.g. [QT2281] [QA2282] or [QA125] [QA89]) get both QA and QT filled where applicable before we decide “first unchecked” step.

---

## 7. Files to touch

| File | Changes |
|------|--------|
| **Core/Events/Quests.lua** | Add `IsQuestCompleted(questId)`; extend `SyncQuestAcceptSteps()` to mark [QA] when quest completed; add `SyncTurninStepsFromCompleted()`; call SyncTurninStepsFromCompleted from `OnQuestLogUpdate` after SyncQuestAcceptSteps. |
| **Core/GuideLibrary.lua** | After each `GLV.QuestTracker:SyncQuestAcceptSteps()`, call `GLV.QuestTracker:SyncTurninStepsFromCompleted()`. |
| **CLAUDE.md** (optional) | Short note under QuestTracker: optional pfQuest_history + store.Completed for QA/QT sync; SyncTurninStepsFromCompleted; IsQuestCompleted. |

No new files required; no changes to parser or GuideWriter.

---

## 8. Testing checklist

- [ ] New character, no pfQuest: behavior unchanged (no completed list).
- [ ] With pfQuest, load guide: [QT] steps for completed quests (in pfQuest_history) get checked; [QA] for completed quests get checked.
- [ ] Without pfQuest, after turning in a quest (store.Completed): reload guide → corresponding [QT] and [QA] steps for that quest are checked.
- [ ] Multi-action: [QT2281] [QA2282] – 2281 completed, 2282 in log → step completes after sync.
- [ ] Multi-action: [QA125] [QA89] – both completed (store or pfQuest) → step completes after sync.
- [ ] Same-name chain: only the correct quest ID is marked (no cross-talk).
- [ ] Current step advances correctly after sync (first unchecked step and RefreshGuide).

---

## 9. Summary

- **QA:** Mark [QA] done when quest is **in log** (current) **or** **completed** (store.Completed or pfQuest_history) via extended SyncQuestAcceptSteps and a small IsQuestCompleted helper.
- **QT:** Bulk-mark [QT] when quest is **completed** (store.Completed or pfQuest_history) via new SyncTurninStepsFromCompleted, called on guide load and OnQuestLogUpdate.
- **Optional pfQuest:** Use `pfQuest_history` only when the global exists; no .toc dependency.
- **Multi-action steps:** Unchanged; per-action keys and AreAllActionsDone already handle [QA]+[QA] and [QT]+[QA] steps.

This plan gives a clear path to implement the feature without changing guide syntax or step structure.
