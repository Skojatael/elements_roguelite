class_name RoomSpawner
extends Node

const ENEMY_SCENE := preload("res://scenes/combat/enemies/Enemy.tscn")
const MAX_ENEMIES := 10

## Must match a key in dungeon_config.json → spawn_configs. Set in the Inspector.
@export var room_id: String = ""

## Emitted once, the same frame the last living enemy is defeated.
signal room_cleared

@onready var _entry_area: Area2D = $"../EntryArea"

var _config: RoomSpawnConfig
var _living_count: int = 0
var _spawned: bool = false


func _ready() -> void:
	_config = _load_config()
	_entry_area.body_entered.connect(_on_player_entered)
	print("[RoomSpawner] ready — room_id='%s' spawn_points=%d" % [room_id, _config.spawn_points.size()])


func _load_config() -> RoomSpawnConfig:
	var raw: Dictionary = ResourceManager.get_dungeon_config()
	var configs: Dictionary = raw.get("spawn_configs", {})
	if not configs.has(room_id):
		print("[RoomSpawner] no config found for room_id='%s' — empty room" % room_id)
		return RoomSpawnConfig.new()  # empty config — no spawns, no error (FR-002)

	var cfg := RoomSpawnConfig.from_dict(room_id, configs[room_id])

	# FR-009: maximum 10 enemies per room.
	if cfg.spawn_points.size() > MAX_ENEMIES:
		push_error("RoomSpawner: spawn_points count exceeds maximum of %d in room '%s'"
			% [MAX_ENEMIES, room_id])
		return RoomSpawnConfig.new()

	# FR-003: all enemy_id values must exist in enemies.json.
	print("[RoomSpawner] validating %d spawn points" % cfg.spawn_points.size())
	for sp: SpawnPointData in cfg.spawn_points:
		var exists := ResourceManager.enemy_id_exists(sp.enemy_id)
		print("[RoomSpawner] enemy_id='%s' exists=%s" % [sp.enemy_id, exists])
		if not exists:
			var msg := "RoomSpawner: unknown enemy_id '%s' in room '%s'" % [sp.enemy_id, room_id]
			push_error(msg)
			print("[RoomSpawner] ERROR: ", msg)
			return RoomSpawnConfig.new()

	return cfg


func _on_player_entered(body: Node2D) -> void:
	print("[RoomSpawner] body_entered — body='%s' groups=%s" % [body.name, body.get_groups()])
	if not body.is_in_group("player"):
		print("[RoomSpawner] ignored — not in player group")
		return
	if RunManager.is_room_cleared(room_id):
		print("[RoomSpawner] ignored — room already cleared")
		return
	if _spawned:
		print("[RoomSpawner] ignored — already spawned")
		return
	print("[RoomSpawner] player entered room '%s'" % room_id)
	_spawn_enemies()


func _spawn_enemies() -> void:
	_spawned = true
	_living_count = _config.spawn_points.size()
	if _living_count == 0:
		print("[RoomSpawner] no spawn points configured for '%s'" % room_id)
		return
	print("[RoomSpawner] spawning %d enemies in '%s'" % [_living_count, room_id])
	for sp: SpawnPointData in _config.spawn_points:
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.enemy_type_id = sp.enemy_id  # must be set before add_child
		get_parent().add_child(enemy)
		var offset := Vector2(
			randf_range(-sp.radius, sp.radius),
			randf_range(-sp.radius, sp.radius)
		)
		enemy.global_position = get_parent().global_position + sp.position + offset
		enemy.defeated.connect(_on_enemy_defeated)
		print("[RoomSpawner] spawned '%s' at %v" % [sp.enemy_id, enemy.global_position])


func _on_enemy_defeated() -> void:
	_living_count -= 1
	print("[RoomSpawner] enemy defeated — remaining: %d" % _living_count)
	if _living_count == 0:
		RunManager.mark_room_cleared(room_id)
		room_cleared.emit()
		print("[RoomSpawner] room '%s' cleared" % room_id)
