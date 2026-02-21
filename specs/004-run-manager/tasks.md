# Tasks: Run Manager

**Input**: Design documents from `specs/004-run-manager/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅
**Tests**: No test tasks — not requested in specification.
**Organization**: Tasks grouped by user story; each story is independently implementable and testable.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: User story this task belongs to ([US1]–[US4])

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prerequisites that all user stories depend on. T001 enables US2 (room tracking); T002 and T003 enable US4 (service access) and provide typed class names referenced in RunManager.

- [x] T001 Extend `scenes/dungeon/RoomSpawner.gd`: add `signal room_entered(room_id: String)` declaration after existing `signal room_cleared`; in `_ready()` add `RunManager.register_room(self)` after the `_entry_area.body_entered.connect` line; in `_on_player_entered()` add `room_entered.emit(room_id)` after the existing player-entered print line and before the `_spawn_enemies()` call — `scenes/dungeon/RoomSpawner.gd`
- [x] T002 [P] Create `scripts/services/DifficultyService.gd`: `class_name DifficultyService extends RefCounted`; implement `func get_multiplier() -> float: return 1.0` — `scripts/services/DifficultyService.gd`
- [x] T003 [P] Create `scripts/services/RewardsService.gd`: `class_name RewardsService extends RefCounted`; implement `func get_room_reward(_room_id: String) -> Dictionary: return {}` — `scripts/services/RewardsService.gd`

**Checkpoint**: All three files parse without errors in Godot. Run game — existing RoomSpawner behaviour unchanged; `register_room` produces a script error (method not yet on RunManager) but no crash.

---

## Phase 2: User Story 1 — Run Lifecycle (Priority: P1) 🎯 MVP

**Goal**: A run can be started and ended. All session state initialises on `start_run(mode)` and `run_ended` fires on `end_run()`. State remains readable after the run ends.

**Independent Test**: Add temporary prints to Main.gd `_ready()`: call `start_run("endless")`, print all session fields, call `end_run()`, confirm signal fired and `is_run_active` is false. See Quickstart Scenario 1.

- [x] T004 [US1] Rewrite `autoload/RunManager.gd` with full session state and lifecycle — replace the entire file content with:
  - Signals: `signal run_ended` and `signal room_cleared(room_id: String)`
  - Session vars (all statically typed): `var run_id: String = ""`, `var is_run_active: bool = false`, `var run_mode: String = ""`, `var current_tier: int = 1`, `var run_start_time: float = 0.0`, `var run_currency: float = 0.0`, `var current_room: Node = null`, `var current_room_index: int = 0`
  - Preserve existing: `var cleared_rooms: Dictionary = {}`
  - Service vars: `var difficulty_service: DifficultyService` and `var rewards_service: RewardsService`
  - `_ready()`: `difficulty_service = DifficultyService.new()` and `rewards_service = RewardsService.new()`
  - `start_run(mode: String) -> void`: if mode not in `["endless", "boss"]` call `push_warning("RunManager: invalid run_mode '%s'" % mode)`; set `run_id = str(Time.get_ticks_msec())`; set `is_run_active = true`, `run_mode = mode`, `current_tier = 1`, `run_start_time = Time.get_ticks_msec() / 1000.0`, `run_currency = 0.0`, `current_room = null`, `current_room_index = 0`, `cleared_rooms = {}`
  - `end_run() -> void`: `if not is_run_active: return`; set `is_run_active = false`; emit `run_ended`
  - Preserve existing: `func mark_room_cleared(room_id: String) -> void`, `func is_room_cleared(room_id: String) -> bool`, `func start_new_run() -> void` (keep body as `cleared_rooms = {}` for backward compat)
  - Stub handlers (empty, extended in T005): `func register_room(_spawner: Node) -> void: pass`, `func _on_room_entered(_room_id: String, _spawner: Node) -> void: pass`, `func _on_room_cleared(_room_id: String) -> void: pass`
  - `add_currency(amount: float) -> void`: stub body `pass` (implemented in T006)
  - `autoload/RunManager.gd`

**Checkpoint**: US1 complete — `start_run("endless")` initialises all fields correctly; `end_run()` fires `run_ended` exactly once; `is_run_active` toggles correctly; state readable after end.

---

## Phase 3: User Story 2 — Room Navigation Tracking (Priority: P2)

**Goal**: `current_room` and `current_room_index` update automatically when the player enters a room. RunManager re-emits `room_cleared` for other systems.

**Independent Test**: Call `start_run("endless")` at game start. Enter CombatRoom01. Confirm `RunManager.current_room_index == 1` and `RunManager.current_room != null`. Defeat all enemies. Confirm `RunManager.room_cleared` signal fires with `"CombatRoom01"`. See Quickstart Scenario 2.

- [x] T005 [US2] Implement room tracking in `autoload/RunManager.gd`: replace the stub `register_room` body with: connect `spawner.room_entered` to `_on_room_entered.bind(spawner)` and `spawner.room_cleared` to `_on_room_cleared`; replace `_on_room_entered` stub with: `if not is_run_active: return`, `current_room = spawner`, `current_room_index += 1`; replace `_on_room_cleared` stub with: `if not is_run_active: return`, `mark_room_cleared(room_id)`, emit `room_cleared(room_id)` — `autoload/RunManager.gd`

**Checkpoint**: US2 complete — enter CombatRoom01, `current_room_index` is 1 and `current_room` is non-null; defeat all enemies and `RunManager.room_cleared` fires.

---

## Phase 4: User Story 3 — Run Currency Tracking (Priority: P3)

**Goal**: Gold accumulates via `add_currency()`. Total never drops below zero. Resets on new run.

**Independent Test**: After `start_run()`, call `add_currency(10)` then `add_currency(5)` — confirm `run_currency` is 15. Call `add_currency(-100)` — confirm floor at 0. Start new run — confirm reset to 0. See Quickstart Scenario 3.

- [x] T006 [US3] Implement `add_currency` in `autoload/RunManager.gd`: replace stub body with: `if not is_run_active: push_warning("RunManager: add_currency called with no active run"); return`; `run_currency = maxf(run_currency + amount, 0.0)` — `autoload/RunManager.gd`

**Checkpoint**: US3 complete — currency accumulates correctly; floor at 0 enforced; resets on `start_run()`.

---

## Phase 5: User Story 4 — Difficulty and Rewards Access (Priority: P4)

**Goal**: `DifficultyService` and `RewardsService` are callable via RunManager in any run state, returning valid placeholder values with no errors.

**Independent Test**: Before and after `start_run()`, call `RunManager.difficulty_service.get_multiplier()` (expect 1.0) and `RunManager.rewards_service.get_room_reward("CombatRoom01")` (expect `{}`). Both return without error. See Quickstart Scenario 4.

> **Note**: No new code tasks — T002 and T003 created the stubs; T004 instantiated them in `_ready()`. This phase is validation-only.

**Checkpoint**: US4 complete — both services accessible via RunManager, return correct stub values in any run state.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and full validation.

- [x] T007 [P] Update `CLAUDE.md`: in the Enemy spawning section, note that `RoomSpawner._ready()` now calls `RunManager.register_room(self)` and emits `signal room_entered(room_id: String)`; in the RunManager / Autoloads section, list the new session fields (`run_id`, `is_run_active`, `run_mode`, `current_tier`, `run_start_time`, `run_currency`, `current_room`, `current_room_index`), new methods (`start_run`, `end_run`, `register_room`, `add_currency`), new signals (`run_ended`, `room_cleared`), and service access (`RunManager.difficulty_service`, `RunManager.rewards_service`) — `CLAUDE.md`
- [ ] T008 [P] Run all quickstart.md validation scenarios (1–6): run lifecycle, room tracking, currency floor, service stubs, end_run no-op, invalid mode warning — `specs/004-run-manager/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately. T002 and T003 run in parallel; T001 independent of both.
- **US1 (Phase 2)**: Depends on T002 and T003 (DifficultyService and RewardsService class names must exist before RunManager declares typed vars). T001 can complete in parallel with T004 — they touch different files.
- **US2 (Phase 3)**: Depends on T004 (extends same RunManager.gd) and T001 (RoomSpawner must emit `room_entered`).
- **US3 (Phase 4)**: Depends on T005 (extends same RunManager.gd). Independent of US2 logic but same file — sequential.
- **US4 (Phase 5)**: Depends on T002, T003, T004 — all already done. Validation only.
- **Polish (Phase 6)**: Depends on all phases complete. T007 and T008 run in parallel.

