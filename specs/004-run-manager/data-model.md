# Data Model: Run Manager

**Feature**: 004-run-manager
**Date**: 2026-02-21

---

## RunSession (in-memory, not persisted)

Holds all state for the currently active run. Lives inside `autoload/RunManager.gd`. Reset on every `start_run()` call.

| Field | Type | Initial Value | Description |
|---|---|---|---|
| `run_id` | `String` | `""` | Temporary unique identifier for this run. Set to `str(Time.get_ticks_msec())` on start. |
| `is_run_active` | `bool` | `false` | True between `start_run()` and `end_run()`. |
| `run_mode` | `String` | `""` | `"endless"` or `"boss"`. Set by caller of `start_run(mode)`. |
| `current_tier` | `int` | `1` | Difficulty tier. Set to 1 on start; updated externally by meta-progression. |
| `run_start_time` | `float` | `0.0` | Engine time at run start (`Time.get_ticks_msec()` as float, seconds). |
| `run_currency` | `float` | `0.0` | Gold accumulated this run. Never drops below 0. |
| `current_room` | `Node` | `null` | Reference to the active `RoomSpawner` node. Null between rooms. |
| `current_room_index` | `int` | `0` | How many rooms the player has entered this run. Starts at 0; increments on each room entry. |
| `cleared_rooms` | `Dictionary` | `{}` | Map of `room_id → true` for rooms cleared this run. Carried forward from existing implementation. |

### State Transitions

```
[No run]
    │  start_run(mode)
    ▼
[Run Active]  ──── register_room() ───►  current_room updated
    │         ──── add_currency()  ───►  run_currency updated
    │         ──── room_cleared   ────►  cleared_rooms updated, room_cleared signal
    │  end_run()
    ▼
[Run Ended]   ← state readable, is_run_active = false
    │  start_run(mode)
    ▼
[Run Active]  ← full reset, new run_id
```

---

## DifficultyService

Stub. Lives in `scripts/services/DifficultyService.gd`. Owned by RunManager (instantiated in `_ready()`). Accessed via `RunManager.difficulty_service`.

| Method | Signature | Returns | Notes |
|---|---|---|---|
| `get_multiplier` | `() -> float` | `1.0` | Stub. Future: calculated from `current_tier` and `current_room_index`. |

---

## RewardsService

Stub. Lives in `scripts/services/RewardsService.gd`. Owned by RunManager. Accessed via `RunManager.rewards_service`.

| Method | Signature | Returns | Notes |
|---|---|---|---|
| `get_room_reward` | `(room_id: String) -> Dictionary` | `{}` | Stub. Future: returns loot table keyed by reward type. |

---

## RoomSpawner — Extended Fields

Changes to the existing `scenes/dungeon/RoomSpawner.gd` to support RunManager integration.

| Addition | Type | Description |
|---|---|---|
| `signal room_entered(room_id: String)` | Signal | Emitted when the player enters this room (after all guards pass). |
| `RunManager.register_room(self)` call | Behaviour | Called in `_ready()` so RunManager can connect to this spawner's signals. |

No new stored fields — all additions are signals and method calls.
