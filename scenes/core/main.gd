extends Node2D

const DEV_MODE: bool = true
const _DEV_PANEL_SCENE = preload("res://scenes/ui/dev/DevPanel.tscn")
const _HUB_ROOM_SCENE = preload("res://scenes/hub/HubRoom.tscn")

@onready var _exploration_hud: CanvasLayer = $ExplorationHUD
@onready var _joystick: JoystickControl = $ExplorationHUD/Joystick
@onready var _movement: MovementComponent = $Player/MovementComponent
@onready var _stats: StatsComponent = $Player/StatsComponent

var _hub_room: Node = null


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
	_hub_room = _HUB_ROOM_SCENE.instantiate()
	add_child(_hub_room)
	_hub_room.hub_exited.connect(_on_hub_exited)
	_exploration_hud.visible = true


func _on_hub_exited() -> void:
	RunManager.start_run("endless")
	GlobalSignals.gameplay_started.emit()


func _on_player_died() -> void:
	GlobalSignals.gameplay_ended.emit()
	RunManager.end_run(RunManager.EndReason.DIED)
