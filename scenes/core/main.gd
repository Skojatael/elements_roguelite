extends Node2D

const DEV_MODE: bool = true
const _DEV_PANEL_SCENE = preload("res://scenes/ui/dev/DevPanel.tscn")
const _HUB_ROOM_SCENE = preload("res://scenes/hub/HubRoom.tscn")
const _RESULTS_SCREEN_SCENE = preload("res://scenes/ui/run_end/ResultsScreen.tscn")
const _RELIC_OFFER_SCENE = preload("res://scenes/ui/relic_offer/RelicOfferScreen.tscn")
const _BOSS_ROOM_DATA := preload("res://data/rooms/BossRoom01.tres")
const _BOSS_VICTORY_OVERLAY_SCENE = preload("res://scenes/ui/boss_victory/BossVictoryOverlay.tscn")
const _BOSS_KILL_POPUP_SCENE = preload("res://scenes/ui/boss_kill_popup/BossKillPopup.tscn")
const BOSS_ROOM_WORLD_POS: Vector2 = Vector2(0.0, -3000.0)
const BOSS_PLAYER_SPAWN_OFFSET: Vector2 = Vector2(0.0, 400.0)

@onready var _exploration_hud: CanvasLayer = $ExplorationHUD
@onready var _joystick: JoystickControl = $ExplorationHUD/Joystick
@onready var _player: Node2D = $Player
@onready var _movement: MovementComponent = $Player/MovementComponent
@onready var _stats: StatsComponent = $Player/StatsComponent
@onready var _skill_component: SkillComponent = $Player/SkillComponent
@onready var _camera: Camera2D = $Camera2D
@onready var _dungeon_gen: DungeonGenerator = $DungeonGenerator
@onready var _room_loader: RoomLoader = $RoomLoader
@onready var _dodge_component: DodgeComponent = $Player/DodgeComponent

var _hub_room: HubRoom = null
var _results_screen: ResultsScreen = null
var _results_layer: CanvasLayer = null
var _relic_offer_layer: CanvasLayer = null
var _relic_offer_screen: RelicOfferScreen = null
var _boss_room_spawner: RoomSpawner = null
var _boss_room_node: Node = null
var _boss_victory_layer: CanvasLayer = null
var _boss_victory_overlay: BossVictoryOverlay = null
var _boss_relic_pending: bool = false
var _boss_kill_popup_layer: CanvasLayer = null
var _first_boss_popup_pending: bool = false
var _book_of_skill_popup_pending: bool = false
var _boss_return_room_id: String = ""


func _ready() -> void:
	if DEV_MODE:
		var panel := _DEV_PANEL_SCENE.instantiate()
		add_child(panel)
		panel.start_run_pressed.connect(func(): RunManager.start_run("endless"))
		panel.end_run_pressed.connect(func(): RunManager.end_run(RunManager.EndReason.DIED))
		panel.cash_out_pressed.connect(func(): RunManager.end_run(RunManager.EndReason.CASH_OUT))
		panel.start_boss_pressed.connect(_on_dev_start_boss)
		panel.get_relic_pressed.connect(_on_dev_get_relic)
	_movement.set_joystick(_joystick)
	(_exploration_hud as ExplorationHUD).setup_hp_bar(_stats)
	(_exploration_hud as ExplorationHUD).setup_skill(_skill_component)
	(_exploration_hud as ExplorationHUD).setup_dodge(_dodge_component)
	(_exploration_hud as ExplorationHUD).dodge_button_pressed.connect(_dodge_component.activate)
	_stats.died.connect(_on_player_died)
	RunManager.run_started.connect(func(_m: String) -> void: _on_run_started())
	RunManager.run_ended.connect(_on_run_ended)
	RelicManager.relic_offer_ready.connect(_on_relic_offer_ready)
	MetaManager.book_of_skill_gate_reached.connect(func() -> void: _book_of_skill_popup_pending = true)
	_exploration_hud.boss_teleport_pressed.connect(_on_boss_teleport_pressed)
	_hub_room = _HUB_ROOM_SCENE.instantiate()
	add_child(_hub_room)
	_hub_room.hub_exited.connect(_on_hub_exited)
	_hub_room.hub_boss_run_pressed.connect(_on_hub_boss_run_pressed)
	GlobalSignals.hub_entered.emit()
	_exploration_hud.visible = true


