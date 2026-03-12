class_name RestoreTowerOverlay
extends Control

signal restore_pressed
signal maybe_later_pressed

@export var _restore_button: Button
@export var _later_button: Button


func _ready() -> void:
	var cost: int = ResourceManager.get_meta_config().get("mage_tower", {}).get("cost", 200)
	_restore_button.text = "Restore the Mage Tower ({c} shards)".format({"c": cost})
	_restore_button.disabled = not MetaManager.can_spend(cost)
	_restore_button.pressed.connect(func() -> void: restore_pressed.emit())
	_later_button.text = "Maybe Later"
	_later_button.pressed.connect(func() -> void: maybe_later_pressed.emit())
