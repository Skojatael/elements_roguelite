class_name RoomSpawner
extends Node

const ENEMY_SCENE := preload("res://scenes/combat/enemies/Enemy.tscn")
const MAX_ENEMIES := 10

## Must match a key in dungeon_config.json → spawn_configs. Set in the Inspector.
@export var room_id: String = ""

## Emitted once, the same frame the last living enemy is defeated.
signal room_cleared

@onready var _entry_area: Area2D = $EntryArea

var _config: RoomSpawnConfig
var _living_count: int = 0
var _spawned: bool = false


func _ready() -> void:
	_config = _load_config()
	_entry_area.body_entered.connect(_on_player_entered)


func _load_config() -> RoomSpawnConfig:
	var raw: Dictionary = ResourceManager.get_dungeon_config()
	var configs: Dictionary = raw.get("spawn_configs", {})
	if not configs.has(room_id):
		return RoomSpawnConfig.new()  # empty config — no spawns, no error (FR-002)

	var cfg := RoomSpawnConfig.from_dict(room_id, configs[room_id])

	# FR-009: maximum 10 enemies per room.
	if cfg.spawn_points.size() > MAX_ENEMIES:
		push_error("RoomSpawner: spawn_points count exceeds maximum of %d in room '%s'"
			% [MAX_ENEMIES, room_id])
		return RoomSpawnConfig.new()

	# FR-003: all enemy_id values must exist in enemies.json.
	for sp: SpawnPointData in cfg.spawn_points:
		if not ResourceManager.enemy_id_exists(sp.enemy_id):
			push_error("RoomSpawner: unknown enemy_id '%s' in room '%s'"
				% [sp.enemy_id, room_id])
			return RoomSpawnConfig.new()

	return cfg


func _on_player_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if RunManager.is_room_cleared(room_id):  # FR-007: skip if already cleared
		return
	if _spawned:
		return
	_spawn_enemies()


func _spawn_enemies() -> void:
	_spawned = true
	_living_count = _config.spawn_points.size()
	if _living_count == 0:
		return
	for sp: SpawnPointData in _config.spawn_points:
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.enemy_type_id = sp.enemy_id  # must be set before add_child
		get_parent().add_child(enemy)
		var offset := Vector2(
			randf_range(-sp.radius, sp.radius),
			randf_range(-sp.radius, sp.radius)
		)
		enemy.global_position = sp.position + offset  # radius 0 → zero offset (exact)
		enemy.defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated() -> void:
	_living_count -= 1
	if _living_count == 0:
		RunManager.mark_room_cleared(room_id)
		room_cleared.emit()
