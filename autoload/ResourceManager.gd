extends Node

var _impl: ResourceManagerImpl = ResourceManagerImpl.new()


func _ready() -> void:
	pass


func get_dungeon_config() -> Dictionary:
	return _impl.get_dungeon_config()


func enemy_id_exists(id: String) -> bool:
	return _impl.enemy_id_exists(id)


func get_enemy_base_essence(id: String) -> float:
	return _impl.get_enemy_base_essence(id)


func get_meta_config() -> Dictionary:
	return _impl.get_meta_config()


func get_relics() -> Dictionary:
	return _impl.get_relics()


func get_enemy_rooms_required(id: String) -> int:
	return _impl.get_enemy_rooms_required(id)
