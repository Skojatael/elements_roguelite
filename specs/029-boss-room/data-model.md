# Data Model: Boss Room

**Feature**: [spec.md](spec.md)
**Date**: 2026-03-05

---

## EnemyData (extended)

**File**: `scripts/data_models/EnemyData.gd`
**Type**: `Resource` (existing class, extended)

| Field | Type | Source (JSON key) | Notes |
|-------|------|-------------------|-------|
| `id` | `String` | `id` | Existing |
| `display_name` | `String` | `display_name` | Existing |
| `max_health` | `float` | `max_health` | Existing |
| `damage` | `float` | `damage` | Existing |
| `move_speed` | `float` | `move_speed` | Existing |
| `detection_range` | `float` | `detection_range` | Existing |
| `damage_cooldown` | `float` | `damage_cooldown` | Existing; maps to user-specified `attack_interval` |
| `base_essence` | `float` | `base_essence` | Existing |
| `rooms_required` | `int` | `rooms_required` | **NEW** — rooms cleared to unlock boss; 0 for non-boss enemies |

**Factory**: `EnemyData.from_dict(data)` — add optional parse: `d.rooms_required = int(data.get("rooms_required", 0))`

---

## enemies.json — new categorised structure

**File**: `data/enemies.json` (full file replace — flat array → category dictionary)

```json
{
    "enemies": {
        "common": [
            {
                "id": "slime",
                "display_name": "Slime",
                "max_health": 10.0,
                "damage": 1.0,
                "move_speed": 60.0,
                "detection_range": 200.0,
                "damage_cooldown": 0.5,
                "base_essence": 10
            },
            {
                "id": "skeleton",
                "display_name": "Skeleton",
                "max_health": 8.0,
                "damage": 2.0,
                "move_speed": 80.0,
                "detection_range": 250.0,
                "damage_cooldown": 1.0,
                "base_essence": 15
            }
        ],
        "boss": [
            {
                "id": "boss",
                "display_name": "Boss",
                "max_health": 40.0,
                "damage": 5.0,
                "move_speed": 60.0,
                "detection_range": 300.0,
                "damage_cooldown": 2.0,
                "base_essence": 0,
                "rooms_required": 6
            }
        ]
    }
}
```

**Schema**: `"enemies"` is now a Dictionary keyed by category name; each value is an Array of enemy entry objects. Entry objects are unchanged in structure.

**Breaking change**: `parsed["enemies"]` is now a Dictionary, not an Array. Two consumers must be updated to iterate over `enemies.values()`:
- `Enemy.gd` — `_ready()` lookup loop
- `ResourceManagerImpl._load_enemy_data()` — cache-population loop

**Notes**:
- `damage_cooldown: 2.0` satisfies spec requirement `attack_interval=2`
- `rooms_required: 6` is the unlock threshold (FR-007); field is absent from common enemies (defaults to 0 in EnemyData)
- `base_essence: 0` — boss does not award essence directly (out of scope for this feature)
- Category keys (`"common"`, `"boss"`) are not read by game code; consumers iterate all values

---

## dungeon_config.json — BossRoom01 spawn_config

**File**: `data/dungeon_config.json` (add to `spawn_configs` dictionary)

```json
"BossRoom01": {
  "spawn_points": [
    { "enemy_id": "boss", "position": { "x": 0, "y": 0 }, "radius": 0 }
  ]
}
```

**Notes**:
- Single spawn point at room center, zero radius (boss always spawns at exact center)
- `RoomSpawner._load_config()` will validate that `enemy_id: "boss"` exists in enemies.json
- No `enemy_count_mult` or `essence_mult` — defaults to 1.0

---

## ResourceManagerImpl — new cache fields

**File**: `scripts/managers/ResourceManager.gd`

| Cache field | Type | Purpose |
|-------------|------|---------|
| `_enemy_rooms_required_cache` | `Dictionary` | Maps `enemy_id → rooms_required` (int), populated in `_load_enemy_data()` |

New method:
```gdscript
func get_enemy_rooms_required(id: String) -> int:
    if not _enemy_ids_loaded:
        _load_enemy_data()
    return _enemy_rooms_required_cache.get(id, 0)
```

---

## Boss HP scaling (computed, not stored)

Computed at teleport time in `Main._on_boss_teleport_pressed()`. Not persisted.

| Symbol | Source |
|--------|--------|
| `base_hp` | `EnemyData.max_health` from enemies.json (40.0) |
| `rooms_cleared` | `RunManager.cleared_rooms.size()` at teleport time |
| `boss_mult` | `1.0 + 0.06 * float(rooms_cleared)` |
| Applied via | `spawner.difficulty_mult = boss_mult` → `Enemy.apply_difficulty(boss_mult)` |

Result: `spawner._stats.max_health = 40.0 × boss_mult` (float precision)

---

## Constants

Defined in `Main.gd`:

| Constant | Type | Value | Notes |
|----------|------|-------|-------|
| `BOSS_ROOM_WORLD_POS` | `Vector2` | `Vector2(0, -3000)` | North of hub, outside dungeon grid |

Defined in `ExplorationHUD.gd`:

| Constant | Type | Value | Notes |
|----------|------|-------|-------|
| `BOSS_ENEMY_ID` | `String` | `"boss"` | Used to look up `rooms_required` from ResourceManager |
