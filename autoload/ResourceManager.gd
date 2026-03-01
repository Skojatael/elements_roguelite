extends Node

var _dungeon_config_cache: Dictionary = {}
var _enemy_ids_cache: Array[String] = []
var _enemy_essence_cache: Dictionary = {}
var _dungeon_config_loaded: bool = false
var _enemy_ids_loaded: bool = false


func _ready() -> void:
	pass


## Returns the parsed contents of data/dungeon_config.json, cached after first load.
func get_dungeon_config() -> Dictionary:
	if _dungeon_config_loaded:
		return _dungeon_config_cache

	var file := FileAccess.open("res://data/dungeon_config.json", FileAccess.READ)
	assert(file != null, "ResourceManager: failed to open res://data/dungeon_config.json")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary,
		"ResourceManager: dungeon_config.json root must be a Dictionary")

	_dungeon_config_cache = parsed as Dictionary
	_dungeon_config_loaded = true
	return _dungeon_config_cache


## Returns true if the given id exists in data/enemies.json.
func enemy_id_exists(id: String) -> bool:
	if not _enemy_ids_loaded:
		_load_enemy_data()
	return _enemy_ids_cache.has(id)


## Returns the base_essence value for the given enemy type id.
## Returns 0.0 for unknown ids or missing base_essence field.
func get_enemy_base_essence(id: String) -> float:
	if not _enemy_ids_loaded:
		_load_enemy_data()
	return _enemy_essence_cache.get(id, 0.0)


func _load_enemy_data() -> void:
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	assert(file != null, "ResourceManager: failed to open res://data/enemies.json")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary, "ResourceManager: enemies.json root must be a Dictionary")

	for entry: Variant in (parsed as Dictionary).get("enemies", []):
		if entry is Dictionary and entry.has("id"):
			_enemy_ids_cache.append(entry["id"])
			_enemy_essence_cache[entry["id"]] = float(entry.get("base_essence", 0.0))
	_enemy_ids_loaded = true
