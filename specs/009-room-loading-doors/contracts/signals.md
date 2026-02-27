# Signal Contracts: Room Loading & Doors (009)

**Date**: 2026-02-24
**Feature**: [spec.md](../spec.md)

---

## New Signal: `DungeonGenerator.dungeon_layout_ready`

| Property | Value |
|---|---|
| Declared in | `scenes/dungeon/DungeonGenerator.gd` |
| Emitter | `DungeonGenerator._generate()` — emitted at end of method, after `rooms_by_id`, `neighbours_by_id`, and `start_room_id` are fully populated |
| Consumer | `scenes/dungeon/RoomLoader.gd` |
| Connected in | `RoomLoader._ready()` |
| Handler | `RoomLoader._on_layout_ready()` |
| Payload | *(none)* |
| Effect | RoomLoader loads the start room scene, configures its doors, places the player at room center |

**Contract**: When `dungeon_layout_ready` fires, `DungeonGenerator.rooms_by_id`, `DungeonGenerator.neighbours_by_id`, and `DungeonGenerator.start_room_id` are fully populated and safe to read. The signal fires exactly once per `run_started` event.

**Ordering guarantee**: `DungeonGenerator` connects to `RunManager.run_started`; `RoomLoader` connects to `DungeonGenerator.dungeon_layout_ready`. This chain guarantees RoomLoader always runs after the layout is ready — no fragile signal-order dependency on tree position.

---

## New Signal: `Door.door_activated`

| Property | Value |
|---|---|
| Declared in | `scenes/dungeon/doors/Door.gd` |
| Emitter | `Door._on_body_entered(body)` — emitted when a body in group `"player"` enters the Area2D |
| Consumer | `scenes/dungeon/RoomLoader.gd` |
| Connected in | `RoomLoader._configure_doors()` — after each room load |
| Handler | `RoomLoader._on_door_activated(direction, target_room_id)` |
| Payload | `direction: String`, `target_room_id: String` |
| Effect | RoomLoader frees the current room and loads the adjacent room |

**Contract**:
- `direction` is one of `"N"`, `"S"`, `"E"`, `"W"` — always the direction the door faces in the current room.
- `target_room_id` is a valid key in `DungeonGenerator.rooms_by_id`.
- The signal fires only when `door.visible == true` and `door.monitoring == true`. Hidden doors have monitoring disabled and never emit.
- RoomLoader uses `_loading` flag to ignore the signal if a load is already in progress (guards against simultaneous door touch).

---

## Consumed Signal: `RunManager.run_started`

| Property | Value |
|---|---|
| Emitter | `autoload/RunManager.gd` |
| Consumer | `scenes/dungeon/DungeonGenerator.gd` (unchanged from feature 008) |
| Handler | `DungeonGenerator._on_run_started(mode)` |
| Effect | Runs `_generate()`, which emits `dungeon_layout_ready` at the end |

`RoomLoader` does NOT connect directly to `run_started`. It relies on `dungeon_layout_ready` for sequencing.

---

## Consumed Properties: `DungeonGenerator` output interface

`RoomLoader` reads these properties after `dungeon_layout_ready` fires (same output interface as feature 008):

| Property | Type | Description |
|---|---|---|
| `rooms_by_id` | `Dictionary` | `room_id → { room_type_id, grid_pos: Vector2i, world_pos: Vector2 }` |
| `neighbours_by_id` | `Dictionary` | `room_id → Array[String]` of adjacent room_ids |
| `start_room_id` | `String` | Always `"room_2_2"` |

---

## Downstream Signals (unchanged)

These signals are produced by `RoomSpawner` nodes, consumed by `RunManager`. Unchanged from features 003 and 004.

| Signal | Emitter | Payload | Description |
|---|---|---|---|
| `room_entered(room_id)` | `RoomSpawner` | `String` | Player entered the room's EntryArea |
| `room_cleared(room_id)` | `RoomSpawner` | `String` | All enemies defeated; RunManager calls `mark_room_cleared(room_id)` |

`RunManager.register_room(spawner)` connects to both — called by `RoomSpawner._ready()` when `auto_register = true` (default for scenes spawned through `RunManager.spawn_room()`).

---

## Config Contract

`RoomLoader` loads `RoomData` resources by type ID. Each room type must have a corresponding `.tres` file:

| Resource Path | Room Type | Required |
|---|---|---|
| `res://data/rooms/StartRoom01.tres` | `"StartRoom01"` | Yes — new in this feature |
| `res://data/rooms/CombatRoom01.tres` | `"CombatRoom01"` | Yes — existing |
| `res://data/rooms/CombatRoom02.tres` | `"CombatRoom02"` | Yes — existing |

**Failure mode**: If `load(path)` returns `null`, `RoomLoader` calls `push_error(...)`, releases the `_loading` guard, and does not transition. The current room remains.

`data/dungeon_config.json` gains a `StartRoom01` entry in `spawn_configs`:

```json
{
  "combat_room_pool": ["CombatRoom01", "CombatRoom02"],
  "spawn_configs": {
    "StartRoom01": { "spawn_points": [] },
    "CombatRoom01": { "spawn_points": [ ... ] },
    "CombatRoom02": { "spawn_points": [ ... ] }
  }
}
```

`RoomSpawner` looks up the type ID in `spawn_configs`. An empty `spawn_points` array produces zero enemies — the intended behaviour for `StartRoom01`.
