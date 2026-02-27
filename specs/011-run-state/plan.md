# Implementation Plan: Run State Snapshot

**Branch**: `011-run-state` | **Date**: 2026-02-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/011-run-state/spec.md`

---

## Summary

Create a dedicated `RunState` data class (`RefCounted`) in `scripts/data_models/RunState.gd` with 4 live fields and 2 stub fields. `RunManager` owns the single instance — it creates a fresh `RunState` at declaration and replaces it on each `start_run()`. Live fields are kept in sync at their natural write points: `run_mode` at run start, `current_room_id` in `_on_room_entered()`, `run_currency` in `add_currency()`, `cleared_rooms` via a shared Dictionary reference. Stub fields default to `0` and are never written in this feature.

---

## Technical Context

**Language/Version**: GDScript, Godot 4.6
**Primary Dependencies**: `RunManager` autoload — the sole owner/writer; no other dependency
**Storage**: None — not persisted to disk in this feature
**Testing**: Manual playtest via Godot Remote Inspector (see `quickstart.md`, 10 scenarios)
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Project Type**: Godot 4.6 mobile game
**Performance Goals**: Zero overhead — RunState holds only primitives and one shared Dictionary reference
**Constraints**: No new signals; polled by consumers; not persisted; read-only for all non-RunManager systems

---

## Constitution Check

### Principle I — Single Responsibility ✅

- `RunState.gd`: one file, one class, one concern — a typed snapshot of run data. No logic, no methods, no side effects.
- `RunManager`: absorbs three new one-liner assignments in existing methods. RunManager's responsibility (run lifecycle management) does not change scope.
- No new autoloads introduced — RunState is accessed via the existing RunManager autoload.

### Principle II — Data-Driven Content ✅

- `RunState` contains no balance values or configurable content. It is a structural data class.
- No JSON changes required.

### Principle III — Mobile-First Performance ✅

- `RunState` holds 2 String fields, 1 float, 1 Dictionary reference, 2 ints. No allocations beyond `RunState.new()` on each run start.
- Polled by consumers — no signal overhead.

### Principle IV — Editor-Centric Workflow ✅

- No scene files modified. Pure GDScript changes only.

### Principle V — Simplicity & YAGNI ✅

- No abstraction, no base class, no interface — a plain data class with 6 fields.
- Stub fields are declared with their final names and types. No placeholder nodes or stub scripts beyond the declared fields.
- `cleared_rooms` shared reference avoids duplicate state — the simplest correct approach.

---

## Project Structure

### Documentation (this feature)

```text
specs/011-run-state/
├── plan.md              ← This file
├── research.md          ← Phase 0 (7 decisions)
├── data-model.md        ← Phase 1
├── quickstart.md        ← Phase 1 (10 scenarios)
├── contracts/
│   └── interfaces.md   ← Phase 1
└── tasks.md             ← Phase 2 (/speckit.tasks)
```

### Source Code

**New GDScript file**:

```text
scripts/data_models/RunState.gd
```

**Modified GDScript file**:

```text
autoload/RunManager.gd    ← add run_state field; populate in start_run(); sync in add_currency() and _on_room_entered()
```

No scene changes, no data file changes, no new autoloads.

---

## Implementation Phases

### Phase 1 — New file: `RunState.gd`

Create `scripts/data_models/RunState.gd`:

```gdscript
class_name RunState
extends RefCounted

## Read-only for all systems except RunManager.

## ID of the room the player is currently in. Empty string when no room is loaded.
var current_room_id: String = ""

## Set of cleared room IDs this run. Same reference as RunManager.cleared_rooms.
var cleared_rooms: Dictionary = {}

## Total currency accumulated this run.
var run_currency: float = 0.0

## Run mode: "endless" or "boss". Set at run start; does not change.
var run_mode: String = ""

## Stub: deepest room reached (in depth steps from start). Always 0 until feature 010 populates it.
var max_depth_reached: int = 0

## Stub: run seed for deterministic dungeon generation. Always 0 until seeded-generation feature.
var seed: int = 0
```

### Phase 2 — RunManager: declare run_state

Add to the session state block in `autoload/RunManager.gd` (after `cleared_rooms`):

```gdscript
## Snapshot of current run state. Populated by start_run(); readable at all times.
var run_state: RunState = RunState.new()
```

### Phase 3 — RunManager: populate in start_run()

In `start_run()`, after `cleared_rooms = {}` and the existing state resets, add:

```gdscript
run_state = RunState.new()
run_state.run_mode = mode
run_state.cleared_rooms = cleared_rooms
```

### Phase 4 — RunManager: sync run_currency in add_currency()

In `add_currency()`, after `run_currency = maxf(run_currency + amount, 0.0)`, add:

```gdscript
run_state.run_currency = run_currency
```

### Phase 5 — RunManager: sync current_room_id in _on_room_entered()

In `_on_room_entered()`, after `rooms_entered += 1`, add:

```gdscript
run_state.current_room_id = room_id
```

### Phase 6 — Validate

Run all 10 scenarios from `specs/011-run-state/quickstart.md`.

---

## Key Design Decisions

| Decision | Summary |
|---|---|
| Base class | `RefCounted` — runtime-only data, not persisted; consistent with SpawnContext |
| File location | `scripts/data_models/RunState.gd` — established home for typed data models |
| Ownership | RunManager declares and replaces; fresh `RunState.new()` on each `start_run()` |
| cleared_rooms | Shared Dictionary reference — mutations auto-reflected, no sync code needed |
| run_currency | Explicit re-assignment in `add_currency()` — float is value type |
| current_room_id | Set in `_on_room_entered()` — the natural update point |
| Read-only | Convention + doc comments — no language enforcement needed |
| Stub fields | Declared with correct types; default 0; reset free via `RunState.new()` |

*(See `research.md` for full rationale on each decision.)*
