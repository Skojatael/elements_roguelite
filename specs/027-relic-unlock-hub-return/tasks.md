# Tasks: Relic Offers Activate on Hub Return

**Input**: Design documents from `specs/027-relic-unlock-hub-return/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Shared data and persistence — required by both user stories before any activation logic can be implemented.

- [X] T001 Add `relic_offers_active: bool = false` field to `scripts/data_models/MetaState.gd`
- [X] T002 [P] Update `save_meta_state()` to write `"relic_offers_active": state.relic_offers_active` and `load_meta_state()` to read it with `.get("relic_offers_active", false)` in `scripts/managers/SaveManager.gd`
- [X] T003 [P] Add `try_activate_relic_offers(save_manager: Node) -> bool` to `scripts/managers/MetaManager.gd` (MetaManagerImpl) — guard on `not meta_state.adventurer_bag_unlocked` (return false), guard on `meta_state.relic_offers_active` (return false), then set `meta_state.relic_offers_active = true`, call `save_manager.save_meta_state(meta_state)`, return `true` (see contracts/interfaces.md for exact code)

**Note**: T002 and T003 both require T001 but touch different files — they can run in parallel after T001 completes.

**Checkpoint**: MetaState, SaveManager, and MetaManagerImpl are ready. User story implementation can begin.

---

## Phase 2: User Story 1 — Relic Offers Withheld Until Hub Return After Unlock (Priority: P1) 🎯 MVP

**Goal**: The `GlobalSignals.hub_entered` signal is emitted when the hub is entered, MetaManager activates relic offers on the first such signal while the bag is unlocked, and RelicManager uses the new gate.

**Independent Test**: Fresh profile → clear elite room → clear 4 more rooms (same run) → confirm zero relic offers → end run → press "Return" → check Output for `[MetaManager] relic offers activated` → start new run → clear 2 standard rooms → confirm relic offer appears.

- [X] T004 [US1] Add `signal hub_entered()` with `@warning_ignore("unused_signal")` and a doc comment to `autoload/GlobalSignals.gd` (see contracts/interfaces.md for exact code)
- [X] T005 [US1] In `autoload/MetaManager.gd`: add `is_relic_offers_active: bool` computed property (`get: return _impl.meta_state.relic_offers_active`); add `GlobalSignals.hub_entered.connect(_on_hub_entered)` in `_ready()`; add `_on_hub_entered()` handler that calls `_impl.try_activate_relic_offers(SaveManager)` and prints if `activated` is `true` (see contracts/interfaces.md for exact code)
- [X] T006 [US1] In `scenes/core/Main.gd`: add `GlobalSignals.hub_entered.emit()` immediately after `add_child(_hub_room)` in `_ready()` AND immediately after `add_child(_hub_room)` in `_on_results_return()` — two separate emit lines in two separate methods (see contracts/interfaces.md for exact code)
- [X] T007 [US1] In `autoload/RelicManager.gd`, in `_on_room_cleared()`, change the gate from `if not MetaManager.is_adventurer_bag_unlocked:` to `if not MetaManager.is_relic_offers_active:` (one word change in the condition)

---

## Phase 3: User Story 2 — Backward Compatibility for Existing Saves (Priority: P2)

**Goal**: Players with `adventurer_bag_unlocked: true` in their save but no `relic_offers_active` key automatically receive relic offers after their next hub visit. No additional code tasks — this is fully covered by T003 (try_activate_relic_offers guards on bag=true, offers=false) and T006 (Main._ready() emits hub_entered at game start, which is already "in the hub").

**Independent Test**: Edit `user://meta_save.json` to set `"adventurer_bag_unlocked": true` with no `relic_offers_active` key → start editor play mode → check Output for `[MetaManager] relic offers activated` → start a run → clear 2 rooms → confirm relic offer appears.

*(No code tasks — covered by T003 + T006 design.)*

---

## Phase 4: Polish

- [ ] T008 Run all 7 quickstart scenarios from `specs/027-relic-unlock-hub-return/quickstart.md`

---

## Dependencies & Execution Order

- T001 has no dependencies — start immediately
- T002, T003 require T001 complete; they are independent of each other [P] after T001
- T004 has no dependencies — can run in parallel with T001/T002/T003 (different file)
- T005 requires T003 and T004 complete (`_impl.try_activate_relic_offers` and `GlobalSignals.hub_entered` must both exist)
- T006 requires T004 complete (`GlobalSignals.hub_entered` must exist before emitting)
- T007 requires T005 complete (`MetaManager.is_relic_offers_active` must be defined)
- T008 requires T001–T007 complete

## Implementation Strategy

1. T001 — MetaState field
2. T002, T003, T004 — three files, all parallelizable (T002+T003 need T001, T004 is independent)
3. T005, T006 — parallelizable (both need T004; T005 also needs T003)
4. T007 — gate swap (needs T005)
5. T008 — validate
