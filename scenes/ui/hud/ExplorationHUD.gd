class_name ExplorationHUD
extends CanvasLayer

# NOTE: This script requires GlobalSignals to be registered as an autoload.
# In Godot Editor: Project → Project Settings → Autoload
# Add: scenes/shared/GlobalSignals.gd  |  Name: GlobalSignals
# Then attach this script to ExplorationHUD.tscn via the Editor.

const BOSS_ENEMY_ID: String = "boss"
const BOSS_ROOM_ID: String = "boss_room"

## Emitted when the player presses the Teleport to Boss button.
## Main.gd connects to this signal to handle the teleportation.
signal boss_teleport_pressed

@export var _boss_button: Button


func _ready() -> void:
	GlobalSignals.gameplay_started.connect(_on_gameplay_started)
	GlobalSignals.gameplay_ended.connect(_on_gameplay_ended)
	RunManager.run_started.connect(func(_m: String) -> void: _on_gameplay_started())
	RunManager.run_ended.connect(func(_r: RunManager.EndReason) -> void: _on_gameplay_ended())
	_boss_button.visible = false
	_boss_button.pressed.connect(_on_boss_button_pressed)
	RunManager.room_cleared.connect(_on_room_cleared_for_boss)
	RunManager.run_started.connect(func(_m: String) -> void: _boss_button.visible = false)
	# Hide by default; shown when a run starts.
	visible = false


func _on_gameplay_started() -> void:
	visible = true


func _on_gameplay_ended() -> void:
	visible = false


static func is_boss_available(cleared_count: int, required: int) -> bool:
	return cleared_count >= required


func _on_room_cleared_for_boss(room_id: String) -> void:
	if room_id == BOSS_ROOM_ID:
		return
	if _boss_button.visible:
		return
	var threshold: int = ResourceManager.get_enemy_rooms_required(BOSS_ENEMY_ID)
	if not ExplorationHUD.is_boss_available(RunManager.cleared_rooms.size(), threshold):
		return
	_boss_button.visible = true


func _on_boss_button_pressed() -> void:
	_boss_button.visible = false
	boss_teleport_pressed.emit()
