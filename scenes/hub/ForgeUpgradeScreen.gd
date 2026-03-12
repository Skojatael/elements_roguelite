class_name ForgeUpgradeScreen
extends Control

signal close_pressed

@export var _damage_button: Button
@export var _close_button: Button


func _ready() -> void:
	_close_button.pressed.connect(func() -> void: close_pressed.emit())
	_damage_button.pressed.connect(_on_damage_buy)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_buttons())
	_update_buttons()


func _update_buttons() -> void:
	var upgrade: Dictionary = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("damage_upgrade", {})
	var upgrade_name: String = upgrade.get("name", "damage_upgrade")
	var max_levels: int = upgrade.get("max_levels", 10)
	if MetaManager.meta_state.damage_upgrade_level >= max_levels:
		_damage_button.text = "{n} — MAX".format({"n": upgrade_name})
		_damage_button.disabled = true
		return
	var cost: int = MetaManager.get_next_upgrade_cost()
	var level: int = MetaManager.meta_state.damage_upgrade_level
	var pct: int = int(float(level + 1) * upgrade.get("damage_per_level", 0.1) * 100.0)
	_damage_button.text = "{n} +{pct}% (Lv{lv}) — {cost} shards".format({
		"n": upgrade_name,
		"pct": pct,
		"lv": level + 1,
		"cost": cost,
	})
	_damage_button.disabled = not MetaManager.can_spend(cost)


func _on_damage_buy() -> void:
	MetaManager.purchase_damage_upgrade()
	_update_buttons()
