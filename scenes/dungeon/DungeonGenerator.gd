class_name DungeonGenerator
extends Node

const ROOM_SPACING: int = 1200


func _ready() -> void:
	RunManager.run_started.connect(_on_run_started)


func _on_run_started(_mode: String) -> void:
	_generate()


func _generate() -> void:
	var raw: Dictionary = ResourceManager.get_dungeon_config()
	var sequence: Array = raw.get("room_sequence", [])
	if sequence.is_empty():
		push_error("DungeonGenerator: room_sequence missing or empty in dungeon_config.json")
		return

	var origin: Vector2 = Vector2.ZERO
	var first_room_pos: Vector2 = Vector2.ZERO
	var spawned_count: int = 0

	for i: int in range(sequence.size()):
		var type_id: String = sequence[i]
		var room_data: RoomData = load("res://data/rooms/{id}.tres".format({"id": type_id}))
		if room_data == null:
			push_error("DungeonGenerator: RoomData not found for type='{type}'".format({"type": type_id}))
			break
		var pos: Vector2 = origin + Vector2(i * ROOM_SPACING, 0)
		var context: SpawnContext = SpawnContext.create(get_parent(), pos)
		var room_id: String = "room_{i}".format({"i": i})
		var spawner: RoomSpawner = RunManager.spawn_room(room_data, room_id, context)
		if spawner == null:
			push_error("DungeonGenerator: spawn_room returned null — room_id='{id}' type='{type}'".format({"id": room_id, "type": type_id}))
			break
		if spawned_count == 0:
			first_room_pos = pos
		spawned_count += 1
		print("[DungeonGenerator] spawned room_id='{id}' room_type='{type}' at {pos}".format({"id": room_id, "type": type_id, "pos": pos}))

	if spawned_count > 0:
		_place_player(first_room_pos)


func _place_player(target_pos: Vector2) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("DungeonGenerator: player not found in group 'player'")
		return
	player.global_position = target_pos
	print("[DungeonGenerator] player placed at {pos}".format({"pos": target_pos}))
