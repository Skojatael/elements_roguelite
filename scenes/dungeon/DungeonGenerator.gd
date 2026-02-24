class_name DungeonGenerator
extends Node

const GRID_SIZE: int = 5
const TARGET_ROOM_COUNT: int = 8
const SPACING_X: int = 2000   # 1920 room width + 80 gap
const SPACING_Y: int = 1200   # 1080 room height + 120 gap
const CENTER: Vector2i = Vector2i(2, 2)

## Maps room_id → { "room_type_id": String, "grid_pos": Vector2i, "world_pos": Vector2 }
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

	_record_room(CENTER, pool.pick_random(), occupied, frontier)
	start_room_id = "room_{x}_{y}".format({"x": CENTER.x, "y": CENTER.y})

	while occupied.size() < TARGET_ROOM_COUNT and not frontier.is_empty():
		var idx: int = randi() % frontier.size()
		var cell: Vector2i = frontier[idx]
		frontier.remove_at(idx)
		_record_room(cell, pool.pick_random(), occupied, frontier)

	if occupied.size() < TARGET_ROOM_COUNT:
		push_warning("DungeonGenerator: frontier exhausted at {count}/{target} rooms".format({"count": occupied.size(), "target": TARGET_ROOM_COUNT}))

	_build_neighbours(occupied)

	print("[DungeonGenerator] layout rooms={count} start={start} cells={keys}".format({"count": rooms_by_id.size(), "start": start_room_id, "keys": rooms_by_id.keys()}))

	_place_player(rooms_by_id[start_room_id]["world_pos"])


func _record_room(cell: Vector2i, type_id: String, occupied: Dictionary, frontier: Array) -> void:
	var room_id: String = "room_{x}_{y}".format({"x": cell.x, "y": cell.y})
	rooms_by_id[room_id] = {
		"room_type_id": type_id,
		"grid_pos": cell,
		"world_pos": _get_world_pos(cell)
	}
	occupied[cell] = room_id
	for neighbour: Vector2i in _get_valid_neighbours(cell, occupied):
		if not frontier.has(neighbour):
			frontier.append(neighbour)


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


func _place_player(target_pos: Vector2) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("DungeonGenerator: player not found in group 'player'")
		return
	player.global_position = target_pos
	print("[DungeonGenerator] player placed at {pos}".format({"pos": target_pos}))
