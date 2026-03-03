class_name Enemy
extends CharacterBody2D

## Enemy type to load from data/enemies.json. Set in the Inspector.
@export var enemy_type_id: String = "slime"

var _data: EnemyData

signal defeated

@onready var _stats: StatsComponent = $StatsComponent

## --- Contact damage (US2) ---
@onready var _contact_area: Area2D = $ContactArea

var _player_stats: StatsComponent = null
var _in_contact: bool = false
var _damage_timer: float = 0.0

## --- Pursuit AI (US3) ---
enum EnemyState { IDLE, PURSUING }

var _state: EnemyState = EnemyState.IDLE
var _player_ref: Node2D = null

@onready var _detection_area: Area2D = $DetectionArea


func _ready() -> void:
	# Load enemy data from JSON.
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	assert(file != null, "Enemy: failed to open res://data/enemies.json")
	var json_text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	assert(parsed is Dictionary, "Enemy: enemies.json root must be a Dictionary")

	var enemies_array: Array = parsed["enemies"]
	var entry: Dictionary = {}
	for item: Variant in enemies_array:
		if item is Dictionary and item.get("id", "") == enemy_type_id:
			entry = item
			break
	assert(not entry.is_empty(),
		"Enemy: no entry found in enemies.json for id '%s'" % enemy_type_id)

	initialize(EnemyData.from_dict(entry))

	# Wire death signal.
	_stats.died.connect(_on_died)

	# Wire contact damage signals.
	_contact_area.body_entered.connect(_on_contact_entered)
	_contact_area.body_exited.connect(_on_contact_exited)

	# Wire detection signals.
	_detection_area.body_entered.connect(_on_detected)
	_detection_area.body_exited.connect(_on_lost)


func initialize(data: EnemyData) -> void:
	_data = data
	_stats.max_health = data.max_health
	_stats.current_health = data.max_health


func apply_difficulty(mult: float) -> void:
	_stats.max_health *= mult
	_stats.current_health = _stats.max_health


func get_hp_ratio() -> float:
	if _stats.max_health <= 0.0:
		return 1.0
	return _stats.current_health / _stats.max_health


func take_damage(amount: float) -> void:
	_stats.take_damage(amount)


func _physics_process(delta: float) -> void:
	# Contact damage tick (US2).
	if _in_contact and _player_stats != null and is_instance_valid(_player_stats):
		_damage_timer -= delta
		if _damage_timer <= 0.0:
			_player_stats.take_damage(_data.damage)
			_damage_timer = _data.damage_cooldown

	# Pursuit movement (US3).
	if _state == EnemyState.PURSUING and is_instance_valid(_player_ref):
		velocity = global_position.direction_to(_player_ref.global_position) * _data.move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO


func _on_died() -> void:
	defeated.emit()
	queue_free()


# --- Contact damage callbacks (US2) ---

func _on_contact_entered(body: Node2D) -> void:
	if body.has_node("StatsComponent"):
		_player_stats = body.get_node("StatsComponent")
		_in_contact = true
		_damage_timer = 0.0


func _on_contact_exited(_body: Node2D) -> void:
	_in_contact = false


# --- Pursuit AI callbacks (US3) ---

func _on_detected(body: Node2D) -> void:
	if body.has_node("StatsComponent"):
		_player_ref = body
		_state = EnemyState.PURSUING


func _on_lost(body: Node2D) -> void:
	if body == _player_ref:
		_state = EnemyState.IDLE
		_player_ref = null
