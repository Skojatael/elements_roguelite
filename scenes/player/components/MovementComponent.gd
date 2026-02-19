class_name MovementComponent
extends Node

## Maximum movement speed in pixels per second.
@export var move_speed: float = 200.0

var _joystick: Node = null


func _ready() -> void:
	assert(move_speed > 0.0,
		"MovementComponent: move_speed must be greater than 0")


## Called once by the coordinator (Main.gd) to wire the joystick reference.
func set_joystick(node: Node) -> void:
	_joystick = node


func _physics_process(_delta: float) -> void:
	if _joystick == null:
		return
	var vel: Vector2 = _joystick.input_vector * move_speed
	get_parent().velocity = vel
	get_parent().move_and_slide()