func _process(_delta: float) -> void:
	if RunManager.current_room != null:
		var room_id: String = (RunManager.current_room as RoomSpawner).room_id
		if _dungeon_gen.rooms_by_id.has(room_id):
			_camera.global_position = _dungeon_gen.rooms_by_id[room_id]["world_pos"]
		else:
			_camera.global_position = (RunManager.current_room as RoomSpawner).get_parent().global_position


func _on_run_started() -> void:
	_boss_relic_pending = false
	_first_boss_popup_pending = false
	_book_of_skill_popup_pending = false
	_boss_return_room_id = ""
	if is_instance_valid(_boss_room_node):
		_boss_room_node.queue_free()
	_boss_room_node = null
	_boss_room_spawner = null
	if _boss_kill_popup_layer != null:
		_boss_kill_popup_layer.queue_free()
		_boss_kill_popup_layer = null
	if _boss_victory_layer != null:
		_boss_victory_layer.queue_free()
		_boss_victory_layer = null
		_boss_victory_overlay = null
	if is_instance_valid(_hub_room):
		_hub_room.queue_free()
		_hub_room = null
	if _results_layer != null:
		_results_layer.queue_free()
		_results_layer = null
		_results_screen = null


func _on_hub_exited(domain: String) -> void:
	_hub_room = null  # HubRoom calls queue_free() on itself; clear the reference
	RunManager.start_run("endless", domain)
	GlobalSignals.gameplay_started.emit()


func _on_hub_boss_run_pressed() -> void:
	_hub_room = null  # HubRoom calls queue_free() on itself; clear the reference
	RunManager.start_run("boss")
	GlobalSignals.gameplay_started.emit()
	_on_boss_teleport_pressed()


func _on_player_died() -> void:
	GlobalSignals.gameplay_ended.emit()
	RunManager.end_run(RunManager.EndReason.DIED)


func _on_run_ended(_reason: RunManager.EndReason) -> void:
	_boss_return_room_id = ""
	if is_instance_valid(_boss_room_node):
		_boss_room_node.queue_free()
	_boss_room_node = null
	_boss_room_spawner = null
	if _boss_kill_popup_layer != null:
		_boss_kill_popup_layer.queue_free()
		_boss_kill_popup_layer = null
	if _boss_victory_layer != null:
		_boss_victory_layer.visible = false
		_boss_victory_layer.queue_free()
		_boss_victory_layer = null
		_boss_victory_overlay = null
	if _relic_offer_layer != null:
		_relic_offer_layer.queue_free()
		_relic_offer_layer = null
		_relic_offer_screen = null
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
	_hub_room.hub_boss_run_pressed.connect(_on_hub_boss_run_pressed)
	GlobalSignals.hub_entered.emit()
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
	if _boss_relic_pending:
		_boss_relic_pending = false
		_show_boss_victory_overlay()
		return
	if _book_of_skill_popup_pending:
		_book_of_skill_popup_pending = false
		_show_book_of_skill_popup()
		return
	_exploration_hud.visible = true


func _on_boss_room_cleared(_room_id: String) -> void:
	_boss_room_spawner = null
	_exploration_hud.visible = false
	if RunManager.run_mode == "endless":
		var base: float = ResourceManager.get_enemy_base_essence("forest_boss_thorns")
		var rooms_cleared: int = RunManager.cleared_rooms.size()
		var reward: int = RunManager.rewards_service.get_boss_reward(base, rooms_cleared)
		RunManager.add_currency(reward)
		print("[Main] boss reward — base={b} rooms_cleared={r} reward={w}".format({
			"b": base, "r": rooms_cleared, "w": reward,
		}))
		if MetaManager.endless_boss_kill_count == 1:
			_first_boss_popup_pending = true
		if RelicManager.trigger_boss_offer():
			_boss_relic_pending = true
			return
	_show_boss_victory_overlay()


