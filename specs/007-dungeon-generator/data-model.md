# Data Model: Dungeon Generator

**Feature**: 007-dungeon-generator
**Date**: 2026-02-23

---

## Entities

### DungeonGenerator *(new)*

Runtime node responsible for reading the room sequence and orchestrating spawning on run start.

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `ROOM_SPACING` | `int` (const) | GDScript | 1200 px — horizontal offset between consecutive room origins |

**Behaviour**:
- Connects to `RunManager.run_started` in `_ready()`
- On signal: reads `room_sequence` from `dungeon_config.json`, loads each RoomData `.tres`, calls `RunManager.spawn_room()`, then places the player

**Location**: `scenes/dungeon/DungeonGenerator.gd` — attached to a `Node` child of `Main.tscn` (added via Editor)

---

### RoomData *(existing — 006-room-factory)*

Resource type loaded from `data/rooms/<room_type_id>.tres`. Already implemented.

| Field | Type | Notes |
|-------|------|-------|
| `room_type_id` | `String` | Matches key in `dungeon_config.json → room_sequence` |
| `scene` | `PackedScene` | The room scene to instantiate |

---

### SpawnContext *(existing — 006-room-factory)*

Parameter bundle passed to `RunManager.spawn_room()`.

| Field | Type | Set by |
|-------|------|--------|
| `parent` | `Node` | DungeonGenerator: `get_parent()` |
| `position` | `Vector2` | DungeonGenerator: `origin + Vector2(i * ROOM_SPACING, 0)` |

---

## Config Schema Changes

### dungeon_config.json — new key: `room_sequence`

```json
{
  "room_sequence": ["CombatRoom01", "CombatRoom02", "EliteRoom01"],
  "spawn_configs": { ... }
}
```

| Key | Type | Description |
|-----|------|-------------|
| `room_sequence` | `Array[String]` | Ordered list of `room_type_id` values to spawn, first → last |

**Consumed by**: `DungeonGenerator._generate()` via `ResourceManager.get_dungeon_config()`

**Validation**: If key is missing or empty, generator logs an error and returns without spawning.

---

## Signal Contract: RunManager.run_started

**New signal added to RunManager**:

```gdscript
signal run_started(mode: String)
```

| Detail | Value |
|--------|-------|
| Emitted by | `RunManager.start_run()` — at the end, after all state is reset |
| Parameter | `mode: String` — the run mode passed to `start_run()` |
| Connected by | `DungeonGenerator._ready()` |
| Handler | `DungeonGenerator._on_run_started(mode: String)` |

---

## Relationships

```
RunManager ──run_started──► DungeonGenerator
                                  │
                        reads dungeon_config.json
                           (room_sequence key)
                                  │
                     for each room_type_id:
                      load("data/rooms/{id}.tres")
                                  │
                            RoomData (.tres)
                                  │
                    RunManager.spawn_room(data, id, ctx)
                                  │
                            RoomFactory
                                  │
                           RoomSpawner (returned)
                                  │
              (first room) ──► place player via group "player"
```
