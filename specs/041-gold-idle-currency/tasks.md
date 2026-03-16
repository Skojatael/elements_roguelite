# Tasks: Gold Idle Currency

**Input**: Design documents from `/specs/041-gold-idle-currency/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the one config key that all other tasks depend on.

- [x] T001 Add `"gold_rate_per_hour": 100` as a top-level key to `data/meta_config.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data model + persistence + atomic save helper. MUST complete before any user story begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Add `var total_gold: float = 0.0` and `var gold_last_saved_timestamp: int = 0` to `scripts/data_models/MetaState.gd`
- [x] T003 Extend `SaveManagerImpl` in `scripts/managers/SaveManager.gd`: add `"total_gold"` and `"gold_last_saved_timestamp"` to the `save_meta_state` data dictionary; add corresponding reads in `load_meta_state` with backward-compatible defaults (`0.0` and `0`)
- [x] T004 Add private `_save(save_manager: SaveManagerImpl) -> void` helper to `MetaManagerImpl` (`scripts/managers/MetaManager.gd`) that sets `meta_state.gold_last_saved_timestamp = int(Time.get_unix_time_from_system())` then calls `save_manager.save_meta_state(meta_state)`; refactor all existing `save_manager.save_meta_state(meta_state)` callsites in the same file to route through `_save()` instead

**Checkpoint**: MetaState carries the two new fields; every save path writes them atomically with the current timestamp. User story work can now begin.

---

## Phase 3: User Story 1 — See Gold Balance in Hub (Priority: P1) 🎯 MVP

**Goal**: Player sees a "Gold: N" label in the hub on launch, showing offline credit already applied.

**Independent Test**: Launch the game (with or without an existing save file), enter the hub — verify a gold label appears near ShardDisplay showing a non-negative integer.

### Tests for User Story 1 ⚠️ Write and confirm FAIL before implementing T007

- [x] T005 [P] [US1] Write GUT unit test file `tests/unit/test_meta_manager_impl_gold.gd`: cover `apply_offline_gold` with an inline stub MetaState — four cases: (1) timestamp == 0 → gold unchanged, (2) elapsed 3600s at rate 100 → gold += 100.0, (3) elapsed negative (clock rollback) → gold unchanged, (4) elapsed 1800s → gold += 50.0; no autoloads required

### Implementation for User Story 1

- [x] T006 [US1] Add `apply_offline_gold(now_unix: int, rate_per_hour: float, save_manager: SaveManagerImpl) -> void` to `MetaManagerImpl` (`scripts/managers/MetaManager.gd`): guard `if meta_state.gold_last_saved_timestamp == 0: return`; compute `elapsed = now_unix - meta_state.gold_last_saved_timestamp`; guard `if elapsed <= 0: return`; add `float(elapsed) * rate_per_hour / 3600.0` to `meta_state.total_gold`; call `_save(save_manager)` (depends on T004)
- [x] T007 [P] [US1] Add `signal gold_changed(new_floor: int)`, `var total_gold: float` (computed: `_impl.meta_state.total_gold`), and `var _last_gold_floor: int = 0` to `autoload/MetaManager.gd`
- [x] T008 [US1] Extend `MetaManager._ready()` in `autoload/MetaManager.gd` (after `_impl.load(SaveManager)`): read rate via `ResourceManager.get_meta_config().get("gold_rate_per_hour", 100.0)`; call `_impl.apply_offline_gold(int(Time.get_unix_time_from_system()), rate, SaveManager._impl)`; set `_last_gold_floor = floori(meta_state.total_gold)`; emit `gold_changed.emit(_last_gold_floor)` (depends on T006, T007)
- [x] T009 [P] [US1] Write `scenes/hub/GoldDisplay.gd`: `@export var _label: Label`; in `_ready()` set `_label.text = "Gold: {n}".format({"n": floori(MetaManager.total_gold)})`; connect `MetaManager.gold_changed` to a lambda that updates `_label.text = "Gold: {n}".format({"n": new_floor})`
- [ ] T010 [US1] **Editor task**: Create `scenes/hub/GoldDisplay.tscn` in the Godot Editor — root node `Control`, attach `GoldDisplay.gd`; add a `Label` child node; assign the Label to the `_label` export in the Inspector
- [ ] T011 [US1] **Editor task**: Open `scenes/hub/HubRoom.tscn` in the Godot Editor; add a `GoldDisplay` instance as a sibling of the existing `ShardDisplay` node, positioned directly above or below it

**Checkpoint**: Launch game → hub loads → "Gold: N" label is visible. US1 is independently testable.

---

## Phase 4: User Story 2 — Gold Visibly Increments in Hub (Priority: P2)

**Goal**: While in the hub, the gold label ticks upward in real time with no player action.

**Independent Test**: Enter the hub, watch the gold label for 36 seconds — it increments by at least 1 (at 100/hr rate).

### Tests for User Story 2 ⚠️ Write and confirm FAIL before implementing T013

- [x] T012 [P] [US2] Add `tick_gold` test cases to `tests/unit/test_meta_manager_impl_gold.gd`: (1) call `tick_gold(3600.0, 100.0)` → returns 100 and `meta_state.total_gold == 100.0`; (2) call `tick_gold(0.5, 100.0)` 7200 times → `total_gold` close to 100.0; (3) `tick_gold` does not call save (verify `gold_last_saved_timestamp` unchanged)

### Implementation for User Story 2

