class_name RestoreLabOverlay
extends Control

signal restore_pressed
signal maybe_later_pressed

@export var _restore_button: Button
@export var _later_button: Button


func _ready() -> void:
	var cost: int = ResourceManager.get_meta_config().get("alchemy_lab", {}).get("cost", 500)
	_restore_button.text = "Restore the Lab ({c} shards)".format({"c": cost})
	_restore_button.disabled = not MetaManager.can_spend(cost)
	_restore_button.pressed.connect(func() -> void: restore_pressed.emit())
	_later_button.text = "Maybe Later"
	_later_button.pressed.connect(func() -> void: maybe_later_pressed.emit())
