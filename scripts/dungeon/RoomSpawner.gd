class_name RoomSpawner
extends Node

const ENEMY_SCENE := preload("res://scenes/combat/enemies/Enemy.tscn")
const MAX_ENEMIES := 10

## Unique instance identifier. Used for tracking (cleared_rooms, signals). Set by RoomFactory or Inspector.
@export var room_id: String = ""

## Matches a key in dungeon_config.json → spawn_configs. Used for enemy spawn config lookup.
@export var room_type_id: String = ""

## When false, skips RunManager.register_room() in _ready(). Set by RoomFactory for dynamic rooms.
@export var auto_register: bool = true

## Applied to each spawned enemy's maximum health. Set by RoomLoader after spawn_room().
@export var difficulty_mult: float = 1.0

## Grid depth of this room (Manhattan distance from start). Set by RoomLoader after spawn_room().
@export var depth: int = 0

## Emitted once, the same frame the last living enemy is defeated.
signal room_cleared(room_id: String)

## Emitted when the player enters this room (after all guards pass).
signal room_entered(room_id: String)

## Emitted for every enemy defeat. Carries only the enemy type — consumers
## resolve stats and context from their own sources.
signal enemy_defeated(enemy_type_id: String)

@onready var _entry_area: Area2D = $"../EntryArea"

var _config: RoomSpawnConfig
var _depth_tiers: Array = []
var _is_depth_band_room: bool = false
var _raw_dungeon_config: Dictionary = {}
var _living_count: int = 0
var _spawned: bool = false
var _wave_index: int = 0
var _total_killed: int = 0
var _total_enemies: int = 0

var essence_mult: float:
	get: return _config.essence_mult if _config != null else 1.0


func _ready() -> void:
	_config = _load_config()
	_entry_area.body_entered.connect(_on_player_entered)
	if auto_register:
		RunManager.register_room(self)
	print("[RoomSpawner] ready — room_id='{id}' room_type_id='{type}' depth_band={db}".format({
		"id": room_id,
		"type": room_type_id,
		"db": _is_depth_band_room,
	}))


func _load_config() -> RoomSpawnConfig:
	var raw: Dictionary = ResourceManager.get_dungeon_config()
	_raw_dungeon_config = raw

	for entry: Variant in raw.get("depth_tiers", []):
		_depth_tiers.append(DepthTierConfig.from_dict(entry as Dictionary))

	var combat_pool: Array = raw.get("combat_room_pool", [])
	if combat_pool.has(room_type_id):
		# Depth is not set yet — defer band lookup to player entry.
		_is_depth_band_room = true
		return RoomSpawnConfig.new()

	var configs: Dictionary = raw.get("spawn_configs", {})
	if not configs.has(room_type_id):
		print("[RoomSpawner] no config found for room_type_id='{type}' — empty room".format({"type": room_type_id}))
		return RoomSpawnConfig.new()

	var cfg := RoomSpawnConfig.from_dict(room_type_id, configs[room_type_id])

	if cfg.spawn_points.size() > MAX_ENEMIES:
		push_error("RoomSpawner: spawn_points count exceeds maximum of {max} in room_type='{type}'".format({
			"max": MAX_ENEMIES,
			"type": room_type_id,
		}))
		return RoomSpawnConfig.new()

	print("[RoomSpawner] validating {count} spawn points".format({"count": cfg.spawn_points.size()}))
	for sp: SpawnPointData in cfg.spawn_points:
		var exists := ResourceManager.enemy_id_exists(sp.enemy_id)
		print("[RoomSpawner] enemy_id='{id}' exists={exists}".format({"id": sp.enemy_id, "exists": exists}))
		if not exists:
			var msg := "RoomSpawner: unknown enemy_id '{enemy}' in room_type='{type}'".format({
				"enemy": sp.enemy_id,
				"type": room_type_id,
			})
			push_error(msg)
			print("[RoomSpawner] ERROR: ", msg)
			return RoomSpawnConfig.new()

	return cfg


