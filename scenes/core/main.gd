extends Node2D

@onready var _joystick: JoystickControl = $ExplorationHUD/Joystick
@onready var _movement: MovementComponent = $Player/MovementComponent
@onready var _stats: StatsComponent = $Player/StatsComponent


func _ready() -> void:
	_movement.set_joystick(_joystick)
	_stats.died.connect(_on_player_died)
	GlobalSignals.gameplay_started.emit()
	RunManager.start_run("endless")


func _on_player_died() -> void:
	GlobalSignals.gameplay_ended.emit()
	RunManager.end_run("dead")
