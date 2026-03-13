class_name LabUpgradeScreen
extends Control

signal close_pressed

@export var _essence_button: Button
@export var _close_button: Button


func _ready() -> void:
	_close_button.pressed.connect(func() -> void: close_pressed.emit())
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_buttons())
	_update_buttons()


func _update_buttons() -> void:
	var upgrade: Dictionary = ResourceManager.get_meta_config().get("alchemy_lab", {}).get("upgrades", {}).get("essence_gain", {})
	var upgrade_name: String = upgrade.get("name", "essence_gain")
	var max_levels: int = upgrade.get("max_levels", 1)
	var level: int = MetaManager.meta_state.essence_gain_level
	if level >= max_levels:
		_essence_button.text = "{n} — MAX".format({"n": upgrade_name})
		_essence_button.disabled = true
		return
	var base_cost: int = upgrade.get("base_cost", 0)
	var pct: int = int(float(level + 1) * upgrade.get("essence_per_level", 0.05) * 100.0)
	_essence_button.text = "{n} +{pct}% (Lv{lv})".format({
		"n": upgrade_name,
		"pct": pct,
		"lv": level + 1,
	})
	_essence_button.disabled = base_cost == 0 or not MetaManager.can_spend(base_cost)
