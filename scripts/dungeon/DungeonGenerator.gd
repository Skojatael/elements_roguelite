class_name DungeonGenerator
extends Node

signal dungeon_layout_ready

const GRID_SIZE: int = 13
const SPACING_X: int = 2000   # 1920 room width + 80 gap
const SPACING_Y: int = 1200   # 1080 room height + 120 gap
const CENTER: Vector2i = Vector2i(6, 6)
const ELITE_START: int = 2
const ELITE_STEP: int = 2

## Maps room_id → { "room_type_id": String, "grid_pos": Vector2i, "world_pos": Vector2, "depth": int, "difficulty_mult": float }
var rooms_by_id: Dictionary = {}

## Maps room_id → Array of adjacent room_ids present in this layout
var neighbours_by_id: Dictionary = {}

## Always "room_6_6" after a successful generation
var start_room_id: String = ""


func _ready() -> void:
	RunManager.run_started.connect(_on_run_started)


func _on_run_started(_mode: String) -> void:
	_generate()


func _generate() -> void:
	_generate_with(ResourceManager.get_dungeon_config(), MetaManager.is_adventuring_gear_owned, MetaManager.is_depth_scaling_unlocked, RunManager.run_domain)


func _generate_with(config: Dictionary, gear_owned: bool, depth_scaling: bool = false, domain: String = "forest") -> void:
	rooms_by_id.clear()
	neighbours_by_id.clear()
	start_room_id = ""

	var pools: Variant = config.get("combat_room_pools", {})
	var pool: Array = []
	if pools is Dictionary:
		pool = (pools as Dictionary).get(domain, [])
	if pool.is_empty():
		push_error("DungeonGenerator: no combat room pool for domain '{d}' in dungeon_config.json".format({"d": domain}))
		return
	var difficulty_scale: float = config.get("difficulty_scale", 0.12)
	var target_room_count: int = config.get("base_room_count", 9)

	var occupied: Dictionary = {}
	var frontier: Array = []

	_record_room(CENTER, "StartRoom01", occupied, frontier, difficulty_scale, depth_scaling)
	start_room_id = "room_{x}_{y}".format({"x": CENTER.x, "y": CENTER.y})

	while occupied.size() < target_room_count and not frontier.is_empty():
		var idx: int = randi() % frontier.size()
		var cell: Vector2i = frontier[idx]
		frontier.remove_at(idx)
		_record_room(cell, pool.pick_random(), occupied, frontier, difficulty_scale, depth_scaling)

	if occupied.size() < target_room_count:
		push_warning("DungeonGenerator: frontier exhausted at {count}/{target} rooms".format({"count": occupied.size(), "target": target_room_count}))

	_build_neighbours(occupied)

	if gear_owned:
		_expand_dungeon(occupied, pool, difficulty_scale, depth_scaling)
		_build_neighbours(occupied)

	_promote_elite_rooms()

	print("[DungeonGenerator] layout rooms={count} start={start}".format({"count": rooms_by_id.size(), "start": start_room_id}))

	dungeon_layout_ready.emit()


func _record_room(cell: Vector2i, type_id: String, occupied: Dictionary, frontier: Array, difficulty_scale: float, depth_scaling: bool = false) -> void:
	var room_id: String = "room_{x}_{y}".format({"x": cell.x, "y": cell.y})
	var depth: int = abs(cell.x - CENTER.x) + abs(cell.y - CENTER.y)
	var difficulty_mult: float = 1.0 + difficulty_scale * float(depth) if depth_scaling else 1.0
	rooms_by_id[room_id] = {
		"room_type_id": type_id,
		"grid_pos": cell,
		"world_pos": _get_world_pos(cell),
		"depth": depth,
		"difficulty_mult": difficulty_mult,
	}
	occupied[cell] = room_id
	for neighbour: Vector2i in _get_valid_neighbours(cell, occupied):
		if not frontier.has(neighbour):
			frontier.append(neighbour)


func _promote_elite_rooms() -> void:
	var d: int = ELITE_START
	while d <= GRID_SIZE * 2:
		var candidates: Array[String] = []
		for room_id: String in rooms_by_id:
			if rooms_by_id[room_id]["depth"] == d:
				candidates.append(room_id)
		if not candidates.is_empty():
			var chosen: String = candidates.pick_random()
			rooms_by_id[chosen]["room_type_id"] = "ForestEliteRoom01"
			print("[DungeonGenerator] elite promoted room_id={id} at depth={d}".format({"id": chosen, "d": d}))
		d += ELITE_STEP


func _build_neighbours(occupied: Dictionary) -> void:
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for cell: Vector2i in occupied.keys():
		var room_id: String = occupied[cell]
		neighbours_by_id[room_id] = []
		for offset: Vector2i in offsets:
			var neighbour: Vector2i = cell + offset
			if occupied.has(neighbour):
				neighbours_by_id[room_id].append(occupied[neighbour])


func _get_world_pos(cell: Vector2i) -> Vector2:
	return Vector2((cell.x - CENTER.x) * SPACING_X, (cell.y - CENTER.y) * SPACING_Y)


func _get_valid_neighbours(cell: Vector2i, occupied: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for offset: Vector2i in offsets:
		var neighbour: Vector2i = cell + offset
		if neighbour.x >= 0 and neighbour.x < GRID_SIZE and neighbour.y >= 0 and neighbour.y < GRID_SIZE and not occupied.has(neighbour):
			result.append(neighbour)
	return result


func _expand_dungeon(occupied: Dictionary, pool: Array, difficulty_scale: float, depth_scaling: bool = false) -> void:
	var expansion_count: int = ResourceManager.get_dungeon_config().get("expansion_room_count", 4)
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
		_record_room(cell, pool.pick_random(), occupied, expansion_frontier, difficulty_scale, depth_scaling)
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
