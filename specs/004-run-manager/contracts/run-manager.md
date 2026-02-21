# Contract: RunManager (Extended)

**Feature**: 004-run-manager
**File**: `autoload/RunManager.gd`
**Date**: 2026-02-21

This contract extends the existing RunManager autoload. Existing methods (`mark_room_cleared`, `is_room_cleared`) are preserved unchanged.

---

## Signals

```gdscript
signal run_ended
signal room_cleared(room_id: String)
```

| Signal | When emitted | Payload |
|---|---|---|
| `run_ended` | Same frame as `end_run()` call | none |
| `room_cleared` | When a registered RoomSpawner emits its own `room_cleared` | `room_id: String` |

---

## Session State (read-only for callers)

```gdscript
var run_id: String
var is_run_active: bool
var run_mode: String
var current_tier: int
var run_start_time: float
var run_currency: float
var current_room: Node          # runtime type: RoomSpawner
var current_room_index: int
var cleared_rooms: Dictionary   # existing field — preserved
```

`current_tier` is the only field callers may set directly (meta-progression assigns it). All others are managed by RunManager.

---

## Public Methods

### `start_run(mode: String) -> void`

Initialises a new run session. Safe to call while a run is already active — fully resets state.

```gdscript
# Pre: mode is "endless" or "boss". Other values emit a push_warning.
# Post: is_run_active == true
#       run_id == str(Time.get_ticks_msec())   # non-empty, unique within session
#       run_mode == mode
#       current_tier == 1
#       run_start_time == Time.get_ticks_msec() / 1000.0
#       run_currency == 0.0
#       current_room == null
#       current_room_index == 0
#       cleared_rooms == {}
```

---

### `end_run() -> void`

Ends the active run. No-op if no run is active.

```gdscript
# Pre:  none (safe to call at any time)
# Post: is_run_active == false
#       run_ended signal emitted exactly once (if run was active)
#       All session fields remain readable until next start_run()
```

---

### `register_room(spawner: Node) -> void`

Called by RoomSpawner in its `_ready()`. Connects RunManager to the spawner's signals.

```gdscript
# Pre:  spawner has signals room_entered(room_id: String) and room_cleared
# Post: RunManager connected to spawner.room_entered → _on_room_entered
#       RunManager connected to spawner.room_cleared  → _on_room_cleared
```

---

### `add_currency(amount: float) -> void`

Adds gold to the current run total.

```gdscript
# Pre:  none (no-op with push_warning if run not active)
# Post: run_currency = maxf(run_currency + amount, 0.0)
```

---

## Internal Handlers (not called externally)

### `_on_room_entered(room_id: String, spawner: Node) -> void`

Bound via `register_room`. Updates room tracking state.

```gdscript
# Guard: return if not is_run_active
# Post:  current_room = spawner
#        current_room_index += 1
```

### `_on_room_cleared(room_id: String) -> void`

Bound via `register_room`. Re-emits the cleared signal for other systems.

```gdscript
# Guard: return if not is_run_active
# Post:  mark_room_cleared(room_id) called
#        room_cleared(room_id) signal emitted
```

---

## Service Access

```gdscript
var difficulty_service: DifficultyService   # RunManager.difficulty_service.get_multiplier()
var rewards_service: RewardsService         # RunManager.rewards_service.get_room_reward(room_id)
```

Both are initialised in `_ready()`. Callers never instantiate services directly.

---

## Preserved Methods (unchanged)

```gdscript
func mark_room_cleared(room_id: String) -> void   # existing
func is_room_cleared(room_id: String) -> bool     # existing
func start_new_run() -> void                      # existing — superseded by start_run() but kept for compatibility
```
