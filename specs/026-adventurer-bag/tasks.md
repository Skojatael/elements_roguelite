# Tasks: Adventurer Bag

**Input**: Design documents from `specs/026-adventurer-bag/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: User Story 1 — First Elite Clear Permanently Unlocks Adventurer Bag (Priority: P1) 🎯 MVP

**Goal**: Detecting the first elite room clear across all runs permanently sets the Adventurer Bag flag in MetaState and persists it.

**Independent Test**: Fresh profile → run until elite room cleared → quit → check `user://meta_save.json` contains `"adventurer_bag_unlocked": true` → re-enter play mode → confirm flag still true.

- [X] T001 [US1] Add `adventurer_bag_unlocked: bool = false` field to `scripts/data_models/MetaState.gd`
- [X] T002 [US1] Update `save_meta_state()` to write `"adventurer_bag_unlocked": state.adventurer_bag_unlocked` and `load_meta_state()` to read it with `.get("adventurer_bag_unlocked", false)` in `scripts/managers/SaveManager.gd`
- [X] T003 [US1] Add `unlock_adventurer_bag(save_manager: Node) -> bool` to `scripts/managers/MetaManager.gd` (MetaManagerImpl) — sets `meta_state.adventurer_bag_unlocked = true`, calls `save_manager.save_meta_state(meta_state)`, returns `true` on first call and `false` if already unlocked (see contracts/interfaces.md for exact code)
- [X] T004 [US1] In `autoload/MetaManager.gd`: add `is_adventurer_bag_unlocked: bool` computed property (`get: return _impl.meta_state.adventurer_bag_unlocked`); add `RunManager.room_cleared.connect(_on_room_cleared)` in `_ready()`; add `_on_room_cleared(room_id: String)` handler that guards on `RunManager.current_room == null`, reads `room_type_id`, checks `room_type.contains("Elite")`, calls `_impl.unlock_adventurer_bag(SaveManager)`, and prints on unlock (see contracts/interfaces.md for exact code)

---

## Phase 2: User Story 2 — Relic System Gated Until Unlock (Priority: P2)

**Goal**: No relic offer is ever emitted while `MetaManager.is_adventurer_bag_unlocked` is false.

**Independent Test**: Fresh profile → clear 10 rooms including elites (before the unlock triggers — requires profiling) → confirm zero relic offer screens appear. Then unlock → clear 2 standard rooms → confirm relic offer appears.

- [X] T005 [US2] Add `if not MetaManager.is_adventurer_bag_unlocked: return` as the first guard in `_on_room_cleared(room_id: String)` in `autoload/RelicManager.gd` (before the existing `if not RunManager.is_run_active:` check)

---

## Phase 3: Polish

- [ ] T006 Run all 6 quickstart scenarios from `specs/026-adventurer-bag/quickstart.md`

---

## Dependencies & Execution Order

- T001 has no dependencies — start immediately
- T002 requires T001 complete (references `MetaState.adventurer_bag_unlocked`)
- T003 requires T001 complete (references `meta_state.adventurer_bag_unlocked`)
- T004 requires T003 complete (`_impl.unlock_adventurer_bag()` must exist)
- T005 requires T004 complete (`MetaManager.is_adventurer_bag_unlocked` must be defined)
- T006 requires T001–T005 complete

## Implementation Strategy

1. T001 — add MetaState field
2. T002, T003 — update SaveManager and MetaManagerImpl (both depend only on T001; can be done sequentially or in any order)
3. T004 — wire MetaManager autoload
4. T005 — add RelicManager gate
5. T006 — validate
