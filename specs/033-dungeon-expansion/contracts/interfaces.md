# Interfaces: Dungeon Expansion (033)

---

## 1. MetaState.gd — new fields

```gdscript
class_name MetaState
extends RefCounted

var total_shards: int = 0
var damage_upgrade_level: int = 0
var adventurer_bag_unlocked: bool = false
var relic_offers_active: bool = false
var first_boss_killed: bool = false      # NEW
var adventuring_gear_owned: bool = false # NEW
```

---

## 2. SaveManagerImpl.gd — serialize/deserialize new fields

```gdscript
func save_meta_state(state: MetaState) -> void:
	var data: Dictionary = {
		"total_shards": state.total_shards,
		"damage_upgrade_level": state.damage_upgrade_level,
		"adventurer_bag_unlocked": state.adventurer_bag_unlocked,
		"relic_offers_active": state.relic_offers_active,
		"first_boss_killed": state.first_boss_killed,           # NEW
		"adventuring_gear_owned": state.adventuring_gear_owned, # NEW
	}
	# ... rest unchanged

func load_meta_state() -> MetaState:
	# ... existing fields unchanged ...
	state.first_boss_killed = bool(parsed.get("first_boss_killed", false))          # NEW
	state.adventuring_gear_owned = bool(parsed.get("adventuring_gear_owned", false)) # NEW
	return state
```

---

## 3. MetaManagerImpl.gd — new methods

```gdscript
## Records first boss kill. Returns true if this call changed the state.
func record_boss_kill(save_manager: Node) -> bool:
	if meta_state.first_boss_killed:
		return false
	meta_state.first_boss_killed = true
	save_manager.save_meta_state(meta_state)
	return true


## Purchases Adventuring Gear if affordable. Returns true on success.
func purchase_adventuring_gear(cost: int, save_manager: Node) -> bool:
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.adventuring_gear_owned = true
	save_manager.save_meta_state(meta_state)
	return true
```

---

## 4. MetaManager.gd (autoload) — new properties, method, boss detection

```gdscript
var is_first_boss_killed: bool:
	get: return _impl.meta_state.first_boss_killed

var is_adventuring_gear_owned: bool:
	get: return _impl.meta_state.adventuring_gear_owned


## Purchases Adventuring Gear for the configured shard cost.
## Returns false silently if insufficient shards — no error state.
func purchase_adventuring_gear() -> bool:
	var cost: int = ResourceManager.get_meta_config().get("adventuring_gear_cost", 300)
	var success: bool = _impl.purchase_adventuring_gear(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func _on_room_cleared(room_id: String) -> void:
	if room_id == "boss_room":                                   # NEW
		var recorded: bool = _impl.record_boss_kill(SaveManager) # NEW
		if recorded:                                             # NEW
			print("[MetaManager] first boss kill recorded")      # NEW
		return                                                   # NEW — early return, skip elite check
	# ... existing elite detection unchanged
```

---

## 5. AdventuringGearShop.gd — new scene script

```gdscript
class_name AdventuringGearShop
extends Control

@export var _button: Button


func _ready() -> void:
	_button.pressed.connect(_on_buy_pressed)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_visibility())
	_update_visibility()


func _update_visibility() -> void:
	visible = MetaManager.is_first_boss_killed and not MetaManager.is_adventuring_gear_owned


func _on_buy_pressed() -> void:
	MetaManager.purchase_adventuring_gear()
	_update_visibility()
```

Button text set in Inspector: `"Adventuring Gear — 300 shards"`. Button is never disabled — `purchase_adventuring_gear()` silently does nothing if insufficient shards.

---

## 6. DungeonGenerator.gd — grid expansion + _expand_dungeon()