func _load_depth_band_config(raw: Dictionary) -> RoomSpawnConfig:
	var bands: Array = raw.get("depth_bands", [])
	var matched_band: Dictionary = {}
	for band: Variant in bands:
		var b: Dictionary = band as Dictionary
		var min_d: int = int(b.get("min_depth", 0))
		var max_d: int = int(b.get("max_depth", -1))
		if depth < min_d:
			continue
		if max_d != -1 and depth > max_d:
			continue
		matched_band = b

	if matched_band.is_empty():
		push_warning("[RoomSpawner] no depth band matches depth={d} for room_type='{type}'".format({
			"d": depth, "type": room_type_id,
		}))
		return RoomSpawnConfig.new()

	var cfg := RoomSpawnConfig.new()
	cfg.room_id = room_type_id

	var band_waves: Array = matched_band.get("waves", [])
	for wave_slots: Variant in band_waves:
		var slots: Array[SpawnPointData] = []
		for slot_data: Variant in (wave_slots as Array):
			var sp := SpawnPointData.from_dict(slot_data as Dictionary)
			if _pool_has_unknown_id(sp.enemy_pool):
				push_error("[RoomSpawner] depth band: unknown enemy_id in room_type='{type}' depth={d}".format({
					"type": room_type_id, "d": depth,
				}))
				return RoomSpawnConfig.new()
			slots.append(sp)
		cfg.wave_spawn_points.append(slots)

	print("[RoomSpawner] depth band loaded — depth={d} waves={w} room_type='{type}'".format({
		"d": depth,
		"w": cfg.wave_spawn_points.size(),
		"type": room_type_id,
	}))
	return cfg


func _resolve_wave_config() -> void:
	if room_type_id.contains("Boss") or room_type_id.contains("Elite"):
		return
	var tier := DepthTierConfig.find_for_depth(_depth_tiers, depth) as DepthTierConfig
	if tier == null:
		return

	var waves_array: Array[int] = []
	if not _config.wave_spawn_points.is_empty():
		for wave_slots: Variant in _config.wave_spawn_points:
			waves_array.append((wave_slots as Array).size())
	else:
		if tier.waves.is_empty():
			return
		waves_array.assign(tier.waves)

	_config.wave_config = WaveConfig.from_dict({
		"waves": waves_array,
		"trigger_threshold": tier.trigger_threshold,
		"alive_cap": tier.alive_cap,
		"min_spawn_distance": tier.min_spawn_distance,
	}) as WaveConfig
	print("[RoomSpawner] depth={d} resolved wave counts={w} threshold={t}".format({
		"d": depth, "w": waves_array, "t": tier.trigger_threshold,
	}))


func _on_player_entered(body: Node2D) -> void:
	print("[RoomSpawner] body_entered — body='{name}' groups={groups}".format({
		"name": body.name,
		"groups": body.get_groups(),
	}))
	if not body.is_in_group("player"):
		print("[RoomSpawner] ignored — not in player group")
		return
	if RunManager.is_room_cleared(room_id):
		print("[RoomSpawner] ignored — room already cleared")
		return
	if _spawned:
		print("[RoomSpawner] ignored — already spawned")
		return
	print("[RoomSpawner] player entered room_id='{id}' room_type='{type}' depth={d}".format({"id": room_id, "type": room_type_id, "d": depth}))
	room_entered.emit(room_id)
	_spawned = true
	if _is_depth_band_room:
		_config = _load_depth_band_config(_raw_dungeon_config)
	_resolve_wave_config()
	if _config.wave_config != null:
		_total_enemies = 0
		for n: int in _config.wave_config.waves:
			_total_enemies += n
		_spawn_wave.call_deferred(0)
	else:
		_spawn_enemies_legacy.call_deferred()


func _lock_doors() -> void:
	for child: Node in get_parent().get_children():
		if child is Door:
			(child as Door).locked = true


func _unlock_doors() -> void:
	for child: Node in get_parent().get_children():
		if child is Door:
			(child as Door).locked = false


func _pool_has_unknown_id(pool: Array) -> bool:
	for entry: Variant in pool:
		if not ResourceManager.enemy_id_exists((entry as Dictionary).get("enemy_id", "")):
			return true
	return false


func _spawn_band_wave(wave_idx: int) -> void:
	var slots: Array = _config.wave_spawn_points[wave_idx]
	var room_origin: Vector2 = get_parent().global_position
	for sp: SpawnPointData in slots:
		var resolved_id: String = sp.pick_enemy_id()
		if resolved_id.is_empty():
			push_warning("[RoomSpawner] pick_enemy_id() returned empty — skipping slot")
			continue
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.enemy_type_id = resolved_id
		get_parent().add_child(enemy)
		enemy.apply_difficulty(difficulty_mult)
		var offset := Vector2(randf_range(-sp.radius, sp.radius), randf_range(-sp.radius, sp.radius))
		enemy.global_position = room_origin + sp.position + offset
		enemy.defeated.connect(_on_enemy_defeated.bind(resolved_id))
		_living_count += 1
		print("[RoomSpawner] spawned '{id}' at {pos}".format({"id": resolved_id, "pos": enemy.global_position}))
	_wave_index += 1
	print("[RoomSpawner] band wave {idx} spawned {n} enemies — living={living}".format({
		"idx": wave_idx, "n": slots.size(), "living": _living_count,
	}))


