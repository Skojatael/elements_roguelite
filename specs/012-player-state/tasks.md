# Tasks: Player State Snapshot

**Input**: Design documents from `/specs/012-player-state/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks grouped by user story. US1 and US2 are both P1 MVP. US3 (stubs) is fully covered by the foundational PlayerState.gd creation — no separate implementation tasks.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

No project initialization required. Pure GDScript additions to existing files; no new dependencies.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create `PlayerState` class and extend `RunState` — required by all user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Create `scripts/data_models/PlayerState.gd` — `class_name PlayerState extends RefCounted` with fields: `current_hp: float = 0.0`, `items: Array = []`, `modifiers: Array = []`, `skill_changes: Array = []`, `skill_cooldowns: Dictionary = {}`
- [x] T002 [P] Add `var player_state: PlayerState = PlayerState.new()` field to `scripts/data_models/RunState.gd` (after T001 so PlayerState class is available)

**Checkpoint**: `PlayerState` class exists; `RunState` exposes `player_state` with safe defaults.

---

## Phase 3: User Story 1 — The Run Always Knows the Player's Health (Priority: P1) 🎯 MVP

**Goal**: `RunManager.player_state.current_hp` tracks `StatsComponent.current_health` live during a run, accessible via `RunManager.run_state.player_state`.

**Independent Test**: Start a run — confirm `run_state.player_state.current_hp` equals `StatsComponent.current_health`. Take damage — confirm `current_hp` decreases. Heal — confirm `current_hp` increases.

### Implementation for User Story 1

- [x] T003 [US1] Add `var player_state: PlayerState = PlayerState.new()` field declaration to `autoload/RunManager.gd` (top-level variable block, after existing vars)
- [x] T004 [US1] Add `start_run()` setup block to `autoload/RunManager.gd`: create fresh `PlayerState.new()`, assign `run_state.player_state = player_state`, find player via group, connect `stats.health_changed` with `is_connected()` guard, set `player_state.current_hp = stats.current_health`
- [x] T005 [US1] Add `_on_player_health_changed(new_health: float, _max_health: float) -> void` method to `autoload/RunManager.gd` that writes `player_state.current_hp = new_health`

**Checkpoint**: US1 complete. `current_hp` updates live via signal. Verify with Remote Inspector: damage and heal both reflect in `RunManager.run_state.player_state.current_hp`.

---

## Phase 4: User Story 2 — Player State Resets When a Run Ends (Priority: P1) 🎯 MVP

**Goal**: Immediately after `end_run()`, `current_hp` equals `StatsComponent.max_health` and stubs are empty — without waiting for the next `start_run()`.

**Independent Test**: Start a run. Take damage. Call `end_run()`. Immediately read `run_state.player_state.current_hp` — confirm it equals max health. Confirm stubs are empty.

### Implementation for User Story 2

- [x] T006 [US2] Add `end_run()` reset block to `autoload/RunManager.gd` (after `is_run_active = false`): find player via group, create `PlayerState.new()`, set `player_state.current_hp = stats.max_health`, update both `player_state` and `run_state.player_state` to the new instance

**Checkpoint**: US2 complete. `end_run()` leaves `current_hp` at max health. Stubs empty (guaranteed by `PlayerState.new()`).

---

## Phase 5: User Story 3 — Future Player Data Fields Are Reserved and Safe (Priority: P2)

**Goal**: `items`, `modifiers`, `skill_changes`, `skill_cooldowns` are declared, return empty defaults, and never cause errors.

**Independent Test**: Read each stub field before, during, and after a run — confirm empty, no errors.

### Implementation for User Story 3

No additional implementation tasks. Stub fields (`items`, `modifiers`, `skill_changes`, `skill_cooldowns`) are declared with correct types and empty defaults in T001 (`PlayerState.gd`). Reset to empty on every `end_run()` is guaranteed by `PlayerState.new()` in T006.

**Checkpoint**: US3 complete after T001 and T006. Verify: read all stubs in Remote Inspector at each lifecycle phase — zero errors.

---

## Phase 6: Polish & Validation

- [ ] T007 Run all 11 manual validation scenarios from `specs/012-player-state/quickstart.md` in Godot Editor using Remote Inspector and Output panel

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately. BLOCKS all user stories.
- **US1 (Phase 3)**: Depends on T001 (PlayerState class) and T002 (RunState field). T003 → T004 → T005 sequential (all in RunManager.gd).
- **US2 (Phase 4)**: Depends on T003 (player_state field on RunManager).
- **US3 (Phase 5)**: Covered by T001 + T006. No additional tasks.
- **Validation (Phase 6)**: Depends on all phases complete.

### Task Dependencies

| Task | Depends On | Reason |
|---|---|---|
| T001 | — | No dependencies |
| T002 | T001 | RunState references PlayerState class |
| T003 | T001 | RunManager references PlayerState class |
| T004 | T003 | Uses `player_state` field; uses `run_state` from 011 |
| T005 | T003 | Uses `player_state` field |
| T006 | T003 | Uses `player_state` field; uses `run_state` from 011 |
| T007 | T001–T006 | All implementation complete |

### Parallel Opportunities

- T002 and T003 can run in parallel (different files, both depend only on T001)
- T004 and T005 both modify RunManager.gd — run sequentially
- T005 and T006 both modify RunManager.gd — run sequentially

---

## Implementation Strategy

### MVP First (US1 + US2 both P1)

1. Complete Phase 2: T001 → T002 (T002 parallel after T001)
2. Complete Phase 3: T003 → T004 → T005
3. Complete Phase 4: T006
4. **STOP and VALIDATE**: Scenarios 1–10 from quickstart.md
5. US3 is already satisfied by T001 + T006 — verify scenarios 5 and 7

### Incremental Delivery

1. T001 + T002 → PlayerState exists, RunState exposes it with safe defaults
2. T003 + T004 + T005 → Live `current_hp` tracking during run (US1 complete)
3. T006 → Clean reset at run end (US2 complete)
4. T007 → Full lifecycle validated

---

## Notes

- [P] tasks modify different files with no incomplete dependencies
- US3 has no implementation tasks — stubs are part of the PlayerState.gd declaration (T001)
- T004 and T005 are in the same file (RunManager.gd) — write T004's block first, then add the method in T005
- T006 block goes after `is_run_active = false` in `end_run()` — both `player_state` and `run_state.player_state` must be updated to keep them in sync
- Reset uses `PlayerState.new()` (not field-by-field reset) — guarantees all fields return to defaults with no risk of a forgotten field
- `is_connected()` guard in T004 prevents duplicate `health_changed` connections across repeated `start_run()` calls
