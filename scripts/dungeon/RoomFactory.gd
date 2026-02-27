class_name RoomFactory
extends RefCounted


func spawn_room(room_data: RoomData, room_id: String, context: SpawnContext) -> RoomSpawner:
	if room_data == null:
		push_error("RoomFactory: room_data is null")
		return null
	if room_data.scene == null:
		push_error("RoomFactory: room_data.scene is null for room_type='{type}'".format({
			"type": room_data.room_type_id,
		}))
		return null

	var room_root: Node = room_data.scene.instantiate()
	var spawner: RoomSpawner = room_root.get_node("RoomSpawner")

	if spawner == null:
		push_error("RoomFactory: no RoomSpawner child found in scene for room_type='{type}'".format({
			"type": room_data.room_type_id,
		}))
		room_root.queue_free()
		return null

	spawner.room_id = room_id
	spawner.room_type_id = room_data.room_type_id
	spawner.auto_register = false

	context.parent.add_child(room_root)
	room_root.global_position = context.position

	print("[RoomFactory] spawned room_id='{id}' room_type='{type}' at {pos}".format({
		"id": room_id,
		"type": room_data.room_type_id,
		"pos": context.position,
	}))

	return spawner