func _show_boss_victory_overlay() -> void:
	if _first_boss_popup_pending:
		_first_boss_popup_pending = false
		_show_boss_kill_popup()
		return
	_boss_victory_layer = CanvasLayer.new()
	add_child(_boss_victory_layer)
	_boss_victory_overlay = _BOSS_VICTORY_OVERLAY_SCENE.instantiate() as BossVictoryOverlay
	_boss_victory_layer.add_child(_boss_victory_overlay)
	_boss_victory_overlay.setup(RunManager.run_mode == "endless" and not _boss_return_room_id.is_empty())
	_boss_victory_overlay.cash_out_pressed.connect(_on_boss_cash_out_pressed)
	_boss_victory_overlay.continue_pressed.connect(_on_boss_continue_pressed)


func _show_boss_kill_popup() -> void:
	var message: String = ResourceManager.get_meta_config().get("mage_tower", {}).get("first_boss_killed", {}).get("popup_message", "")
	_boss_kill_popup_layer = CanvasLayer.new()
	add_child(_boss_kill_popup_layer)
	var popup: BossKillPopup = _BOSS_KILL_POPUP_SCENE.instantiate() as BossKillPopup
	_boss_kill_popup_layer.add_child(popup)
	popup.setup(message)
	popup.ok_pressed.connect(_on_boss_kill_popup_ok)


func _on_boss_kill_popup_ok() -> void:
	_boss_kill_popup_layer.queue_free()
	_boss_kill_popup_layer = null
	_show_boss_victory_overlay()


func _show_book_of_skill_popup() -> void:
	var message: String = ResourceManager.get_meta_config().get("book_of_skill", {}).get("popup_message", "")
	_boss_kill_popup_layer = CanvasLayer.new()
	add_child(_boss_kill_popup_layer)
	var popup: BossKillPopup = _BOSS_KILL_POPUP_SCENE.instantiate() as BossKillPopup
	_boss_kill_popup_layer.add_child(popup)
	popup.setup(message)
	popup.ok_pressed.connect(_on_book_of_skill_popup_ok)


func _on_book_of_skill_popup_ok() -> void:
	_boss_kill_popup_layer.queue_free()
	_boss_kill_popup_layer = null
	_exploration_hud.visible = true


func _on_boss_cash_out_pressed() -> void:
	RunManager.end_run(RunManager.EndReason.CASH_OUT)


func _on_boss_continue_pressed() -> void:
	if _boss_return_room_id.is_empty():
		return
	if is_instance_valid(_boss_room_node):
		_boss_room_node.queue_free()
	_boss_room_node = null
	_boss_room_spawner = null
	_boss_victory_layer.queue_free()
	_boss_victory_layer = null
	_boss_victory_overlay = null
	GlobalSignals.gameplay_started.emit()
	_room_loader.return_to_room(_boss_return_room_id)
	_boss_return_room_id = ""


func _on_dev_start_boss() -> void:
	if RunManager.is_run_active:
		return
	if _boss_room_spawner != null:
		return
	if _boss_victory_layer != null:
		return
	RunManager.start_run("endless")
	_on_boss_teleport_pressed()


func _on_dev_get_relic() -> void:
	if not RunManager.is_run_active:
		return
	if _relic_offer_screen != null:
		return
	RelicManager.trigger_offer()


func _on_boss_teleport_pressed() -> void:
	if RunManager.current_room != null:
		_boss_return_room_id = (RunManager.current_room as RoomSpawner).room_id
	_room_loader.free_current_room()
	var rooms_cleared: int = RunManager.cleared_rooms.size()
	var boss_mult: float = RunManager.difficulty_service.get_boss_multiplier(rooms_cleared)
	var context: SpawnContext = SpawnContext.create(self, BOSS_ROOM_WORLD_POS)
	var spawner: RoomSpawner = RunManager.spawn_room(_BOSS_ROOM_DATA, "boss_room", context)
	spawner.difficulty_mult = boss_mult
	var room_node: Node = spawner.get_parent()
	for child: Node in room_node.get_children():
		if child is Door:
			child.visible = false
			child.monitoring = false
	_boss_room_spawner = spawner
	_boss_room_node = room_node
	spawner.room_cleared.connect(_on_boss_room_cleared)
	_player.global_position = BOSS_ROOM_WORLD_POS + BOSS_PLAYER_SPAWN_OFFSET
	_camera.global_position = BOSS_ROOM_WORLD_POS
	print("[Main] boss teleport — rooms_cleared={r} boss_mult={m}".format({"r": rooms_cleared, "m": boss_mult}))
