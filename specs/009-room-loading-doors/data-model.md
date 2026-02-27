# Data Model: Room Loading & Doors (009)

**Date**: 2026-02-24
**Feature**: [spec.md](spec.md)

---

## New GDScript Node: `RoomLoader`

`scenes/dungeon/RoomLoader.gd` — `Node` child of Main.tscn, sibling of `DungeonGenerator`.

### Runtime State

| Field | Type | Default | Description |
|---|---|---|---|
| `_loading` | `bool` | `false` | Guard flag — true while a room load is in progress; ignores additional door activations |
| `_current_room_node` | `Node` | `null` | Root node of the room scene currently present in the scene tree |
| `_dungeon_gen` | `DungeonGenerator` | `null` | Reference to sibling DungeonGenerator; obtained in `_ready()` |

### Constants

| Constant | Type | Value | Description |
|---|---|---|---|
| `ENTRY_OFFSET` | `float` | `150.0` | Pixels inward from wall edge where player is placed on room entry |
| `OPPOSITE` | `Dictionary` | `{"N":"S","S":"N","E":"W","W":"E"}` | Maps door direction to its opposite for player entry placement |
| `ENTRY_LOCAL` | `Dictionary` | *(see below)* | Maps entry-side direction to local Vector2 offset from room world_pos |

**`ENTRY_LOCAL` values** (relative to room center at `world_pos`):

| Entry Side | Local Offset | Comment |
|---|---|---|
| `"N"` | `Vector2(0, -540 + 150)` = `Vector2(0, -390)` | Entered through north wall, 150px inside |
| `"S"` | `Vector2(0, 540 - 150)` = `Vector2(0, 390)` | Entered through south wall, 150px inside |
| `"E"` | `Vector2(960 - 150, 0)` = `Vector2(810, 0)` | Entered through east wall, 150px inside |
| `"W"` | `Vector2(-960 + 150, 0)` = `Vector2(-810, 0)` | Entered through west wall, 150px inside |

**Start room**: player placed at `world_pos` (room center); no entry direction applies.

### Key Behaviours

- Connects to `DungeonGenerator.dungeon_layout_ready` in `_ready()`.
- On `_on_layout_ready()`: overrides start room type to `"StartRoom01"`, loads and places the room.
- On `_on_door_activated(direction, target_room_id)`: sets `_loading = true`, frees current room, spawns next room, configures doors, places player.
- Reads layout data from `DungeonGenerator.rooms_by_id` and `DungeonGenerator.neighbours_by_id`.
- Loads `RoomData` resources from `res://data/rooms/{room_type_id}.tres`.
- Calls `RunManager.spawn_room(room_resource, room_id, context)` for room instantiation.
- Sets `RunManager.current_room = null` before `queue_free()` on the outgoing room.

---

## New Entity: `Door`

`scenes/dungeon/doors/Door.gd` — script attached to `scenes/dungeon/doors/Door.tscn`.

### Scene Structure

```
Door.tscn
└── Area2D (Door.gd attached)
    └── CollisionShape2D (RectangleShape2D 200×200)
```

### Exported Properties

| Property | Type | Description |
|---|---|---|
| `direction` | `String` | Cardinal direction this door faces: `"N"`, `"S"`, `"E"`, or `"W"` |
| `target_room_id` | `String` | room_id of the room this door connects to; set by RoomLoader at room load time |

### Signal

| Signal | Payload | Description |
|---|---|---|
| `door_activated(direction: String, target_room_id: String)` | direction, target_room_id | Emitted when a body in group `"player"` enters the Area2D |

### Behaviour

- Monitors `body_entered` on the Area2D.
- On entry: if body is in group `"player"`, emits `door_activated`.
- Is shown (`visible = true`) or hidden (`visible = false`) by `RoomLoader._configure_doors()`.
- When hidden, its `CollisionShape2D` is also disabled (visibility does not disable collision automatically — RoomLoader must also set `monitoring = false` on hidden doors, or the Area2D's `CollisionShape2D` must be set to `disabled = true`).

### Door Slots in `RoomBase.tscn`

Four `Door.tscn` instances are added as children of `RoomBase.tscn` in the Godot Editor:

| Node Name | Local Position | Wall Edge |
|---|---|---|
| `DoorN` | `Vector2(0, -540)` | Top-center |
| `DoorS` | `Vector2(0, 540)` | Bottom-center |
| `DoorE` | `Vector2(960, 0)` | Right-center |
| `DoorW` | `Vector2(-960, 0)` | Left-center |

The collision shape (200×200) is centered at the door position — half inside the room, half outside.

---

## New Room Type: `StartRoom01`

A dedicated room type with no enemy spawning. Used only for the starting room of a run.

### Scene

`scenes/dungeon/rooms/StartRoom01.tscn` — inherited scene from `RoomBase.tscn`.

- `RoomSpawner.room_type_id` set to `"StartRoom01"` in the Editor.
- No additional modifications — inherits all four door slots from `RoomBase.tscn`.

### RoomData Resource

`data/rooms/StartRoom01.tres` — authored in the Godot Inspector.

| Field | Value |
|---|---|
| `room_type_id` | `"StartRoom01"` |
| `scene` | `scenes/dungeon/rooms/StartRoom01.tscn` |

### Spawn Config

`data/dungeon_config.json` gains a `StartRoom01` entry with an empty `spawn_points` array so `RoomSpawner` finds valid config and spawns zero enemies:

```json
"spawn_configs": {
  "StartRoom01": { "spawn_points": [] },
  "CombatRoom01": { ... },
  "CombatRoom02": { ... }
}
```

---

## Direction → Grid Offset Map

Used by `RoomLoader._configure_doors()` to determine which neighbour corresponds to each door direction.

| Direction | Grid Delta (Vector2i) |
|---|---|
| `"N"` | `(0, -1)` |
| `"S"` | `(0, 1)` |
| `"E"` | `(1, 0)` |
| `"W"` | `(-1, 0)` |

---

## Modified: `DungeonGenerator`

`scenes/dungeon/DungeonGenerator.gd` receives two changes:

1. **New signal**: `signal dungeon_layout_ready` — emitted at the end of `_generate()`, after `rooms_by_id`, `neighbours_by_id`, and `start_room_id` are fully populated.
2. **Remove `_place_player()` call**: the call to `_place_player(rooms_by_id[start_room_id]["world_pos"])` is removed from `_generate()`. The `_place_player()` function itself is also removed — `RoomLoader` owns all player placement from this feature forward.

These are the only changes to `DungeonGenerator`.

---

## Unchanged Systems

| System | Reason |
|---|---|
| `RoomSpawner.gd` | Fresh instantiation resets `_spawned = false`; `is_room_cleared()` check handles cleared rooms. No changes needed. |
| `RunManager.gd` | `cleared_rooms`, `current_room`, `spawn_room()`, `register_room()` all used as-is. |
| `RoomFactory.gd` | Called through `RunManager.spawn_room()` — unchanged. |
| `CombatRoom01.tscn`, `CombatRoom02.tscn` | Inherit `RoomBase.tscn` — they automatically inherit the four door slots once added to RoomBase. |
