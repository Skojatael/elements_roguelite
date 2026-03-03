# Contracts: Elite Room Bonuses

## dungeon_config.json — spawn_configs schema extension

```json
"spawn_configs": {
    "EliteRoom01": {
        "enemy_count_mult": 1.5,
        "essence_mult": 1.8,
        "spawn_points": [
            { "enemy_id": "slime",    "position": { "x": -80, "y": 0 }, "radius": 20 },
            { "enemy_id": "skeleton", "position": { "x":  80, "y": 0 }, "radius": 20 }
        ]
    }
}
```

`enemy_count_mult` and `essence_mult` are **optional** in all room types. Absence = 1.0.

---

## RoomSpawnConfig (`scripts/data_models/RoomSpawnConfig.gd`)

```gdscript
class_name RoomSpawnConfig
extends Resource

var room_id: String
var spawn_points: Array[SpawnPointData]
var enemy_count_mult: float = 1.0    # NEW
var essence_mult: float = 1.0        # NEW

static func from_dict(p_room_id: String, data: Dictionary) -> RoomSpawnConfig:
    # ...existing spawn_points parsing...
    cfg.enemy_count_mult = float(data.get("enemy_count_mult", 1.0))
    cfg.essence_mult = float(data.get("essence_mult", 1.0))
    return cfg
```

---

## RoomSpawner (`scripts/dungeon/RoomSpawner.gd`)

```gdscript
# NEW computed property — read by RunManager
var essence_mult: float:
    get: return _config.essence_mult if _config != null else 1.0

# MODIFIED — _spawn_enemies() core loop
func _spawn_enemies() -> void:
    _spawned = true
    var base_count: int = _config.spawn_points.size()
    _living_count = mini(floori(float(base_count) * _config.enemy_count_mult), MAX_ENEMIES)
    if _living_count == 0:
        return
    for i in _living_count:
        var sp: SpawnPointData = _config.spawn_points[i % base_count]
        # ... spawn enemy using sp.enemy_id, sp.radius (unchanged mechanics)
```

**Invariants**:
- `_living_count` is always in `[0, MAX_ENEMIES]`.
- Standard rooms (`enemy_count_mult = 1.0`) produce `floor(n × 1.0) = n` — no change.
- Extra enemies beyond the base list cycle through `spawn_points` via modulo.

---

## RunManager (`scripts/managers/RunManager.gd`)

```gdscript
func _on_enemy_defeated(enemy_type_id: String) -> void:
    enemies_slain += 1
    var base_essence: float = ResourceManager.get_enemy_base_essence(enemy_type_id)
    var essence_depth_scale: float = ResourceManager.get_dungeon_config().get("essence_depth_scale", 0.10)
    var room_essence_mult: float = (current_room as RoomSpawner).essence_mult if current_room != null else 1.0
    var essence: int = floori(base_essence * (1.0 + essence_depth_scale * float(current_room_depth - 1)) * room_essence_mult)
    if essence > 0:
        add_currency(float(essence))
```

**Invariants**:
- Non-elite rooms: `room_essence_mult = 1.0` → formula identical to before.
- `current_room` null guard returns `1.0` (safe fallback, no essence change).