- [x] T013 [US2] Add `tick_gold(delta: float, rate_per_hour: float) -> int` to `MetaManagerImpl` (`scripts/managers/MetaManager.gd`): `meta_state.total_gold += delta * rate_per_hour / 3600.0`; return `floori(meta_state.total_gold)` (no save — save cadence governed by existing triggers)
- [x] T014 [US2] Add `_process(delta: float) -> void` to `autoload/MetaManager.gd`: read rate from `ResourceManager.get_meta_config().get("gold_rate_per_hour", 100.0)`; call `var new_floor: int = _impl.tick_gold(delta, rate)`; guard `if new_floor == _last_gold_floor: return`; set `_last_gold_floor = new_floor`; emit `gold_changed.emit(new_floor)` (depends on T013)

**Checkpoint**: Hub gold label increments in real time. US1 and US2 both work independently.

---

## Phase 5: User Story 3 — Offline Gold Generation (Priority: P3)

**Goal**: Gold earned while the game is closed is credited automatically on next launch.

**Independent Test**: Note gold balance, close game, wait 1 minute, reopen — gold increased by ~1.67.

> **Note**: The implementation for US3 is fully contained in `apply_offline_gold` (completed in Phase 3, T006). This phase focuses on edge-case coverage and runtime validation.

### Tests for User Story 3 ⚠️ Add to existing test file before runtime validation

- [ ] T015 [P] [US3] Add new-player edge case to `tests/unit/test_meta_manager_impl_gold.gd`: construct a fresh MetaState (timestamp == 0), call `apply_offline_gold(current_unix, 100.0, stub_save)` — verify `total_gold` remains 0.0 and no save occurs (timestamp still 0)

### Validation for User Story 3

- [ ] T016 [US3] Runtime validation — offline credit: in a running game, open `user://meta_save.json` via the Godot editor FileSystem or OS file explorer; set `gold_last_saved_timestamp` to `(Time.get_unix_time_from_system() - 3600)` and `total_gold` to `0`; save the file; relaunch the game — verify the hub shows "Gold: 100" on load
- [ ] T017 [US3] Runtime validation — backward compatibility: delete `user://meta_save.json` entirely; relaunch the game — verify hub shows "Gold: 0" with no crash or error

**Checkpoint**: All three user stories work independently and the offline path is validated.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T018 [P] Runtime validation — clock rollback guard: with a valid save file, temporarily set the system clock to a past time and relaunch — verify gold does not decrease and no errors are logged
- [ ] T019 [P] Runtime validation — atomic save pair: make a shard purchase (which triggers save); open `user://meta_save.json`; verify both `total_gold` and `gold_last_saved_timestamp` are present and `gold_last_saved_timestamp` reflects a recent Unix timestamp (within a few seconds of the purchase)
- [ ] T020 Run the full validation checklist from `specs/041-gold-idle-currency/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on T001 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 complete — T005 can start immediately (test); T006–T011 depend on T004
- **US2 (Phase 4)**: Depends on Phase 2 complete; T012 can start with US1; T013–T014 depend on T007 (gold_changed signal)
- **US3 (Phase 5)**: Depends on Phase 3 complete (apply_offline_gold must exist for runtime validation)
- **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1)**: Foundational done → independently implementable → MVP
- **US2 (P2)**: Foundational done + T007 (signal) done → independently testable
- **US3 (P3)**: US1 complete (apply_offline_gold) → runtime validation only, no new code

### Within Each Story

- Test tasks (`T005`, `T012`, `T015`) MUST be written and confirmed failing before their paired implementation tasks
- T006 (apply_offline_gold) depends on T004 (_save helper)
- T008 (_ready extension) depends on T006 and T007
- T014 (_process) depends on T013 (tick_gold) and T007 (signal)
- Editor tasks (T010, T011) can only start after GoldDisplay.gd (T009) is written

### Parallel Opportunities

- T001 can start immediately; T002–T004 can follow in parallel with T001 since they're all different files
- Within Phase 2: T002 (MetaState) and T003 (SaveManagerImpl) are different files and can run in parallel; T004 depends on T002
- Within Phase 3: T005 (test) and T007 (signal) and T009 (GoldDisplay.gd) are all different files — can run in parallel
- Within Phase 4: T012 (test) can run in parallel with any Phase 3 task once T007 is done

---

## Parallel Example: User Story 1

```
# These three tasks touch different files — launch together:
T005  → tests/unit/test_meta_manager_impl_gold.gd   (write failing tests)
T007  → autoload/MetaManager.gd                      (signal + property)
T009  → scenes/hub/GoldDisplay.gd                    (display script)

# Then sequentially:
T006  → scripts/managers/MetaManager.gd              (apply_offline_gold, needs T004)
T008  → autoload/MetaManager.gd                      (ready extension, needs T006 + T007)
T010  → Godot Editor: GoldDisplay.tscn               (needs T009)
T011  → Godot Editor: HubRoom.tscn                   (needs T010)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T004)
3. Complete Phase 3: User Story 1 (T005–T011)
4. **STOP and VALIDATE**: Gold label appears in hub with correct initial value
5. US1 is the shippable MVP — gold is visible and offline credit works

### Incremental Delivery

1. T001–T004 → Foundation ready
2. T005–T011 → US1: Gold label in hub (MVP)
3. T012–T014 → US2: Real-time increment in hub
4. T015–T017 → US3: Offline validation
5. T018–T020 → Polish

---

## Notes

- [P] tasks touch different files and can run in parallel
- Editor tasks (T010, T011) require the Godot Editor — cannot be done via script
- `_process()` in an autoload Node runs every frame in all scenes; `tick_gold` is O(1) — no performance concern
- Commit after each logical group: after Phase 2, after each phase's checkpoint
- The GUT test file at `tests/unit/test_meta_manager_impl_gold.gd` may need to be placed in the project's existing GUT test directory — check `tests/` structure before creating
