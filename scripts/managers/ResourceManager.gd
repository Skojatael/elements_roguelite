class_name ResourceManagerImpl
extends RefCounted

var _dungeon_config_cache: Dictionary = {}
var _enemy_ids_cache: Array[String] = []
var _enemy_essence_cache: Dictionary = {}
var _enemy_rooms_required_cache: Dictionary = {}
var _enemy_data_cache: Dictionary = {}
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


## Returns the full data dictionary for the given enemy id, with the "id" field
## injected. Returns an empty dictionary for unknown ids.
func get_enemy_data(id: String) -> Dictionary:
	if not _enemy_ids_loaded:
		_load_enemy_data()
	return _enemy_data_cache.get(id, {})


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


## Returns the combat room pool array for the given domain from dungeon_config.json.
## Returns an empty array with a warning if the domain is unknown.
func get_combat_room_pool(domain: String) -> Array:
	var config: Dictionary = get_dungeon_config()
	var pools: Variant = config.get("combat_room_pools", {})
	if not pools is Dictionary:
		push_warning("ResourceManager: combat_room_pools missing or wrong type in dungeon_config.json")
		return []
	var pool: Variant = (pools as Dictionary).get(domain, null)
	if pool == null:
		push_warning("ResourceManager: unknown domain '{d}' — no combat room pool found".format({"d": domain}))
		return []
	return pool as Array


func _load_enemy_data() -> void:
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	assert(file != null, "ResourceManager: failed to open res://data/enemies.json")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary, "ResourceManager: enemies.json root must be a Dictionary")
	_load_enemy_data_from_dict(parsed as Dictionary)


## Parses the three-level (tier → domain → id) enemy structure into flat caches.
## Called by _load_enemy_data() after file I/O; exposed separately for unit testing.
func _load_enemy_data_from_dict(root: Dictionary) -> void:
	for tier_value: Variant in root.values():
		if not tier_value is Dictionary:
			continue
		for domain_value: Variant in (tier_value as Dictionary).values():
			if not domain_value is Dictionary:
				continue
			for enemy_id: Variant in (domain_value as Dictionary):
				var entry: Variant = (domain_value as Dictionary)[enemy_id]
				if not entry is Dictionary:
					continue
				var id: String = enemy_id as String
				var full: Dictionary = (entry as Dictionary).duplicate()
				full["id"] = id
				_enemy_ids_cache.append(id)
				_enemy_essence_cache[id] = float(full.get("base_essence", 0.0))
				_enemy_rooms_required_cache[id] = int(full.get("rooms_required", 0))
				_enemy_data_cache[id] = full
	_enemy_ids_loaded = true
