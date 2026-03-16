class_name LabUpgradeScreen
extends Control

signal close_pressed

@export var _essence_button: Button
@export var _transmuter_button: Button
@export var _storage_cap_button: Button
@export var _close_button: Button


func _ready() -> void:
	_close_button.pressed.connect(func() -> void: close_pressed.emit())
	_transmuter_button.pressed.connect(_on_transmuter_pressed)
	_storage_cap_button.pressed.connect(_on_storage_cap_pressed)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_buttons())
	_update_buttons()


func _update_buttons() -> void:
	_update_essence_button()
	_update_transmuter_button()
	_update_storage_cap_button()


func _update_essence_button() -> void:
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


func _update_transmuter_button() -> void:
	var upgrade: Dictionary = ResourceManager.get_meta_config().get("alchemy_lab", {}).get("upgrades", {}).get("gold_generator", {})
	var upgrade_name: String = upgrade.get("name", "gold_generator")
	var cost: int = upgrade.get("cost", 50)
	if MetaManager.is_gold_generator_owned:
		_transmuter_button.text = "{n} — ACTIVE".format({"n": upgrade_name})
		_transmuter_button.disabled = true
		return
	_transmuter_button.text = "{n} ({cost} shards)".format({"n": upgrade_name, "cost": cost})
	_transmuter_button.disabled = not MetaManager.can_spend(cost)


func _update_storage_cap_button() -> void:
	var upgrade: Dictionary = ResourceManager.get_meta_config().get("alchemy_lab", {}).get("upgrades", {}).get("gold_storage_cap", {})
	var upgrade_name: String = upgrade.get("name", "gold_storage_cap")
	var max_levels: int = upgrade.get("max_levels", 2)
	var level: int = MetaManager.meta_state.gold_storage_cap_level
	if level >= max_levels:
		_storage_cap_button.text = "{n} — MAX".format({"n": upgrade_name})
		_storage_cap_button.disabled = true
		return
	var base_hours: int = upgrade.get("base_hours", 4)
	var hours_per_level: int = upgrade.get("hours_per_level", 4)
	var cur_hours: int = base_hours + hours_per_level * level
	var next_hours: int = cur_hours + hours_per_level
	var cost: int = _get_storage_cap_cost(upgrade)
	_storage_cap_button.text = "{n} {cur}h → {next}h ({cost} shards)".format({
		"n": upgrade_name,
		"cur": cur_hours,
		"next": next_hours,
		"cost": cost,
	})
	_storage_cap_button.disabled = not MetaManager.can_spend(cost)


func _get_storage_cap_cost(upgrade: Dictionary) -> int:
	var base_cost: int = upgrade.get("base_cost", 100)
	var cost_scale: float = upgrade.get("cost_scale", 1.5)
	var level: int = MetaManager.meta_state.gold_storage_cap_level
	var cost: int = base_cost
	for _i: int in level:
		cost = floori(float(cost) * cost_scale)
	return cost


func _on_transmuter_pressed() -> void:
	MetaManager.purchase_gold_generator()


func _on_storage_cap_pressed() -> void:
	MetaManager.purchase_gold_storage_cap()
