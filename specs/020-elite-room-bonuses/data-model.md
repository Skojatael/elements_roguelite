# Data Model: Elite Room Bonuses

## dungeon_config.json — spawn_configs extension

Each entry in `spawn_configs` gains two optional fields (both default to `1.0` when absent):

| Field              | Type    | Default | Description                                                     |
|--------------------|---------|---------|------------------------------------------------------------------|
| `enemy_count_mult` | `float` | `1.0`   | Total enemy count = `floor(base_count × enemy_count_mult)`.     |
| `essence_mult`     | `float` | `1.0`   | Per-kill essence multiplier applied after depth scaling.         |

**EliteRoom01 values**: `enemy_count_mult: 1.5`, `essence_mult: 1.8`
**All other room types**: omit both fields (defaults to `1.0` — no change).

**Pre-computed results for EliteRoom01** (base = 2 spawn_points):

| Metric              | Value                                   |
|---------------------|-----------------------------------------|
| Total enemies       | `floor(2 × 1.5)` = **3**               |
| Extra enemy (index 2) | slime (index 2 % 2 = 0 → entry 0)   |
| Essence per slime at depth 1   | `floor(10 × 1.0 × 1.8)` = 18  |
| Essence per skeleton at depth 1 | `floor(15 × 1.0 × 1.8)` = 27 |
| Essence per slime at depth 2   | `floor(10 × 1.1 × 1.8)` = 19  |

---

## RoomSpawnConfig (`scripts/data_models/RoomSpawnConfig.gd`) — modified

| Field              | Type                    | Default | Description                              |
|--------------------|-------------------------|---------|------------------------------------------|
| `room_id`          | `String`                | `""`    | Existing — room type identifier.         |
| `spawn_points`     | `Array[SpawnPointData]` | `[]`    | Existing — base enemy definitions.       |
| `enemy_count_mult` | `float`                 | `1.0`   | NEW — parsed from config entry.          |
| `essence_mult`     | `float`                 | `1.0`   | NEW — parsed from config entry.          |

`from_dict()` adds:
```gdscript
cfg.enemy_count_mult = float(data.get("enemy_count_mult", 1.0))
cfg.essence_mult = float(data.get("essence_mult", 1.0))
```

---

## RoomSpawner (`scripts/dungeon/RoomSpawner.gd`) — modified

### New public property

| Member         | Type    | Description                                                               |
|----------------|---------|---------------------------------------------------------------------------|
| `essence_mult` | `float` | Computed property. Returns `_config.essence_mult` (or `1.0` if null).    |

### `_spawn_enemies()` logic change

**Before**:
```
_living_count = _config.spawn_points.size()
for sp in spawn_points: spawn one enemy at sp.position
```

**After**:
```
base_count = spawn_points.size()
_living_count = mini(floori(base_count * enemy_count_mult), MAX_ENEMIES)
for i in _living_count:
    sp = spawn_points[i % base_count]
    spawn enemy using sp.enemy_id and sp.radius
```

---

## RunManager (`scripts/managers/RunManager.gd`) — modified

### `_on_enemy_defeated()` essence formula change

**Before**: `essence = floor(base_essence × (1 + depth_scale × (depth − 1)))`

**After**: `essence = floor(base_essence × (1 + depth_scale × (depth − 1)) × room_essence_mult)`

Where `room_essence_mult` = `(current_room as RoomSpawner).essence_mult` (1.0 for
non-elite rooms, 1.8 for EliteRoom01).

---

## Modified files summary

| File | Change |
|------|--------|
| `data/dungeon_config.json` | Add `enemy_count_mult: 1.5, essence_mult: 1.8` to EliteRoom01 spawn config |
| `scripts/data_models/RoomSpawnConfig.gd` | Add `enemy_count_mult` and `essence_mult` fields; parse in `from_dict()` |
| `scripts/dungeon/RoomSpawner.gd` | Change `_spawn_enemies()` to use multiplier + cycle; expose `essence_mult` property |
| `scripts/managers/RunManager.gd` | Apply `essence_mult` from current room in `_on_enemy_defeated()` |

No new files. No new scenes. No new autoloads.
