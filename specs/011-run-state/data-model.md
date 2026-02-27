# Data Model: Run State Snapshot

**Feature**: 011-run-state
**Date**: 2026-02-27

---

## RunState Class

**File**: `scripts/data_models/RunState.gd`
**Base class**: `RefCounted`
**Owner**: `RunManager` (sole writer)
**Consumers**: Any system that needs read-only run snapshot (HUD, future save system, analytics)

### Fields

| Field | Type | Default | Live/Stub | Description |
|---|---|---|---|---|
| `current_room_id` | `String` | `""` | Live | ID of the room the player is currently in. Empty before run starts and during room transitions. |
| `cleared_rooms` | `Dictionary` | `{}` | Live | Same reference as `RunManager.cleared_rooms`. Keys are `room_id` strings; values are `true`. |
| `run_currency` | `float` | `0.0` | Live | Total currency collected this run. Mirrors `RunManager.run_currency`. |
| `run_mode` | `String` | `""` | Live | `"endless"` or `"boss"`. Set at run start; does not change during the run. |
| `max_depth_reached` | `int` | `0` | **Stub** | Deepest room reached (in depth units). Always 0 in this feature. Populated by feature 010. |
| `seed` | `int` | `0` | **Stub** | Run seed for deterministic generation. Always 0 in this feature. Populated by a future seeded-generation feature. |

### Class Definition

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

---

## RunManager Changes

### New Field

```gdscript
## Snapshot of current run state. Populated by start_run(); readable at all times.
var run_state: RunState = RunState.new()
```

Initialized at declaration → safe defaults before any run starts.

### start_run() — Reset

```gdscript
cleared_rooms = {}
# ... (existing reset code) ...
run_state = RunState.new()
run_state.run_mode = mode
run_state.cleared_rooms = cleared_rooms  # shared reference — mutations auto-reflected
```

`RunState.new()` is called AFTER `cleared_rooms = {}` so the shared reference points to the new empty dict.

### add_currency() — Sync

```gdscript
run_currency = maxf(run_currency + amount, 0.0)
run_state.run_currency = run_currency  # explicit sync (float is value type)
```

### _on_room_entered() — Sync

```gdscript
current_room = spawner
rooms_entered += 1
run_state.current_room_id = room_id  # sync string field
```

### mark_room_cleared() — No change needed

`cleared_rooms[room_id] = true` mutates the shared dict — `run_state.cleared_rooms` reflects it automatically.

---

## State Lifecycle

```
Before any run:
  run_state = RunState.new()       ← all defaults (declared at RunManager init)
  run_state.current_room_id = ""
  run_state.run_currency    = 0.0
  run_state.cleared_rooms   = {}
  run_state.run_mode        = ""

start_run(mode):
  cleared_rooms = {}
  run_state = RunState.new()       ← fresh instance
  run_state.run_mode = mode
  run_state.cleared_rooms = cleared_rooms

During run:
  _on_room_entered(room_id, …):    run_state.current_room_id = room_id
  add_currency(amount):            run_state.run_currency = run_currency
  mark_room_cleared(room_id):      cleared_rooms dict mutated → run_state reflects automatically

end_run():
  is_run_active = false
  run_state NOT touched            ← final values remain readable (FR-011)

Next start_run():
  run_state replaced with fresh    ← previous run's values discarded
```

---

## Stub Field Contract

Both stub fields (`max_depth_reached`, `seed`) MUST:
- Be declared with their correct types and default value `0`
- Never cause an error when read
- Reset to `0` on each new run (guaranteed by `RunState.new()` creating a fresh instance)
- Not be populated or incremented by anything in this feature
