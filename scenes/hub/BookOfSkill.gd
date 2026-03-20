class_name BookOfSkill
extends Control

@export var _not_created_visual: ColorRect
@export var _created_visual: ColorRect
@export var _label: Label
@export var _button: Button
@export var _buy_overlay_scene: PackedScene
@export var _interior_scene: PackedScene

var _overlay_layer: CanvasLayer = null


func _ready() -> void:
	_not_created_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_created_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_visuals())
	GlobalSignals.hub_entered.connect(func() -> void: _update_visuals())
	_button.pressed.connect(_on_button_pressed)
	_update_visuals()


func _update_visuals() -> void:
	visible = MetaManager.is_book_of_skill_gate_reached
	_not_created_visual.visible = not MetaManager.is_book_of_skill_owned
	_created_visual.visible = MetaManager.is_book_of_skill_owned


func _on_button_pressed() -> void:
	if MetaManager.is_book_of_skill_owned:
		_show_interior()
	else:
		_show_buy_overlay()


func _show_buy_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	add_child(_overlay_layer)
	var overlay: BookOfSkillBuyOverlay = _buy_overlay_scene.instantiate() as BookOfSkillBuyOverlay
	_overlay_layer.add_child(overlay)
	overlay.buy_pressed.connect(_on_buy_pressed)
	overlay.maybe_later_pressed.connect(_close_overlay)


func _on_buy_pressed() -> void:
	MetaManager.purchase_book_of_skill()
	_close_overlay()
	_update_visuals()


func _show_interior() -> void:
	_overlay_layer = CanvasLayer.new()
	add_child(_overlay_layer)
	var interior: BookOfSkillInterior = _interior_scene.instantiate() as BookOfSkillInterior
	_overlay_layer.add_child(interior)
	interior.close_pressed.connect(_close_overlay)


func _close_overlay() -> void:
	if _overlay_layer == null:
		return
	_overlay_layer.queue_free()
	_overlay_layer = null
