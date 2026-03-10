class_name MageTower
extends Control

@export var _ruined_visual: ColorRect
@export var _magic_visual: ColorRect
@export var _label: Label
@export var _button: Button
@export var _restore_overlay_scene: PackedScene
@export var _upgrade_screen_scene: PackedScene

var _overlay_layer: CanvasLayer = null


func _ready() -> void:
	_button.pressed.connect(_on_tower_pressed)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_visuals())
	GlobalSignals.hub_entered.connect(func() -> void: _update_visuals())
	_update_visuals()


func _update_visuals() -> void:
	var unlocked: bool = MetaManager.is_mage_tower_unlocked
	_ruined_visual.visible = not unlocked
	_magic_visual.visible = unlocked
	_label.text = "Mage Tower" if unlocked else "Ruined Mage Tower"


func _on_tower_pressed() -> void:
	if _overlay_layer != null:
		return
	if MetaManager.is_mage_tower_unlocked:
		_show_upgrade_screen()
	else:
		_show_restore_overlay()


func _show_restore_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	add_child(_overlay_layer)
	var overlay: RestoreTowerOverlay = _restore_overlay_scene.instantiate() as RestoreTowerOverlay
	_overlay_layer.add_child(overlay)
	overlay.restore_pressed.connect(_on_restore_pressed)
	overlay.maybe_later_pressed.connect(_close_overlay)


func _show_upgrade_screen() -> void:
	_overlay_layer = CanvasLayer.new()
	add_child(_overlay_layer)
	var screen: MageTowerUpgradeScreen = _upgrade_screen_scene.instantiate() as MageTowerUpgradeScreen
	_overlay_layer.add_child(screen)
	screen.close_pressed.connect(_close_overlay)


func _close_overlay() -> void:
	if _overlay_layer == null:
		return
	_overlay_layer.queue_free()
	_overlay_layer = null


func _on_restore_pressed() -> void:
	var success: bool = MetaManager.purchase_mage_tower()
	if not success:
		return
	_close_overlay()
	_update_visuals()
