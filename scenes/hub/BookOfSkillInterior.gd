class_name BookOfSkillInterior
extends Control

signal close_pressed

@export var _close_button: Button
@export var _forest_label: Label
@export var _forest_button: Button


func _ready() -> void:
	_close_button.pressed.connect(func() -> void: close_pressed.emit())
	_forest_button.pressed.connect(func() -> void: MetaManager.purchase_forest_domain(); _update_ui())
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_ui())
	_update_ui()


func _update_ui() -> void:
	var cfg: Dictionary = ResourceManager.get_meta_config().get("book_of_skill", {}).get("upgrades", {}).get("forest_domain", {})
	var cost: int = int(cfg.get("cost", 40))
	var display_name: String = str(cfg.get("name", "Forest Domain"))
	_close_button.text = "Close"
	if MetaManager.is_forest_domain_unlocked:
		_forest_label.text = "{name}".format({"name": display_name})
		_forest_button.text = "Unlocked"
		_forest_button.disabled = true
	else:
		_forest_label.text = "{name}".format({"name": display_name})
		_forest_button.text = "Unlock ({cost} shards)".format({"cost": cost})
		_forest_button.disabled = not MetaManager.can_spend(cost)
