class_name ExplorationHUD
extends CanvasLayer

# NOTE: This script requires GlobalSignals to be registered as an autoload.
# In Godot Editor: Project → Project Settings → Autoload
# Add: scenes/shared/GlobalSignals.gd  |  Name: GlobalSignals
# Then attach this script to ExplorationHUD.tscn via the Editor.

const BOSS_ENEMY_ID: String = "forest_boss_thorns"
const BOSS_ROOM_ID: String = "boss_room"

## Emitted when the player presses the Teleport to Boss button.
## Main.gd connects to this signal to handle the teleportation.
signal boss_teleport_pressed

## Emitted when the player presses the Dodge button.
## Main.gd connects this to DodgeComponent.activate().
signal dodge_button_pressed

const CHARGE_ACTIVE_COLOR: Color = Color(0.9, 0.6, 0.1)
const CHARGE_SPENT_COLOR: Color = Color(0.2, 0.2, 0.2)
const SKILL_READY_MODULATE: Color = Color(1, 1, 1, 1)
const SKILL_COOLDOWN_MODULATE: Color = Color(0.5, 0.5, 0.5, 1)

@export var _boss_button: Button
@export var _skill_button: Button
@export var _dodge_button: Button
@export var _hp_bar: HPBar
@export var _charge_pips_container: Control
@export var _charge_pip_gap: float = 4.0

var _charge_pips: Array[ColorRect] = []


func _ready() -> void:
	GlobalSignals.gameplay_started.connect(_on_gameplay_started)
	GlobalSignals.gameplay_ended.connect(_on_gameplay_ended)
	GlobalSignals.hub_entered.connect(_on_hub_entered)
	RunManager.run_started.connect(func(_m: String) -> void: _on_gameplay_started())
	RunManager.run_ended.connect(func(_r: RunManager.EndReason) -> void: _on_gameplay_ended())
	_boss_button.visible = false
	_boss_button.pressed.connect(_on_boss_button_pressed)
	_skill_button.pressed.connect(_on_skill_button_pressed)
	_dodge_button.pressed.connect(func() -> void: dodge_button_pressed.emit())
	_dodge_button.visible = false
	RunManager.room_cleared.connect(_on_room_cleared_for_boss)
	RunManager.run_started.connect(func(_m: String) -> void: _boss_button.visible = false)
	# Hide by default; shown when a run starts.
	visible = false


func _on_gameplay_started() -> void:
	visible = true
	_skill_button.visible = true
	_dodge_button.visible = true
	_hp_bar.visible = true
	if _charge_pips_container != null:
		_charge_pips_container.visible = true


func _on_gameplay_ended() -> void:
	visible = false


func _on_hub_entered() -> void:
	_skill_button.visible = false
	_dodge_button.visible = false
	_hp_bar.visible = false
	if _charge_pips_container != null:
		_charge_pips_container.visible = false


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


func setup_hp_bar(stats: StatsComponent) -> void:
	_hp_bar.setup(stats)


func setup_dodge(dodge: DodgeComponent) -> void:
	dodge.cooldown_changed.connect(_on_dodge_cooldown_changed)


func _on_dodge_cooldown_changed(remaining: float, _total: float) -> void:
	_dodge_button.modulate = SKILL_COOLDOWN_MODULATE if remaining > 0.0 else SKILL_READY_MODULATE


func setup_skill(skill: SkillComponent) -> void:
	_build_charge_pips(skill._max_charges)
	skill.charges_changed.connect(_on_charges_changed)
	skill.cooldown_changed.connect(_on_cooldown_changed)
	_on_charges_changed(skill._current_charges, skill._max_charges)


func _build_charge_pips(count: int) -> void:
	for child: Node in _charge_pips_container.get_children():
		child.free()
	_charge_pips.clear()
	const PIP_SIZE: float = 20.0
	for i: int in count:
		var pip := ColorRect.new()
		pip.size = Vector2(PIP_SIZE, PIP_SIZE)
		pip.position = Vector2(i * (PIP_SIZE + _charge_pip_gap), 0.0)
		_charge_pips_container.add_child(pip)
		_charge_pips.append(pip)
	_charge_pips_container.custom_minimum_size = Vector2(
		count * PIP_SIZE + (count - 1) * _charge_pip_gap, PIP_SIZE
	)


func _on_cooldown_changed(remaining: float, _total: float) -> void:
	_skill_button.modulate = SKILL_COOLDOWN_MODULATE if remaining > 0.0 else SKILL_READY_MODULATE


func _on_charges_changed(current: int, maximum: int) -> void:
	if _charge_pips.size() != maximum:
		_build_charge_pips(maximum)
	for i: int in _charge_pips.size():
		_charge_pips[i].color = CHARGE_ACTIVE_COLOR if i < current else CHARGE_SPENT_COLOR


func _on_skill_button_pressed() -> void:
	GlobalSignals.skill_button_pressed.emit()
