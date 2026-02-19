extends Node2D

@onready var _joystick: JoystickControl = $ExplorationHUD/Joystick
@onready var _movement: MovementComponent = $Player/MovementComponent


func _ready() -> void:
	_movement.set_joystick(_joystick)
	GlobalSignals.gameplay_started.emit()
