extends Node2D

const DEV_MODE: bool = true
const _DEV_PANEL_SCENE = preload("res://scenes/ui/dev/DevPanel.tscn")

@onready var _joystick: JoystickControl = $ExplorationHUD/Joystick
@onready var _movement: MovementComponent = $Player/MovementComponent
@onready var _stats: StatsComponent = $Player/StatsComponent


func _ready() -> void:
	if DEV_MODE:
		var panel := _DEV_PANEL_SCENE.instantiate()
		add_child(panel)
		panel.start_run_pressed.connect(func(): RunManager.start_run("endless"))
		panel.end_run_pressed.connect(func(): RunManager.end_run(RunManager.EndReason.DIED))
		panel.cash_out_pressed.connect(func(): RunManager.end_run(RunManager.EndReason.CASH_OUT))
		panel.start_boss_pressed.connect(func(): print("[DevPanel] start_boss pressed — stub"))
	_movement.set_joystick(_joystick)
	_stats.died.connect(_on_player_died)
	GlobalSignals.gameplay_started.emit()
	RunManager.start_run("endless")


func _on_player_died() -> void:
	GlobalSignals.gameplay_ended.emit()
	RunManager.end_run(RunManager.EndReason.DIED)
