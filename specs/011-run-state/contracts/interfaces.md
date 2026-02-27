# Interface Contracts: Run State Snapshot

**Feature**: 011-run-state
**Date**: 2026-02-27

---

## 1. RunManager.run_state Property

**Owner**: `RunManager` (declares, creates, updates)
**Consumed by**: Any system needing a run snapshot (HUD, future save system)
**Type**: `RunState`

### Contract

```gdscript
var run_state: RunState
```

- MUST be non-null at all times (initialized to `RunState.new()` at RunManager declaration).
- MUST reflect accurate live values during an active run.
- MUST retain final values after `end_run()` until the next `start_run()`.
- Read-only for all systems other than RunManager. Consumers MUST NOT assign to `run_state` or its fields.

### Access Pattern (consumers)

```gdscript
# Correct — read only:
var currency: float = RunManager.run_state.run_currency
var cleared: Dictionary = RunManager.run_state.cleared_rooms
var room_id: String = RunManager.run_state.current_room_id

# WRONG — never write from consumer:
RunManager.run_state.run_currency = 50.0  # prohibited
```

---

## 2. RunState Field Invariants

### current_room_id: String

| State | Value |
|---|---|
| Before any run | `""` |
| After `start_run()`, before first room entered | `""` |
| After player enters a room | ID of that room (e.g. `"room_3_2"`) |
| During room transition (room freed, next not loaded) | Previous room's ID (momentary; consumers handle gracefully) |
| After `end_run()` | ID of the last room entered |

### cleared_rooms: Dictionary

- Same object reference as `RunManager.cleared_rooms`.
- Keys: room_id strings. Values: `true`.
- Count equals number of rooms cleared this run.
- Empty `{}` immediately after `start_run()`.

### run_currency: float

- Always `>= 0.0`.
- Exactly equals `RunManager.run_currency`.
- `0.0` immediately after `start_run()`.

### run_mode: String

- `""` before first `start_run()`.
- `"endless"` or `"boss"` during and after a run.
- Does not change during a run.

### max_depth_reached: int (stub)

- Always `0` in this feature.
- MUST NOT be written by anything in this feature.
- MUST return `0` without error on any read.

### seed: int (stub)

- Always `0` in this feature.
- MUST NOT be written by anything in this feature.
- MUST return `0` without error on any read.

---

## 3. RunManager Write Points

Only these locations in RunManager may write to RunState:

| Method | Field(s) written |
|---|---|
| Declaration (init) | `run_state = RunState.new()` |
| `start_run()` | `run_state = RunState.new()`, `run_state.run_mode`, `run_state.cleared_rooms` |
| `add_currency()` | `run_state.run_currency` |
| `_on_room_entered()` | `run_state.current_room_id` |
| `mark_room_cleared()` | (implicit — shared dict reference) |
