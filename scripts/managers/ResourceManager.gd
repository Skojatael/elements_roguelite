class_name ResourceManagerImpl
extends RefCounted

var _dungeon_config_cache: Dictionary = {}
var _enemy_ids_cache: Array[String] = []
var _enemy_essence_cache: Dictionary = {}
var _enemy_rooms_required_cache: Dictionary = {}
var _meta_config_cache: Dictionary = {}
var _relics_cache: Dictionary = {}
var _skills_cache: Array = []
var _player_config_cache: Dictionary = {}
var _dungeon_config_loaded: bool = false
var _enemy_ids_loaded: bool = false
var _meta_config_loaded: bool = false
var _relics_loaded: bool = false
var _skills_loaded: bool = false
var _player_config_loaded: bool = false


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


## Returns the parsed contents of data/meta_config.json, cached after first load.
func get_meta_config() -> Dictionary:
	if _meta_config_loaded:
		return _meta_config_cache

	var file := FileAccess.open("res://data/meta_config.json", FileAccess.READ)
	assert(file != null, "ResourceManager: failed to open res://data/meta_config.json")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary,
		"ResourceManager: meta_config.json root must be a Dictionary")

	_meta_config_cache = parsed as Dictionary
	_meta_config_loaded = true
	return _meta_config_cache


## Returns the parsed contents of data/relics.json, cached after first load.
func get_relics() -> Dictionary:
	if _relics_loaded:
		return _relics_cache

	var file := FileAccess.open("res://data/relics.json", FileAccess.READ)
	assert(file != null, "ResourceManager: failed to open res://data/relics.json")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary,
		"ResourceManager: relics.json root must be a Dictionary")

	_relics_cache = parsed as Dictionary
	_relics_loaded = true
	return _relics_cache


## Returns the rooms_required value for the given enemy id. Returns 0 for non-boss enemies
## or unknown ids.
func get_enemy_rooms_required(id: String) -> int:
	if not _enemy_ids_loaded:
		_load_enemy_data()
	return _enemy_rooms_required_cache.get(id, 0)


## Returns the parsed contents of data/player.json, cached after first load.
func get_player_config() -> Dictionary:
	if _player_config_loaded:
		return _player_config_cache

	var file := FileAccess.open("res://data/player.json", FileAccess.READ)
	assert(file != null, "ResourceManager: failed to open res://data/player.json")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary,
		"ResourceManager: player.json root must be a Dictionary")

	_player_config_cache = parsed as Dictionary
	_player_config_loaded = true
	return _player_config_cache


## Returns the parsed skills array from data/skills.json, cached after first load.
func get_skills() -> Array:
	if _skills_loaded:
		return _skills_cache

	var file := FileAccess.open("res://data/skills.json", FileAccess.READ)
	assert(file != null, "ResourceManager: failed to open res://data/skills.json")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary,
		"ResourceManager: skills.json root must be a Dictionary")

	var root: Dictionary = parsed as Dictionary
	var skills: Variant = root.get("skills", [])
	assert(skills is Array, "ResourceManager: skills.json 'skills' field must be an Array")
	_skills_cache = skills as Array
	_skills_loaded = true
	return _skills_cache


func _load_enemy_data() -> void:
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	assert(file != null, "ResourceManager: failed to open res://data/enemies.json")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary, "ResourceManager: enemies.json root must be a Dictionary")

	var enemies_root: Variant = (parsed as Dictionary).get("enemies", {})
	assert(enemies_root is Dictionary,
		"ResourceManager: enemies.json 'enemies' field must be a Dictionary — got wrong type (old flat-array format?)")
	for category: Variant in (enemies_root as Dictionary).values():
		if not category is Array:
			continue
		for entry: Variant in category:
			if not (entry is Dictionary and entry.has("id")):
				continue
			_enemy_ids_cache.append(entry["id"])
			_enemy_essence_cache[entry["id"]] = float(entry.get("base_essence", 0.0))
			_enemy_rooms_required_cache[entry["id"]] = int(entry.get("rooms_required", 0))
	_enemy_ids_loaded = true
