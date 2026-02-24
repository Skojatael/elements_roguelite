# Data Model: Room Factory

**Feature**: 006-room-factory
**Date**: 2026-02-23

---

## RoomData

**File**: `scripts/data_models/RoomData.gd`
**Type**: `Resource` — Godot resource; instances saved as `.tres` files in `res://data/rooms/`

| Field | Type | Description |
|---|---|---|
| `room_type_id` | `String` | Unique identifier for this room type (e.g. `"CombatRoom01"`) |
| `scene` | `PackedScene` | The room scene to instantiate |

Both fields are `@export` — set in the Godot Inspector when authoring each `.tres` file.

**Asset locations** (one `.tres` per room type):

| Asset | room_type_id | scene |
|---|---|---|
| `res://data/rooms/CombatRoom01.tres` | `"CombatRoom01"` | `CombatRoom01.tscn` |
| `res://data/rooms/CombatRoom02.tres` | `"CombatRoom02"` | `CombatRoom02.tscn` |
| `res://data/rooms/EliteRoom01.tres` | `"EliteRoom01"` | `EliteRoom01.tscn` |
| `res://data/rooms/BossRoom01.tres` | `"BossRoom01"` | `BossRoom01.tscn` |

**Constraints**:
- `scene` MUST NOT be null — validated by RoomFactory before instantiation
- Adding a new room type requires only creating a new `.tres` asset — no code changes

---

## SpawnContext

**File**: `scripts/data_models/SpawnContext.gd`
**Type**: `RefCounted` — plain data bundle, no behaviour

| Field | Type | Description |
|---|---|---|
| `parent` | `Node` | The scene-tree node to `add_child` the room under |
| `position` | `Vector2` | World position to place the room root node |

**Factory method**: `SpawnContext.create(parent: Node, position: Vector2) -> SpawnContext`

**Constraints**:
- `parent` MUST be in the scene tree at the time `spawn_room()` is called
- `position` is applied as `global_position` on the room root after `add_child()`

---

## RoomFactory

**File**: `scenes/dungeon/RoomFactory.gd`
**Type**: `RefCounted` — stateless service; no internal scene registry

**Method**:

```
spawn_room(room_data: RoomData, room_id: String, context: SpawnContext) -> RoomSpawner
```

| Parameter | Type | Description |
|---|---|---|
| `room_data` | `RoomData` | Resource asset describing the room type; carries `scene` and `room_type_id` |
| `room_id` | `String` | Caller-supplied instance identifier — factory passes through, never generates |
| `context` | `SpawnContext` | Parent node and world position |

**Returns**: `RoomSpawner` on success; `null` on invalid input (error logged).

**Execution sequence**:
1. Validate `room_data` is not null and `room_data.scene` is not null — `push_error` + return `null` if invalid
2. Instantiate `room_data.scene`
3. Locate the `RoomSpawner` child on the instantiated root
4. Set `spawner.room_id = room_id` (before `add_child` so `_ready()` gets the correct value)
5. Set `spawner.auto_register = false` (prevent RoomSpawner from auto-registering with RunManager)
6. Call `context.parent.add_child(room_root)`
7. Set `room_root.global_position = context.position`
8. Return `spawner`

---

## RoomSpawner Changes

**File**: `scenes/dungeon/RoomSpawner.gd` — one field added

| Field | Type | Default | Description |
|---|---|---|---|
| `auto_register` | `bool` | `true` | When false, skips `RunManager.register_room(self)` in `_ready()` |

The existing `_ready()` call `RunManager.register_room(self)` is guarded:
```gdscript
if auto_register:
    RunManager.register_room(self)
```

Pre-placed rooms in the Editor continue to work unchanged (`auto_register` defaults to `true`).

---

## RunManager Changes

**File**: `autoload/RunManager.gd`

| Change | Detail |
|---|---|
| Add field | `var room_factory: RoomFactory` |
| Init | `room_factory = RoomFactory.new()` in `_ready()` |
| `current_room` type | Remains `Node` (RoomSpawner is a Node) |
| Add method | `spawn_room(room_data, room_id, context) -> RoomSpawner` — delegates to factory, connects spawner signals |
| Update | `register_room(spawner)` — unchanged externally; internally sets `current_room = spawner` |

### spawn_room() wiring in RunManager

```gdscript
func spawn_room(room_data: RoomData, room_id: String, context: SpawnContext) -> RoomSpawner:
    var spawner := room_factory.spawn_room(room_data, room_id, context)
    if spawner:
        spawner.room_entered.connect(_on_room_entered.bind(spawner))
        spawner.room_cleared.connect(_on_room_cleared)
        current_room = spawner
    return spawner
```
