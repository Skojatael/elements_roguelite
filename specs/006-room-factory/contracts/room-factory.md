# Contract: RoomFactory

**Feature**: 006-room-factory
**Date**: 2026-02-23

---

## RoomFactory

**File**: `scenes/dungeon/RoomFactory.gd`

```gdscript
class_name RoomFactory
extends RefCounted

func spawn_room(room_data: RoomData, room_id: String, context: SpawnContext) -> RoomSpawner
```

### Preconditions

- `room_data` MUST NOT be null and `room_data.scene` MUST NOT be null.
- `room_id` MUST be supplied by the caller — factory MUST NOT generate or modify it.
- `context.parent` MUST be a valid Node currently in the scene tree.
- `context.position` MAY be any `Vector2`.

### Postconditions (success)

- `room_data.scene` is instantiated and added as a child of `context.parent`.
- The room root's `global_position` equals `context.position`.
- The RoomSpawner inside the room has `room_id` set to the supplied value.
- The RoomSpawner has `auto_register = false` — it does NOT call `RunManager.register_room()`.
- The `RoomSpawner` is returned.

### Postconditions (failure — null room_data or null scene)

- `push_error` is called with a descriptive message.
- `null` is returned.
- No scene is instantiated; no node is added to the scene tree.

### Constraints

- Factory MUST NOT generate room IDs.
- Factory MUST NOT maintain an internal scene registry — scene reference lives in `room_data.scene`.
- Factory MUST NOT call `RunManager` directly — all RunManager wiring is the caller's responsibility.
- Factory MUST NOT store state between calls (stateless per call).

---

## SpawnContext

**File**: `scripts/data_models/SpawnContext.gd`

```gdscript
class_name SpawnContext
extends RefCounted

var parent: Node
var position: Vector2

static func create(p_parent: Node, p_position: Vector2) -> SpawnContext
```

---

## RunManager Integration Contract

```gdscript
# Spawn a factory room — RunManager is the caller
var room_data: RoomData = load("res://data/rooms/CombatRoom01.tres")
var context := SpawnContext.create(world_node, Vector2(0, 0))
var spawner := RunManager.spawn_room(room_data, "room_001", context)
# spawner.room_entered and spawner.room_cleared are already connected
# current_room is set to spawner

# Pre-placed room auto-registration (backward compat — unchanged)
# RoomSpawner._ready() calls RunManager.register_room(self) when auto_register=true
RunManager.register_room(spawner)
```

### RunManager.spawn_room()

```gdscript
func spawn_room(room_data: RoomData, room_id: String, context: SpawnContext) -> RoomSpawner
```

- Delegates to `room_factory.spawn_room()`
- On success: connects spawner signals to internal handlers; sets `current_room = spawner`
- On failure (null returned): logs warning, does not update `current_room`
- MUST NOT generate `room_id` — caller supplies it

### RunManager.register_room() (unchanged externally)

```gdscript
func register_room(spawner: Node) -> void
```

- Connects spawner signals to internal handlers; sets `current_room = spawner`
- Signature and behaviour unchanged from 004-run-manager