```gdscript
const GRID_SIZE: int = 13   # was 5
const CENTER: Vector2i = Vector2i(6, 6)   # was Vector2i(2, 2)
# TARGET_ROOM_COUNT const removed — read from dungeon_config.json as "base_room_count"

func _generate() -> void:
	var target_room_count: int = ResourceManager.get_dungeon_config().get("base_room_count", 9)
	# ... existing base generation uses target_room_count instead of TARGET_ROOM_COUNT ...
	_build_neighbours(occupied)
	_promote_elite_rooms()

	if MetaManager.is_adventuring_gear_owned:
		_expand_dungeon(occupied, pool, difficulty_scale)
		_build_neighbours(occupied)   # rebuild after expansion

	print("[DungeonGenerator] ...")
	dungeon_layout_ready.emit()


func _expand_dungeon(occupied: Dictionary, pool: Array, difficulty_scale: float) -> void:
	var expansion_count: int = ResourceManager.get_dungeon_config().get("expansion_room_count", 4)
	# Find max depth room (Room A)
	var max_depth: int = 0
	for room_data: Variant in rooms_by_id.values():
		var d: int = (room_data as Dictionary).get("depth", 0)
		if d > max_depth:
			max_depth = d
	var seed_id: String = ""
	for rid: String in rooms_by_id:
		if rooms_by_id[rid].get("depth", 0) == max_depth:
			seed_id = rid
			break

	var seed_cell: Vector2i = rooms_by_id[seed_id]["grid_pos"]
	var expansion_frontier: Array = []
	for neighbour: Vector2i in _get_expansion_neighbours(seed_cell, occupied, max_depth):
		expansion_frontier.append(neighbour)

	var added: int = 0
	while added < expansion_count and not expansion_frontier.is_empty():
		var idx: int = randi() % expansion_frontier.size()
		var cell: Vector2i = expansion_frontier[idx]
		expansion_frontier.remove_at(idx)
		_record_room(cell, pool.pick_random(), occupied, expansion_frontier, difficulty_scale)
		# Prune frontier: keep only cells with depth > max_depth
		expansion_frontier = expansion_frontier.filter(
			func(c: Vector2i) -> bool:
				var d: int = abs(c.x - CENTER.x) + abs(c.y - CENTER.y)
				return d > max_depth
		)
		added += 1

	if added < expansion_count:
		push_warning("DungeonGenerator: expansion placed {a}/{e} rooms".format({"a": added, "e": expansion_count}))
	print("[DungeonGenerator] expansion seed={s} max_depth={d} rooms_added={a}".format({
		"s": seed_id, "d": max_depth, "a": added,
	}))


func _get_expansion_neighbours(cell: Vector2i, occupied: Dictionary, min_depth: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for offset: Vector2i in offsets:
		var neighbour: Vector2i = cell + offset
		if neighbour.x < 0 or neighbour.x >= GRID_SIZE or neighbour.y < 0 or neighbour.y >= GRID_SIZE:
			continue
		if occupied.has(neighbour):
			continue
		var depth: int = abs(neighbour.x - CENTER.x) + abs(neighbour.y - CENTER.y)
		if depth > min_depth:
			result.append(neighbour)
	return result
```

**Note on `_record_room` reuse**: The existing `_record_room` calls `_get_valid_neighbours` which adds ALL unoccupied in-bounds neighbors to the frontier. For expansion, we immediately prune the frontier after each room is added (keeping only cells at depth > max_depth). This ensures the expansion never branches back toward the center.

---

## Signal Flow

```
Boss dies
  → RoomSpawner.room_cleared("boss_room")
  → MetaManager._on_room_cleared("boss_room")
      → MetaManagerImpl.record_boss_kill()  [sets first_boss_killed, saves]

Hub entered (after boss kill)
  → AdventuringGearShop._update_visibility() via shards_changed OR _ready()
      → visible = true  [300 shards button appears]

Player taps button (≥300 shards)
  → MetaManager.purchase_adventuring_gear()
      → MetaManagerImpl.purchase_adventuring_gear()  [deducts, sets owned, saves]
      → shards_changed.emit()
  → AdventuringGearShop._update_visibility()
      → visible = false  [button disappears permanently]

Run started (gear owned)
  → DungeonGenerator._generate()
      → base 9 rooms placed (1 start + 8 combat)
      → MetaManager.is_adventuring_gear_owned == true
      → _expand_dungeon(): 4 rooms added from Room A
      → _build_neighbours() rebuilt
```
