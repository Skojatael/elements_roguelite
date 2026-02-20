# Data Model: Enemy Spawning

**Feature**: 003-enemy-spawning
**Date**: 2026-02-20

---

## New Entities

### SpawnPointData

**File**: `scripts/data_models/SpawnPointData.gd`
**Extends**: `RefCounted`
**Purpose**: Typed GDScript wrapper for a single spawn point entry from JSON.

| Field | GDScript Type | JSON Key | Constraints |
|-------|--------------|----------|-------------|
| `enemy_id` | `String` | `"enemy_id"` | Must match an `id` in `enemies.json`; validated by `RoomSpawner` at load time |
| `position` | `Vector2` | `"position"` (object with `"x"`, `"y"`) | World-space coordinates within the room |
| `radius` | `float` | `"radius"` | ≥ 0.0; 0 = exact position; no upper bound enforced in data model |

**Validation rules**:
- `enemy_id` MUST be non-empty.
- `radius` MUST be ≥ 0.0.

---

### RoomSpawnConfig

**File**: `scripts/data_models/RoomSpawnConfig.gd`
**Extends**: `RefCounted`
**Purpose**: Typed wrapper for the complete spawn configuration of one room type.

| Field | GDScript Type | Description |
|-------|--------------|-------------|
| `room_id` | `String` | Matches the key in `dungeon_config.json → spawn_configs` and the `room_id` export on `RoomSpawner` |
| `spawn_points` | `Array[SpawnPointData]` | Ordered list of spawn point definitions; length MUST be ≤ 10 |

**Validation rules**:
- `spawn_points.size()` MUST be ≤ 10 (enforced by `RoomSpawner._ready()`).
- Missing `spawn_configs` key for a `room_id` → treated as empty config (no error; FR-002).

---

## Modified Entities

### dungeon_config.json (extended)

**File**: `data/dungeon_config.json`
**Change**: Add top-level `"spawn_configs"` object. Each key is a `room_id` string; each value is an object with a `"spawn_points"` array.

**Schema**:

```json
{
  "spawn_configs": {
    "<room_id>": {
      "spawn_points": [
        {
          "enemy_id": "<string>",
          "position": { "x": <float>, "y": <float> },
          "radius": <float>
        }
      ]
    }
  }
}
```

**Example** (two-room minimum for independent test US2):

```json
{
  "spawn_configs": {
    "CombatRoom01": {
      "spawn_points": [
        { "enemy_id": "slime", "position": { "x": -100, "y": 0 }, "radius": 30 },
        { "enemy_id": "slime", "position": { "x":  100, "y": 0 }, "radius": 30 }
      ]
    },
    "CombatRoom02": {
      "spawn_points": [
        { "enemy_id": "skeleton", "position": { "x": 0, "y": 0 }, "radius": 0 }
      ]
    }
  }
}
```

---

### RunManager (extended)

**File**: `autoload/RunManager.gd` (and `scripts/managers/RunManager.gd` if separate)
**Change**: Add `cleared_rooms` dictionary and two public methods.

| Addition | Type | Description |
|----------|------|-------------|
| `cleared_rooms` | `Dictionary` | Keys: `room_id` strings; values: `true`. Reset on new run. |
| `mark_room_cleared(room_id: String) → void` | method | Adds `room_id` to `cleared_rooms`. |
| `is_room_cleared(room_id: String) → bool` | method | Returns `cleared_rooms.has(room_id)`. |

**State lifecycle**: `cleared_rooms` is populated during a run and reset (`cleared_rooms = {}`) when a new run begins. The specific "new run" signal/hook is out of scope for this feature; `RunManager` already manages run-start lifecycle.

---

## Entity Relationships

```
dungeon_config.json
  └── spawn_configs{}
        └── [room_id] → RoomSpawnConfig
              └── spawn_points[] → SpawnPointData
                    └── enemy_id → references enemies.json[id]

RoomSpawner (scene node)
  ├── reads RoomSpawnConfig from ResourceManager/dungeon_config.json
  ├── instantiates Enemy.tscn × N (one per SpawnPointData)
  ├── listens to Enemy.defeated signal × N
  ├── tracks living_count: int
  └── on living_count == 0 → emits room_cleared + calls RunManager.mark_room_cleared()

RunManager (autoload)
  └── cleared_rooms: Dictionary  ← written by RoomSpawner, read by RoomSpawner on entry
```
