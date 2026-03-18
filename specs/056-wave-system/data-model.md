# Data Model: Room Wave System

## New Data Model

### `WaveConfig` (`scripts/data_models/WaveConfig.gd`)

Typed wrapper around the top-level `wave_config` block in `dungeon_config.json`.

| Field | Type | Description |
|-------|------|-------------|
| `waves` | `Array[int]` | Enemy counts per wave in order. e.g. `[3, 2, 1]` |
| `trigger_threshold` | `int` | Alive count at which the next wave fires. e.g. `1` |
| `alive_cap` | `int` | Max enemies alive at any one time. e.g. `4` |
| `min_spawn_distance` | `float` | Minimum distance from player for a spawn point to be preferred. e.g. `200.0` |

Factory: `WaveConfig.from_dict(data: Dictionary) -> WaveConfig`

---

## Modified Data Models

### `RoomSpawnConfig` (`scripts/data_models/RoomSpawnConfig.gd`)

**New field**: `wave_config: WaveConfig` — populated by `RoomSpawner._load_config()` after `from_dict()` by reading the top-level `wave_config` key from the dungeon config. Defaults to `null`; spawner treats `null` as "no wave system — legacy flat spawn behaviour".

---

## JSON Schema Change

### `data/dungeon_config.json` — new top-level key

```json
"wave_config": {
  "waves": [3, 2, 1],
  "trigger_threshold": 1,
  "alive_cap": 4,
  "min_spawn_distance": 200.0
}
```

### `data/dungeon_config.json` — expanded combat room spawn points

**CombatRoom01**: 4 points at room quadrant corners (radius 40)

```json
"CombatRoom01": {
  "spawn_points": [
    { "enemy_id": "slime", "position": { "x": -350, "y": -250 }, "radius": 40 },
    { "enemy_id": "slime", "position": { "x":  350, "y": -250 }, "radius": 40 },
    { "enemy_id": "slime", "position": { "x": -350, "y":  250 }, "radius": 40 },
    { "enemy_id": "slime", "position": { "x":  350, "y":  250 }, "radius": 40 }
  ]
}
```

**CombatRoom02**: 4 points at cardinal positions (radius 30)

```json
"CombatRoom02": {
  "spawn_points": [
    { "enemy_id": "skeleton", "position": { "x": -300, "y":    0 }, "radius": 30 },
    { "enemy_id": "skeleton", "position": { "x":  300, "y":    0 }, "radius": 30 },
    { "enemy_id": "skeleton", "position": { "x":    0, "y": -250 }, "radius": 30 },
    { "enemy_id": "skeleton", "position": { "x":    0, "y":  250 }, "radius": 30 }
  ]
}
```

EliteRoom01 and BossRoom01 are unchanged — the wave system is not applied to them (see RoomSpawner guard logic below).

---

## RoomSpawner Runtime State (transient, not persisted)

| Field | Type | Initial | Description |
|-------|------|---------|-------------|
| `_wave_index` | `int` | `0` | Index of the next wave to spawn (0-based). |
| `_living_count` | `int` | `0` | Currently alive enemies across all waves. |
| `_total_killed` | `int` | `0` | Cumulative enemy deaths this room. |
| `_total_enemies` | `int` | `sum(waves)` | Total enemies to kill for room clear. Set in `_spawn_wave(0)`. |

### State Transitions

```
player enters room
    │
    ▼
_spawn_wave(0) → spawn 3 enemies, _living_count=3, _wave_index=1
    │
    │  enemy dies → _living_count=2, _total_killed=1
    │  enemy dies → _living_count=1, _total_killed=2
    │    alive (1) <= trigger_threshold (1)  →  _spawn_wave(1)
    ▼
_spawn_wave(1) → spawn 2 enemies, _living_count=3, _wave_index=2
    │
    │  enemy dies → _living_count=2, _total_killed=3
    │  enemy dies → _living_count=1, _total_killed=4
    │    alive (1) <= trigger_threshold (1)  →  _spawn_wave(2)
    ▼
_spawn_wave(2) → spawn 1 enemy, _living_count=2, _wave_index=3
    │
    │  enemy dies → _living_count=1, _total_killed=5
    │  enemy dies → _living_count=0, _total_killed=6
    │    _total_killed (6) == _total_enemies (6)  →  room_cleared
    ▼
room cleared ✓
```

Wave trigger check is skipped when `_wave_index >= waves.size()` (all waves exhausted).
