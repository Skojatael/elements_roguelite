# Contract: RunManager Extension

**File**: `autoload/RunManager.gd`
**Change type**: Additive — new field and two methods; no existing API modified.

---

## New Field

```gdscript
var cleared_rooms: Dictionary = {}
```

- Keys: `room_id` strings (e.g. `"CombatRoom01"`).
- Values: `true` (presence = cleared; absence = not cleared).
- Lifetime: Current run only. Must be reset to `{}` when a new run begins.

---

## New Methods

```gdscript
func mark_room_cleared(room_id: String) -> void:
    cleared_rooms[room_id] = true

func is_room_cleared(room_id: String) -> bool:
    return cleared_rooms.has(room_id)
```

---

## Behaviour contract

- `mark_room_cleared` is idempotent — calling it multiple times for the same `room_id` has no side effect.
- `is_room_cleared` never errors on an unknown `room_id`; returns `false`.
- `cleared_rooms` reset: when a new run starts (exact hook is existing `RunManager` responsibility; this feature only requires the field exists and is reset).

---

## Consumers

| Consumer | Method called |
|----------|--------------|
| `RoomSpawner` | `is_room_cleared(room_id)` on player entry |
| `RoomSpawner` | `mark_room_cleared(room_id)` when last enemy defeated |
