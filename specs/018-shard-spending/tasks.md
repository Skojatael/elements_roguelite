# Tasks: Shard Spending

**Input**: Design documents from `specs/018-shard-spending/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks in the same phase)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

No setup required. Both target files (`scripts/managers/MetaManager.gd`,
`autoload/MetaManager.gd`) already exist.

---

## Phase 2: Foundational (Blocking Prerequisite)

**Purpose**: Remove `on_run_ended()` from `MetaManagerImpl` — this method is superseded by
`add_shards()` and its continued presence would duplicate mutation/save logic.

**⚠️ CRITICAL**: T001 must complete before any US1/US2 impl changes (same file).

- [X] T001 Remove `on_run_ended(summary, divisor, save_manager)` method entirely from `scripts/managers/MetaManager.gd`

**Checkpoint**: Foundation clean — impl file no longer contains stale method.

---

## Phase 3: User Story 1 — Spend Shards (Priority: P1) 🎯 MVP

**Goal**: `can_spend(cost)` and `spend(cost)` available on MetaManager, with impl logic in MetaManagerImpl.

**Independent Test**: With total_shards=50, call `MetaManager.spend(20)` → returns true, balance=30.
Call `MetaManager.spend(100)` → returns false, balance=30. Call `MetaManager.can_spend(30)` → true; `can_spend(31)` → false. No signal needed for this checkpoint.

### Implementation

- [X] T002 [P] [US1] Add `can_spend(cost: int) -> bool` and `spend(cost: int, save_manager: Node) -> bool` to `MetaManagerImpl` in `scripts/managers/MetaManager.gd` — see plan.md for exact implementation
- [X] T003 [P] [US1] Add `can_spend(cost: int) -> bool` and `spend(cost: int) -> bool` delegating methods to `autoload/MetaManager.gd` (delegation only — signal wiring added in US3)

**Checkpoint**: `MetaManager.can_spend()` and `MetaManager.spend()` functional. Balance guard
and persistence work correctly. Signal not yet wired.

---

## Phase 4: User Story 2 — Grant Shards from Any Source (Priority: P2)

**Goal**: `add_shards(amount)` available on MetaManager, usable from any in-game event.

**Independent Test**: With total_shards=10, call `MetaManager.add_shards(15)` → balance=25,
persisted. Existing run-end shard conversion continues to work (verified by completing a run
and checking the log line).

### Implementation

- [X] T004 [P] [US2] Add `add_shards(amount: int, save_manager: Node) -> void` to `MetaManagerImpl` in `scripts/managers/MetaManager.gd` — no-op if `amount <= 0`; mutate then save
- [X] T005 [P] [US2] Add `add_shards(amount: int) -> void` delegating method to `autoload/MetaManager.gd` (delegation only — signal emit added in US3)

**Checkpoint**: `MetaManager.add_shards()` functional and persists. Signal not yet wired.

---

## Phase 5: User Story 3 — React to Balance Changes (Priority: P3)

**Goal**: `signal shards_changed(new_total: int)` declared on MetaManager autoload; emitted
after every successful mutation. Run-end conversion also emits via refactored `_on_run_ended`.

**Independent Test**: Connect listener: `MetaManager.shards_changed.connect(func(n): print(n))`.
Call `spend(10)` and `add_shards(5)` — listener fires each time. Complete a run — listener also
fires with the post-conversion total.

### Implementation

- [X] T006 [US3] Declare `signal shards_changed(new_total: int)` on `autoload/MetaManager.gd` and add `shards_changed.emit(meta_state.total_shards)` inside the existing `spend()` wrapper (emit only when `success and cost > 0`) and inside `add_shards()` wrapper (emit only when `amount > 0`)
- [X] T007 [US3] Refactor `_on_run_ended()` in `autoload/MetaManager.gd`: remove the call to `_impl.on_run_ended(...)`, replace with: get `divisor` from ResourceManager, compute `earned = summary.essence_cashed_out / divisor`, call `add_shards(earned)` (which saves and emits signal), keep the existing print log line

**Checkpoint**: All three paths (spend, add_shards, run-end conversion) emit `shards_changed`.
Signal carries correct updated total. `_on_run_ended` no longer references removed impl method.

---

## Phase 6: Polish & Validation

- [ ] T008 Manual validation — run all 10 scenarios in `specs/018-shard-spending/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately. BLOCKS T002 and T004 (same impl file).
- **US1 (Phase 3)**: T001 complete. T002 and T003 can run in parallel (different files).
- **US2 (Phase 4)**: T001 complete. T004 and T005 can run in parallel (different files). T004 sequentially after T002 (same impl file, previous phase).
- **US3 (Phase 5)**: T003 and T005 complete (both add delegation to the autoload file that T006/T007 now extend). T006 → T007 sequentially (same file).
- **Polish (Phase 6)**: All implementation complete.

### User Story Dependencies

- **US1 (P1)**: After foundational. No dependency on US2 or US3.
- **US2 (P2)**: After foundational. No dependency on US1 or US3.
- **US3 (P3)**: Depends on US1 and US2 autoload wrappers existing (T003, T005) so emit calls have methods to follow.

### Parallel Opportunities

- T002 ‖ T003 (impl file vs autoload file — different files, Phase 3)
- T004 ‖ T005 (impl file vs autoload file — different files, Phase 4)

---

## Implementation Strategy

### MVP (US1 only — can_spend + spend)

1. T001: Remove stale impl method
2. T002 + T003 (parallel): impl methods + autoload delegation
3. Validate: spend/can_spend functional, balance guarded, persisted

### Full Feature (all 3 stories)

1. T001 → T002‖T003 → T004‖T005 → T006 → T007 → T008

---

## Notes

- T002 and T004 both modify `scripts/managers/MetaManager.gd` — they are in separate phases and thus always sequential. Do NOT attempt to parallelize them.
- T003, T005, T006, T007 all modify `autoload/MetaManager.gd` — always sequential across phases.
- US3 (signal) adds emit calls inside methods introduced by US1 (spend) and US2 (add_shards). Complete US1 and US2 autoload wrappers before starting US3.
- After T007, verify the game boots without errors — the removed `impl.on_run_ended()` call must be fully replaced by the `add_shards(earned)` call.
