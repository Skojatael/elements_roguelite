class_name MovementComponent
extends Node

## Maximum movement speed in pixels per second.
@export var move_speed: float = 200.0
@export var _root: RootComponent

var last_direction: Vector2 = Vector2.DOWN
var _joystick: Node = null
var _base_move_speed: float = 0.0

func _ready() -> void:
	var movement: Dictionary = ResourceManager.get_player_config().get("movement", {})
	_base_move_speed = float(movement.get("move_speed", move_speed))
	assert(_base_move_speed > 0.0,
		"MovementComponent: move_speed must be greater than 0")
	RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_stats())
	RelicManager.relics_cleared.connect(func() -> void: _recompute_stats())



## Called once by the coordinator (Main.gd) to wire the joystick reference.
func set_joystick(node: Node) -> void:
	_joystick = node

func _recompute_stats() -> void:
	move_speed = _base_move_speed * RelicManager.get_stat_mult("move_speed")

func _physics_process(_delta: float) -> void:
	if _joystick == null:
		return
	if _root != null and _root.is_rooted:
		get_parent().velocity = Vector2.ZERO
		get_parent().move_and_slide()
		return
	if _joystick.input_vector != Vector2.ZERO:
		last_direction = _joystick.input_vector.normalized()
	var vel: Vector2 = _joystick.input_vector * move_speed
	get_parent().velocity = vel
	get_parent().move_and_slide()