func _spawn_wave(wave_idx: int) -> void:
	if wave_idx == 0:
		_lock_doors()
	if wave_idx >= _config.wave_config.waves.size():
		return

	if not _config.wave_spawn_points.is_empty() and wave_idx < _config.wave_spawn_points.size():
		_spawn_band_wave(wave_idx)
		return

	# Legacy path: sorted flat spawn_points list with cycling
	var wave_size: int = mini(_config.wave_config.waves[wave_idx], _config.wave_config.alive_cap - _living_count)
	if wave_size <= 0:
		return
	if _config.spawn_points.is_empty():
		push_warning("[RoomSpawner] _spawn_wave: no spawn points for room_type='{type}'".format({"type": room_type_id}))
		return

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var room_origin: Vector2 = get_parent().global_position

	var sorted_points: Array[SpawnPointData] = []
	sorted_points.assign(_config.spawn_points)
	if player != null:
		sorted_points.sort_custom(func(a: SpawnPointData, b: SpawnPointData) -> bool:
			var da: float = (room_origin + a.position).distance_to(player.global_position)
			var db: float = (room_origin + b.position).distance_to(player.global_position)
			return da > db)
	else:
		push_warning("[RoomSpawner] _spawn_wave: player not found, skipping distance sort")

	for i: int in wave_size:
		var sp: SpawnPointData = sorted_points[i % sorted_points.size()]
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.enemy_type_id = sp.enemy_id
		get_parent().add_child(enemy)
		enemy.apply_difficulty(difficulty_mult)
		var offset := Vector2(
			randf_range(-sp.radius, sp.radius),
			randf_range(-sp.radius, sp.radius)
		)
		enemy.global_position = room_origin + sp.position + offset
		enemy.defeated.connect(_on_enemy_defeated.bind(sp.enemy_id))
		_living_count += 1
		print("[RoomSpawner] spawned '{id}' at {pos}".format({"id": sp.enemy_id, "pos": enemy.global_position}))

	_wave_index += 1
	print("[RoomSpawner] wave {idx} spawned {n} enemies — living={living}".format({
		"idx": wave_idx, "n": wave_size, "living": _living_count,
	}))


func _spawn_enemies_legacy() -> void:
	var base_count: int = _config.spawn_points.size()
	_living_count = mini(floori(float(base_count) * _config.enemy_count_mult), MAX_ENEMIES)
	if _living_count == 0:
		print("[RoomSpawner] no spawn points configured for room_type='{type}'".format({"type": room_type_id}))
		return
	_lock_doors()
	print("[RoomSpawner] spawning {count} enemies in room_type='{type}' (base={base} mult={mult})".format({
		"count": _living_count, "type": room_type_id, "base": base_count, "mult": _config.enemy_count_mult,
	}))
	for i: int in _living_count:
		var sp: SpawnPointData = _config.spawn_points[i % base_count]
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.enemy_type_id = sp.enemy_id
		get_parent().add_child(enemy)
		enemy.apply_difficulty(difficulty_mult)
		var offset := Vector2(
			randf_range(-sp.radius, sp.radius),
			randf_range(-sp.radius, sp.radius)
		)
		enemy.global_position = get_parent().global_position + sp.position + offset
		enemy.defeated.connect(_on_enemy_defeated.bind(sp.enemy_id))
		print("[RoomSpawner] spawned '{id}' at {pos}".format({"id": sp.enemy_id, "pos": enemy.global_position}))


func _on_enemy_defeated(enemy_type_id: String) -> void:
	enemy_defeated.emit(enemy_type_id)
	_living_count -= 1
	if _config.wave_config != null:
		_total_killed += 1
		print("[RoomSpawner] enemy defeated — killed={killed}/{total} living={living}".format({
			"killed": _total_killed, "total": _total_enemies, "living": _living_count,
		}))
		if _total_killed == _total_enemies:
			_unlock_doors()
			RunManager.mark_room_cleared(room_id)
			room_cleared.emit(room_id)
			print("[RoomSpawner] cleared room_id='{id}' room_type='{type}'".format({"id": room_id, "type": room_type_id}))
			return
		if _wave_index < _config.wave_config.waves.size() and _living_count <= _config.wave_config.trigger_threshold:
			_spawn_wave(_wave_index)
	else:
		print("[RoomSpawner] enemy defeated — remaining: {count}".format({"count": _living_count}))
		if _living_count == 0:
			_unlock_doors()
			RunManager.mark_room_cleared(room_id)
			room_cleared.emit(room_id)
			print("[RoomSpawner] cleared room_id='{id}' room_type='{type}'".format({"id": room_id, "type": room_type_id}))
