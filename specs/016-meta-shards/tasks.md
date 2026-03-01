# Tasks: Meta Currency — Shards

**Input**: Design documents from `/specs/016-meta-shards/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- All paths are relative to repository root (`res://`)

---

## Phase 1: Setup

**Purpose**: Create balance config JSON before any GDScript is written (Constitution Principle II: data-first).

- [X] T001 Create `data/meta_config.json` with field `shard_conversion_rate: 1.0`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data model and shared services that both user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 Create `scripts/data_models/MetaState.gd` — `class_name MetaState extends RefCounted`, field `var total_shards: int = 0`
- [X] T003 [P] Add `get_meta_config() -> Dictionary` to `autoload/ResourceManager.gd` — reads and caches `data/meta_config.json` following the existing `get_dungeon_config()` pattern
- [X] T004 [P] Implement `save_meta_state(state: MetaState) -> void` and `load_meta_state() -> MetaState` in `autoload/SaveManager.gd` — save path `user://meta_save.json`, JSON format `{"total_shards": <int>}`, `load_meta_state()` returns `MetaState.new()` if file missing or malformed, never returns null; remove empty `_process()` stub

**Checkpoint**: MetaState, SaveManager, and ResourceManager are ready — user story implementation can begin.

---

## Phase 3: User Story 1 — Earn Shards on Run End (Priority: P1) 🎯 MVP

**Goal**: When a run ends, MetaManager automatically converts essence cashed out to shards and persists the updated total.

**Independent Test**: Start a run, kill enemies, end the run via DevPanel. Check logs for `[MetaManager] N shards earned — total=M`. Confirm N == essence_cashed_out from the `[Essence]` log line.

### Implementation

- [X] T005 [US1] Implement shard earning in `autoload/MetaManager.gd`:
  - Declare `var meta_state: MetaState = MetaState.new()`
  - In `_ready()`: set `meta_state = MetaState.new()` (placeholder; replaced in US2), connect `RunManager.run_ended` via lambda: `RunManager.run_ended.connect(func(r: RunManager.EndReason) -> void: _on_run_ended(r))`
  - Implement `func _on_run_ended(reason: RunManager.EndReason) -> void`: read `RunManager.run_summary.essence_cashed_out`, get rate via `ResourceManager.get_meta_config().get("shard_conversion_rate", 1.0)`, compute `var shards_earned: int = floori(float(summary.essence_cashed_out) * rate)`, add to `meta_state.total_shards`, call `SaveManager.save_meta_state(meta_state)`, print `"[MetaManager] {shards} shards earned — total={total}".format(...)`
  - Remove empty `_process()` stub

**Checkpoint**: User Story 1 fully functional. Shards are computed and saved on every run end.

---

## Phase 4: User Story 2 — MetaState Persists Across Sessions (Priority: P2)

**Goal**: Total shards survive game restarts — loaded from disk in MetaManager._ready().

**Independent Test**: Earn shards, stop the play session, restart, end another run. Confirm the log total includes shards from the previous session.

### Implementation

- [X] T006 [US2] Replace `meta_state = MetaState.new()` with `meta_state = SaveManager.load_meta_state()` in `MetaManager._ready()` in `autoload/MetaManager.gd`

**Checkpoint**: Both user stories complete. Shards accumulate correctly across runs and sessions.

---

## Phase 5: Polish & Validation

- [ ] T007 Run all 7 manual validation scenarios from `specs/016-meta-shards/quickstart.md` and confirm each passes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 (T001 must exist before ResourceManager reads it); T003 and T004 can run in parallel with each other
- **Phase 3 (US1)**: Depends on T002, T003, T004 all complete
- **Phase 4 (US2)**: Depends on T005 complete (same file, sequential)
- **Phase 5 (Polish)**: Depends on T006 complete

### Task-level Dependencies

```
T001
 └─► T003 (reads meta_config.json)
T002
 └─► T004 (save/load uses MetaState type)
 └─► T005 (MetaManager declares MetaState field)
T003, T004
 └─► T005
T005
 └─► T006
T006
 └─► T007
```

### Parallel Opportunities

- T003 and T004 can run in parallel (different files: ResourceManager.gd, SaveManager.gd)

---

## Implementation Strategy

### MVP (User Story 1 only)

1. T001 → T002 → T003 + T004 (parallel) → T005
2. Validate: end a run, confirm `[MetaManager]` log line appears with correct shard count
3. MVP complete — shards are earned and saved

### Full delivery

4. T006 — add load-on-startup
5. T007 — run quickstart scenarios

---

## Notes

- T003 and T004 are marked [P] — implement in parallel, they touch different files
- T005 and T006 both modify `autoload/MetaManager.gd` — must be sequential
- MetaManager already exists as a stub autoload; do NOT create a new autoload registration
- `RunManager.run_summary` is guaranteed non-null when `run_ended` fires (set before emit in `end_run()`)
- Use lambda for `run_ended` connection: signal passes `EndReason`, method signature must match
- `floori()` is required for all shard math — no `int()` or `round()`