### Within-Phase File Conflicts

| Tasks | File | Constraint |
|---|---|---|
| T004, T005, T006 | `autoload/RunManager.gd` | Sequential: T004 → T005 → T006 |
| T002, T003 | Different files | Fully parallel |
| T001 | `scenes/dungeon/RoomSpawner.gd` | Independent — parallel with T002, T003, T004 |

### Execution Order

```text
T001 (RoomSpawner)  ─────────────────────────┐
T002 (DifficultyService) [P] ─┐              │
T003 (RewardsService)    [P] ─┤              │
                              ▼              ▼
                         T004 [US1] (RunManager core)
                              │
                         T005 [US2] (room tracking)
                              │
                         T006 [US3] (currency)
                              │
                     US4 validated (no code)
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
         T007 (CLAUDE.md)              T008 (validate)
```

---

## Parallel Execution Examples

### Phase 1: Setup

```text
All three parallel:
  T001: "Extend RoomSpawner.gd — add room_entered signal and register_room call"
  T002: "Create DifficultyService.gd stub in scripts/services/"
  T003: "Create RewardsService.gd stub in scripts/services/"
```

### Phase 6: Polish

```text
Both parallel:
  T007: "Update CLAUDE.md with new RunManager API and RoomSpawner changes"
  T008: "Run all quickstart.md validation scenarios 1–6"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: US1 (T004)
3. **STOP and VALIDATE**: Run Quickstart Scenario 1 — lifecycle fields init correctly, run_ended fires
4. Feature is usable; other systems can now call `start_run()` and `end_run()`

### Incremental Delivery

1. Setup (T001–T003) → prerequisites in place
2. US1 (T004) → run lifecycle working → **MVP**
3. US2 (T005) → room tracking working
4. US3 (T006) → currency working
5. US4 → validated (no code)
6. Polish (T007–T008) → docs updated, all scenarios pass

### Notes

- T004 is a full file rewrite — write the complete new RunManager.gd in one pass. Do not attempt incremental edits to the existing file.
- T005 and T006 are targeted method implementations extending T004's stubs — do not rewrite the whole file again.
- The `.bind(spawner)` pattern in `register_room` is critical: `room_entered(room_id)` signal only carries the room_id string, but `_on_room_entered` needs the spawner reference too. `.bind(spawner)` appends it as an extra argument.
- T001 (RoomSpawner) can be done at any time before T005 is validated — the `register_room` call in RoomSpawner will hit the stub body in T004 (which is just `pass`) until T005 replaces it.
- US4 has no implementation tasks because T002 + T003 + T004 already fulfil all four US4 acceptance scenarios.
