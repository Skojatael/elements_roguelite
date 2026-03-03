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
var _living_count: int = 0
var _spawned: bool = false

var essence_mult: float:
	get: return _config.essence_mult if _config != null else 1.0


func _ready() -> void:
	_config = _load_config()
	_entry_area.body_entered.connect(_on_player_entered)
	if auto_register:
		RunManager.register_room(self)
	print("[RoomSpawner] ready — room_id='{id}' room_type_id='{type}' spawn_points={count}".format({
		"id": room_id,
		"type": room_type_id,
		"count": _config.spawn_points.size(),
	}))


func _load_config() -> RoomSpawnConfig:
	var raw: Dictionary = ResourceManager.get_dungeon_config()
	var configs: Dictionary = raw.get("spawn_configs", {})
	if not configs.has(room_type_id):
		print("[RoomSpawner] no config found for room_type_id='{type}' — empty room".format({"type": room_type_id}))
		return RoomSpawnConfig.new()  # empty config — no spawns, no error (FR-002)

	var cfg := RoomSpawnConfig.from_dict(room_type_id, configs[room_type_id])

	# FR-009: maximum 10 enemies per room.
	if cfg.spawn_points.size() > MAX_ENEMIES:
		push_error("RoomSpawner: spawn_points count exceeds maximum of {max} in room_type='{type}'".format({
			"max": MAX_ENEMIES,
			"type": room_type_id,
		}))
		return RoomSpawnConfig.new()

	# FR-003: all enemy_id values must exist in enemies.json.
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
	print("[RoomSpawner] player entered room_id='{id}' room_type='{type}'".format({"id": room_id, "type": room_type_id}))
	room_entered.emit(room_id)
	_spawn_enemies.call_deferred()


func _spawn_enemies() -> void:
	_spawned = true
	var base_count: int = _config.spawn_points.size()
	_living_count = mini(floori(float(base_count) * _config.enemy_count_mult), MAX_ENEMIES)
	if _living_count == 0:
		print("[RoomSpawner] no spawn points configured for room_type='{type}'".format({"type": room_type_id}))
		return
	print("[RoomSpawner] spawning {count} enemies in room_type='{type}' (base={base} mult={mult})".format({
		"count": _living_count, "type": room_type_id, "base": base_count, "mult": _config.enemy_count_mult,
	}))
	for i: int in _living_count:
		var sp: SpawnPointData = _config.spawn_points[i % base_count]
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.enemy_type_id = sp.enemy_id  # must be set before add_child
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
	print("[RoomSpawner] enemy defeated — remaining: {count}".format({"count": _living_count}))
	if _living_count == 0:
		RunManager.mark_room_cleared(room_id)
		room_cleared.emit(room_id)
		print("[RoomSpawner] cleared room_id='{id}' room_type='{type}'".format({"id": room_id, "type": room_type_id}))
