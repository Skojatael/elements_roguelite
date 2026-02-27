class_name RoomLoader
extends Node

const ENTRY_OFFSET: float = 150.0
const OPPOSITE: Dictionary = {"N": "S", "S": "N", "E": "W", "W": "E"}

var _loading: bool = false
var _current_room_node: Node = null
var _dungeon_gen: DungeonGenerator = null


func _ready() -> void:
	_dungeon_gen = get_parent().get_node("DungeonGenerator")
	_dungeon_gen.dungeon_layout_ready.connect(_on_layout_ready)


func _on_layout_ready() -> void:
	_load_room(_dungeon_gen.start_room_id, "")


func _load_room(room_id: String, entry_direction: String) -> void:
	if _loading:
		return
	_loading = true
	if _current_room_node != null:
		RunManager.current_room = null
		_current_room_node.queue_free()
		_current_room_node = null
	var room_data: Dictionary = _dungeon_gen.rooms_by_id.get(room_id, {})
	if room_data.is_empty():
		push_error("RoomLoader: room_id={id} not found in rooms_by_id".format({"id": room_id}))
		_loading = false
		return
	var type_id: String = room_data["room_type_id"]
	var res_path: String = "res://data/rooms/{type}.tres".format({"type": type_id})
	var room_resource: RoomData = load(res_path)
	if room_resource == null:
		push_error("RoomLoader: RoomData not found at {path}".format({"path": res_path}))
		_loading = false
		return
	var context: SpawnContext = SpawnContext.create(get_parent(), room_data["world_pos"])
	var spawner: RoomSpawner = RunManager.spawn_room(room_resource, room_id, context)
	if spawner == null:
		_loading = false
		return
	var room_mult: float = _dungeon_gen.rooms_by_id[room_id].get("difficulty_mult", 1.0)
	spawner.difficulty_mult = room_mult
	_current_room_node = spawner.get_parent()
	_configure_doors(_current_room_node, room_id)
	_place_player(entry_direction, room_data["world_pos"])
	_loading = false


func _configure_doors(room_node: Node, room_id: String) -> void:
	var neighbours: Array = _dungeon_gen.neighbours_by_id.get(room_id, [])
	if neighbours.is_empty():
		push_warning("RoomLoader: no neighbours found for room_id={id}".format({"id": room_id}))
	var delta_to_dir: Dictionary = {
		Vector2i(1, 0): "E",
		Vector2i(-1, 0): "W",
		Vector2i(0, 1): "S",
		Vector2i(0, -1): "N"
	}
	var dir_to_neighbour: Dictionary = {}
	var current_grid: Vector2i = _dungeon_gen.rooms_by_id[room_id]["grid_pos"]
	for neighbour_id: String in neighbours:
		var neighbour_grid: Vector2i = _dungeon_gen.rooms_by_id[neighbour_id]["grid_pos"]
		var delta: Vector2i = neighbour_grid - current_grid
		if delta_to_dir.has(delta):
			dir_to_neighbour[delta_to_dir[delta]] = neighbour_id
	for direction: String in ["N", "S", "E", "W"]:
		var door: Door = room_node.get_node_or_null("Door{dir}".format({"dir": direction}))
		if door == null:
			continue
		if dir_to_neighbour.has(direction):
			door.visible = true
			door.monitoring = true
			door.target_room_id = dir_to_neighbour[direction]
			door.direction = direction
			if not door.door_activated.is_connected(_on_door_activated):
				door.door_activated.connect(_on_door_activated)
		else:
			door.visible = false
			door.monitoring = false


func _place_player(entry_direction: String, world_pos: Vector2) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("RoomLoader: player not found in group 'player'")
		return
	if entry_direction.is_empty():
		player.global_position = world_pos
		return
	var local_offset: Vector2
	match entry_direction:
		"N":
			local_offset = Vector2(0.0, -540.0 + ENTRY_OFFSET)
		"S":
			local_offset = Vector2(0.0, 540.0 - ENTRY_OFFSET)
		"E":
			local_offset = Vector2(960.0 - ENTRY_OFFSET, 0.0)
		"W":
			local_offset = Vector2(-960.0 + ENTRY_OFFSET, 0.0)
		_:
			push_error("RoomLoader: unknown entry_direction={dir}".format({"dir": entry_direction}))
			player.global_position = world_pos
			return
	player.global_position = world_pos + local_offset
	print("[RoomLoader] player placed at {pos} via {dir} entry".format({"pos": player.global_position, "dir": entry_direction}))


func _on_door_activated(direction: String, target_room_id: String) -> void:
	var entry_direction: String = OPPOSITE[direction]
	_load_room.call_deferred(target_room_id, entry_direction)
