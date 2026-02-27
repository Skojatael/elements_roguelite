# Tasks: Run State Snapshot

**Input**: Design documents from `specs/011-run-state/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story. US1 and US2 share the same implementation (reset-in-start_run covers both). US3 has no additional code — stub fields are declared in RunState.gd and reset for free via `RunState.new()`. All code tasks are in 2 files.

**Files changed**:
- `scripts/data_models/RunState.gd` — new file (Foundational)
- `autoload/RunManager.gd` — 4 additions across existing methods

---

## Phase 1: Setup

No project setup required. No new dependencies, no new scenes, no data files.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: `RunState.gd` must exist before RunManager can reference it. All user story phases depend on this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Create `scripts/data_models/RunState.gd` as `class_name RunState extends RefCounted` with 6 fields and doc comments: `var current_room_id: String = ""`, `var cleared_rooms: Dictionary = {}`, `var run_currency: float = 0.0`, `var run_mode: String = ""`, `var max_depth_reached: int = 0` (stub), `var seed: int = 0` (stub) — each with a `##` doc comment describing its purpose and stub status where applicable

**Checkpoint**: RunState.gd exists and parses without errors — RunManager can now reference it.

---

## Phase 3: User Story 1 — The Game Always Knows the Full Run State (Priority: P1) 🎯 MVP

**Goal**: All 4 live fields in RunState accurately reflect RunManager's live state during an active run. RunState is accessible at any time via `RunManager.run_state`.

**Independent Test**: Start a run. In Remote Inspector on RunManager, confirm `run_state` is non-null and `run_state.run_mode` equals the chosen mode. Enter a room — confirm `run_state.current_room_id` matches the room. Clear a room — confirm it appears in `run_state.cleared_rooms`. Collect currency — confirm `run_state.run_currency` matches.

**⚠️ Depends on**: Phase 2 (T001 must be complete)

### Implementation for User Story 1

- [x] T002 [US1] Add `## Snapshot of current run state. Populated by start_run(); readable at all times.\nvar run_state: RunState = RunState.new()` to the session state declarations block in `autoload/RunManager.gd` (after the `cleared_rooms` field)
- [x] T003 [US1] In `start_run()` in `autoload/RunManager.gd`, immediately after `cleared_rooms = {}`, add three lines: `run_state = RunState.new()`, `run_state.run_mode = mode`, `run_state.cleared_rooms = cleared_rooms` (the shared reference assignment)
- [x] T004 [P] [US1] In `add_currency()` in `autoload/RunManager.gd`, add `run_state.run_currency = run_currency` immediately after the `run_currency = maxf(run_currency + amount, 0.0)` assignment
- [x] T005 [P] [US1] In `_on_room_entered()` in `autoload/RunManager.gd`, add `run_state.current_room_id = room_id` immediately after `rooms_entered += 1`

**Checkpoint**: After T002–T005 — all 4 live fields stay in sync. Verify via Remote Inspector: enter rooms, clear rooms, collect currency.

---

## Phase 4: User Story 2 — Run State Resets Cleanly Between Runs (Priority: P1) 🎯 MVP

**Goal**: Starting a new run produces a completely clean RunState. No data from the previous run leaks in.

**Independent Test**: Play a run — collect currency, clear rooms. Start a new run. Confirm `run_state.run_currency == 0.0`, `run_state.cleared_rooms` is empty, `run_state.current_room_id == ""`.

**No additional code tasks** — the fresh `RunState.new()` created in T003's `start_run()` changes fully implements this story. US2 is verified by running the test above after US1 code is in place.

**Checkpoint**: US2 is satisfied when T001–T005 are complete and the independent test passes.

---

## Phase 5: User Story 3 — Future Fields Are Reserved and Safe (Priority: P2)

**Goal**: `max_depth_reached` and `seed` exist on RunState, return `0`, and never cause errors.

**Independent Test**: Start a run. Read `RunManager.run_state.max_depth_reached` — confirm `0`, no error. Read `RunManager.run_state.seed` — confirm `0`, no error.

**No additional code tasks** — stub fields are declared in T001's RunState.gd with `= 0` defaults and are reset for free by `RunState.new()` in T003. US3 is verified by running the test above after T001 is complete.

**Checkpoint**: US3 is satisfied when T001 is complete and the independent test passes.

---

## Phase 6: Polish & Validation

- [ ] T006 Run all 10 manual validation scenarios from `specs/011-run-state/quickstart.md` and confirm every scenario passes with no errors or warnings in the Output panel

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 2 (Foundational)** — No dependencies, start immediately
- **Phase 3 (US1)** — Depends on T001 (RunState.gd must exist)
- **Phase 4 (US2)** — No new code; satisfied by T003 (start_run reset)
- **Phase 5 (US3)** — No new code; satisfied by T001 (stub field declarations)
- **Phase 6 (Validation)** — Depends on T001–T005 complete

### Task Dependencies

- **T001**: No dependencies — start here
- **T002**: Depends on T001 (RunManager references RunState type)
- **T003**: Depends on T002 (references `run_state` field declared in T002)
- **T004** [P]: Depends on T002; independent of T005
- **T005** [P]: Depends on T002; independent of T004
- **T006**: Depends on T001–T005 complete

### Parallel Opportunities

- T004 and T005 can run in parallel — different methods in RunManager.gd, no conflict

---

## Parallel Example: US1

```
T001 → T002 → T003
               ↓
       T004 [P] + T005 [P]   (both depend on T002/T003, independent of each other)
```

---

## Implementation Strategy

### MVP (complete in ~15 minutes of coding)

1. T001 — Create RunState.gd (~20 lines)
2. T002 — Add 2-line field declaration to RunManager.gd
3. T003 — Add 3 lines in start_run()
4. T004 + T005 — (parallel) 1 line each in add_currency() and _on_room_entered()
5. T006 — Validate 10 quickstart scenarios

All three user stories are satisfied by T001–T005. No story requires separate tasks.

---

## Notes

- T004 and T005 are [P] — different methods, same file. No write conflict.
- US2 and US3 have zero additional code tasks — they fall out of US1's implementation naturally.
- `cleared_rooms` shared reference means `mark_room_cleared()` requires no changes — the dict mutation is automatically visible through `run_state.cleared_rooms`.
- Reading `run_state` before any run started is always safe — the field is initialized at RunManager declaration (T002).
