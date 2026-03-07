class_name AdventuringGearShop
extends Control

@export var _button: Button


func _ready() -> void:
	_button.pressed.connect(_on_buy_pressed)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_visibility())
	_update_visibility()


func _update_visibility() -> void:
	visible = MetaManager.is_first_boss_killed and not MetaManager.is_adventuring_gear_owned


func _on_buy_pressed() -> void:
	MetaManager.purchase_adventuring_gear()
	_update_visibility()
