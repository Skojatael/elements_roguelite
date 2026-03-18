# Tasks: Boss Continue (Endless Mode)

**Input**: Design documents from `specs/1-boss-continue/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: No mandatory GUT unit tests — no new `*Impl.gd` or static-method scripts introduced. Scene/autoload-dependent integration tests are optional and not included.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Foundational (Blocking Prerequisite)

**Purpose**: Expose `RoomLoader.return_to_room()` before any `Main.gd` changes consume it.

**⚠️ CRITICAL**: T001 must be complete before Phase 2 begins.

- [x] T001 Add public method `return_to_room(room_id: String) -> void` to `scripts/dungeon/RoomLoader.gd` — calls `_load_room(room_id, "")` directly; no other changes to the file

**Checkpoint**: `RoomLoader` now has a public `return_to_room` API. Phase 2 can begin.

---

## Phase 2: User Story 1 — Continue After Boss Kill (Priority: P1) 🎯 MVP

**Goal**: "Continue" button returns the player to the dungeon room they left from, keeping the run active.

**Independent Test**: Start endless run → clear 6+ rooms → press boss button → defeat boss → press **Continue** → verify player lands in the departure room, ExplorationHUD is visible, run is active, and run currency is unchanged.

### Implementation for User Story 1

- [x] T002 [US1] Add `var _boss_return_room_id: String = ""` field to `scenes/core/main.gd` alongside the other boss lifecycle fields (`_boss_room_spawner`, `_boss_room_node`, etc.)

- [x] T003 [US1] Clear `_boss_return_room_id = ""` in both `_on_run_started()` and `_on_run_ended()` in `scenes/core/main.gd`

- [x] T004 [US1] Capture departure room in `_on_boss_teleport_pressed()` in `scenes/core/main.gd`: before calling `_room_loader.free_current_room()`, set `_boss_return_room_id = (RunManager.current_room as RoomSpawner).room_id` if `RunManager.current_room != null`, otherwise leave as `""`

- [x] T005 [US1] Update `_show_boss_victory_overlay()` in `scenes/core/main.gd`: change `setup(run_mode == "endless")` to `setup(run_mode == "endless" and not _boss_return_room_id.is_empty())`

- [x] T006 [US1] Implement `_on_boss_continue_pressed()` in `scenes/core/main.gd` (currently a print stub):
  1. Guard: `if _boss_return_room_id.is_empty(): return`
  2. Free `_boss_room_node` (`queue_free()`, null both `_boss_room_node` and `_boss_room_spawner`)
  3. Free `_boss_victory_layer` (`queue_free()`, null `_boss_victory_layer` and `_boss_victory_overlay`)
  4. `GlobalSignals.gameplay_started.emit()` to restore ExplorationHUD
  5. `_room_loader.return_to_room(_boss_return_room_id)`
  6. `_boss_return_room_id = ""`

**Checkpoint**: User Story 1 is fully functional. "Continue" returns player to departure room with run active.

---

## Phase 3: User Story 2 — Continue Hidden Outside Endless (Priority: P2)

**Goal**: "Continue" is absent in boss-mode runs and when boss was started via DevPanel without a prior dungeon room.

**Independent Test**: (a) Start boss-mode run, defeat boss → verify overlay shows only "Cash Out". (b) Use DevPanel "Start Boss" → defeat boss → verify "Continue" is not visible.

### Implementation for User Story 2

- [x] T007 [US2] Verify in `scenes/core/main.gd` that `_on_dev_start_boss()` does NOT set `_boss_return_room_id` (it calls `_on_boss_teleport_pressed()` when `RunManager.current_room` is null, so the field stays `""`). No code change expected — confirm by reading the call path from T004.

**Checkpoint**: Both user stories complete. Continue is shown only when a valid departure room exists.

---

## Phase 4: Polish & Validation

- [ ] T008 Run the quickstart.md validation sequence: endless run → clear rooms → boss → Continue → confirm departure room loads, HUD shows, run remains active, cash-out path still works

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies — start immediately
- **Phase 2 (US1)**: Depends on T001 (Phase 1) — `return_to_room` must exist
- **Phase 3 (US2)**: Can run in parallel with Phase 2 (read-only verification, different concern)
- **Phase 4 (Polish)**: Depends on Phases 2 and 3 complete

### Within Phase 2

- T002, T003 are independent of each other — can be done in any order or together
- T004 depends on T002 (field must exist)
- T005 depends on T002 (field must exist)
- T006 depends on T001 (needs `return_to_room`) and T002–T005

### Parallel Opportunities

- T002 and T003 can be done together (both add to the same field lifecycle)
- T004 and T005 can be done in parallel (different methods in the same file)
- T007 (US2) can be verified in parallel with T002–T005 (read-only)

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. T001 — expose `return_to_room` on RoomLoader
2. T002–T006 — wire up `_boss_return_room_id` and continue handler in Main.gd
3. **STOP and VALIDATE**: endless run → boss → Continue → verify return

### Full Delivery

4. T007 — confirm US2 (button hidden in non-endless paths)
5. T008 — full quickstart validation

---

## Notes

- [P] tasks = different files or independent concerns, no blocking dependencies
- T007 is likely a no-code verification task — the logic from T004 already handles it
- Commit after T001 (RoomLoader change), then again after T006 (Main.gd complete)
