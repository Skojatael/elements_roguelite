class_name DungeonGenerator
extends Node

signal dungeon_layout_ready

const GRID_SIZE: int = 5
const TARGET_ROOM_COUNT: int = 8
const SPACING_X: int = 2000   # 1920 room width + 80 gap
const SPACING_Y: int = 1200   # 1080 room height + 120 gap
const CENTER: Vector2i = Vector2i(2, 2)
const ELITE_START: int = 2
const ELITE_STEP: int = 2

## Maps room_id → { "room_type_id": String, "grid_pos": Vector2i, "world_pos": Vector2, "depth": int, "difficulty_mult": float }
var rooms_by_id: Dictionary = {}

## Maps room_id → Array of adjacent room_ids present in this layout
var neighbours_by_id: Dictionary = {}

## Always "room_2_2" after a successful generation
var start_room_id: String = ""


func _ready() -> void:
	RunManager.run_started.connect(_on_run_started)


func _on_run_started(_mode: String) -> void:
	_generate()


func _generate() -> void:
	rooms_by_id.clear()
	neighbours_by_id.clear()
	start_room_id = ""

	var raw: Dictionary = ResourceManager.get_dungeon_config()
	var pool: Array = raw.get("combat_room_pool", [])
	if pool.is_empty():
		push_error("DungeonGenerator: combat_room_pool missing or empty in dungeon_config.json")
		return

	if TARGET_ROOM_COUNT > GRID_SIZE * GRID_SIZE:
		push_error("DungeonGenerator: TARGET_ROOM_COUNT={count} exceeds grid capacity={cap}".format({"count": TARGET_ROOM_COUNT, "cap": GRID_SIZE * GRID_SIZE}))

	var occupied: Dictionary = {}
	var frontier: Array = []

	_record_room(CENTER, "StartRoom01", occupied, frontier)
	start_room_id = "room_{x}_{y}".format({"x": CENTER.x, "y": CENTER.y})

	while occupied.size() < TARGET_ROOM_COUNT and not frontier.is_empty():
		var idx: int = randi() % frontier.size()
		var cell: Vector2i = frontier[idx]
		frontier.remove_at(idx)
		_record_room(cell, pool.pick_random(), occupied, frontier)

	if occupied.size() < TARGET_ROOM_COUNT:
		push_warning("DungeonGenerator: frontier exhausted at {count}/{target} rooms".format({"count": occupied.size(), "target": TARGET_ROOM_COUNT}))

	_build_neighbours(occupied)
	_promote_elite_rooms()

	print("[DungeonGenerator] layout rooms={count} start={start} cells={keys}".format({"count": rooms_by_id.size(), "start": start_room_id, "keys": rooms_by_id.keys()}))

	dungeon_layout_ready.emit()


func _record_room(cell: Vector2i, type_id: String, occupied: Dictionary, frontier: Array) -> void:
	var room_id: String = "room_{x}_{y}".format({"x": cell.x, "y": cell.y})
	var depth: int = abs(cell.x - CENTER.x) + abs(cell.y - CENTER.y)
	var difficulty_mult: float = 1.0 + 0.12 * float(depth)
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
			rooms_by_id[chosen]["room_type_id"] = "EliteRoom01"
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
