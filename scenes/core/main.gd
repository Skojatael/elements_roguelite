extends Node2D

const DEV_MODE: bool = true
const _DEV_PANEL_SCENE = preload("res://scenes/ui/dev/DevPanel.tscn")
const _HUB_ROOM_SCENE = preload("res://scenes/hub/HubRoom.tscn")
const _RESULTS_SCREEN_SCENE = preload("res://scenes/ui/run_end/ResultsScreen.tscn")
const _RELIC_OFFER_SCENE = preload("res://scenes/ui/relic_offer/RelicOfferScreen.tscn")

@onready var _exploration_hud: CanvasLayer = $ExplorationHUD
@onready var _joystick: JoystickControl = $ExplorationHUD/Joystick
@onready var _player: Node2D = $Player
@onready var _movement: MovementComponent = $Player/MovementComponent
@onready var _stats: StatsComponent = $Player/StatsComponent
@onready var _camera: Camera2D = $Camera2D
@onready var _dungeon_gen: DungeonGenerator = $DungeonGenerator

var _hub_room: Node = null
var _results_screen: Node = null
var _results_layer: CanvasLayer = null
var _relic_offer_layer: CanvasLayer = null
var _relic_offer_screen: RelicOfferScreen = null


func _ready() -> void:
	if DEV_MODE:
		var panel := _DEV_PANEL_SCENE.instantiate()
		add_child(panel)
		panel.start_run_pressed.connect(func(): RunManager.start_run("endless"))
		panel.end_run_pressed.connect(func(): RunManager.end_run(RunManager.EndReason.DIED))
		panel.cash_out_pressed.connect(func(): RunManager.end_run(RunManager.EndReason.CASH_OUT))
		panel.start_boss_pressed.connect(func(): print("[DevPanel] start_boss pressed — stub"))
		panel.get_relic_pressed.connect(_on_dev_get_relic)
	_movement.set_joystick(_joystick)
	_stats.died.connect(_on_player_died)
	RunManager.run_started.connect(func(_m: String) -> void: _on_run_started())
	RunManager.run_ended.connect(_on_run_ended)
	RelicManager.relic_offer_ready.connect(_on_relic_offer_ready)
	_hub_room = _HUB_ROOM_SCENE.instantiate()
	add_child(_hub_room)
	_hub_room.hub_exited.connect(_on_hub_exited)
	_exploration_hud.visible = true


func _process(_delta: float) -> void:
	if RunManager.current_room != null:
		var room_id: String = (RunManager.current_room as RoomSpawner).room_id
		if _dungeon_gen.rooms_by_id.has(room_id):
			_camera.global_position = _dungeon_gen.rooms_by_id[room_id]["world_pos"]


func _on_run_started() -> void:
	if is_instance_valid(_hub_room):
		_hub_room.queue_free()
		_hub_room = null
	if _results_layer != null:
		_results_layer.queue_free()
		_results_layer = null
		_results_screen = null


func _on_hub_exited() -> void:
	_hub_room = null  # HubRoom calls queue_free() on itself; clear the reference
	RunManager.start_run("endless")
	GlobalSignals.gameplay_started.emit()


func _on_player_died() -> void:
	GlobalSignals.gameplay_ended.emit()
	RunManager.end_run(RunManager.EndReason.DIED)


func _on_run_ended(_reason: RunManager.EndReason) -> void:
	if is_instance_valid(_hub_room):
		_hub_room.queue_free()
		_hub_room = null
	_player.visible = false
	_results_layer = CanvasLayer.new()
	add_child(_results_layer)
	_results_screen = _RESULTS_SCREEN_SCENE.instantiate()
	_results_layer.add_child(_results_screen)
	(_results_screen as ResultsScreen).setup(RunManager.run_summary)
	(_results_screen as ResultsScreen).return_pressed.connect(_on_results_return)


func _on_results_return() -> void:
	_results_layer.queue_free()
	_results_layer = null
	_results_screen = null
	_hub_room = _HUB_ROOM_SCENE.instantiate()
	add_child(_hub_room)
	_camera.global_position = Vector2.ZERO
	_hub_room.hub_exited.connect(_on_hub_exited)
	_player.global_position = _hub_room.global_position
	_player.visible = true
	_exploration_hud.visible = true


func _on_relic_offer_ready(options: Array) -> void:
	_exploration_hud.visible = false
	_relic_offer_layer = CanvasLayer.new()
	add_child(_relic_offer_layer)
	_relic_offer_screen = _RELIC_OFFER_SCENE.instantiate() as RelicOfferScreen
	_relic_offer_layer.add_child(_relic_offer_screen)
	_relic_offer_screen.setup(options)
	_relic_offer_screen.relic_picked.connect(_on_relic_picked)


func _on_relic_picked(relic_id: String) -> void:
	RelicManager.pick_relic(relic_id)
	_relic_offer_layer.queue_free()
	_relic_offer_layer = null
	_relic_offer_screen = null
	_exploration_hud.visible = true


func _on_dev_get_relic() -> void:
	if not RunManager.is_run_active:
		return
	if _relic_offer_screen != null:
		return
	RelicManager.trigger_offer()
