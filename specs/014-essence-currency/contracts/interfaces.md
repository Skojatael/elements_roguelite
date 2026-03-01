# Interface Contracts: Essence Currency

**Feature**: 014-essence-currency
**Date**: 2026-02-28

---

## New Method: `ResourceManager.get_enemy_base_essence(id: String) -> float`

**File**: `autoload/ResourceManager.gd`

Returns the `base_essence` value for the given enemy type ID. Lazy-loads and caches
on first call (same pattern as `enemy_id_exists()`). Returns `0.0` for unknown IDs
or missing `base_essence` field — no crash (FR-008).

```gdscript
func get_enemy_base_essence(id: String) -> float:
    if not _enemy_ids_loaded:
        _load_enemy_data()
    return _enemy_essence_cache.get(id, 0.0)
```

The existing `_load_enemy_ids()` is renamed `_load_enemy_data()` and extended to
also populate `_enemy_essence_cache`:
```gdscript
var _enemy_essence_cache: Dictionary = {}

# inside _load_enemy_data(), alongside existing ID append:
_enemy_essence_cache[entry["id"]] = float(entry.get("base_essence", 0.0))
```

**Called by**: `RunManager._on_enemy_defeated()`
**Side effects**: Loads and caches `enemies.json` on first call (same as before).

---

## New Signal: `RoomSpawner.enemy_defeated(enemy_type_id: String)`

**File**: `scripts/dungeon/RoomSpawner.gd`

Emitted once per enemy death. Carries only the enemy type — no stats, no depth,
no currency implications. Consumers resolve what they need from their own context.

```gdscript
signal enemy_defeated(enemy_type_id: String)
```

---

## Modified Method: `RoomSpawner._on_enemy_defeated(enemy_type_id: String)`

**File**: `scripts/dungeon/RoomSpawner.gd`

**Before**: `func _on_enemy_defeated() -> void`
**After**: `func _on_enemy_defeated(enemy_type_id: String) -> void`

Supplied via bind at connection time in `_spawn_enemies()`:
```gdscript
enemy.defeated.connect(_on_enemy_defeated.bind(sp.enemy_id))
```

Emits `enemy_defeated` signal then decrements `_living_count`. No currency calls.

---

## New Session Field: `RunManager.current_room_depth: int`

**File**: `scripts/managers/RunManager.gd`

Caches the depth of the room currently being played. Set in `_on_room_entered()`,
reset to `0` in `start_run()`.

```gdscript
var current_room_depth: int = 0
```

Set when a room is entered:
```gdscript
func _on_room_entered(room_id: String, spawner: Node) -> void:
    ...existing lines...
    current_room_depth = (spawner as RoomSpawner).depth
```

---

## New Method: `RunManager._on_enemy_defeated(enemy_type_id: String)`

**File**: `scripts/managers/RunManager.gd`

Connected to `RoomSpawner.enemy_defeated` in `register_room()`. Owns the essence
formula. Reads its own session state (`current_room_depth`) and delegates the
data lookup to `ResourceManager`.

```gdscript
func _on_enemy_defeated(enemy_type_id: String) -> void:
    var base_essence: float = ResourceManager.get_enemy_base_essence(enemy_type_id)
    var essence: int = floori(base_essence * (1.0 + 0.10 * float(current_room_depth)))
    if essence > 0:
        add_currency(float(essence))
```

---

## Modified Method: `RunManager.register_room(spawner: Node)`

**File**: `scripts/managers/RunManager.gd`

One line added alongside the existing two signal connections:
```gdscript
spawner.enemy_defeated.connect(_on_enemy_defeated)
```

---

## Modified Method: `RunManager.end_run(reason: EndReason)`

**File**: `scripts/managers/RunManager.gd`

Cash-out block inserted after `is_run_active = false`, before `run_ended.emit()`:

```gdscript
var cashed_out: int
if reason == EndReason.DIED:
    cashed_out = floori(run_currency * 0.85)
else:
    cashed_out = floori(run_currency)
print("[Essence] {amount} essence cashed out".format({"amount": cashed_out}))
```

**Contracts**:
- `cashed_out` is always `>= 0`.
- Message is always printed, even when `run_currency == 0.0`.

---

## Unchanged Interfaces

- `Enemy.defeated` signal — signature unchanged (no parameters).
- `Enemy.gd` — no new methods needed; `get_base_essence()` is NOT added.
- `RunManager.add_currency(amount: float)` — called internally, no change.
- `EnemyData.from_dict()` — signature unchanged; body gains one `.get()` call.
