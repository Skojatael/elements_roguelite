class_name ForgeUpgradeScreen
extends Control

signal close_pressed

@export var _damage_button: Button
@export var _missile_charge_button: Button
@export var _rarity_luck_button: Button
@export var _close_button: Button


func _ready() -> void:
	_close_button.pressed.connect(func() -> void: close_pressed.emit())
	_damage_button.pressed.connect(_on_damage_buy)
	_missile_charge_button.pressed.connect(_on_missile_charge_buy)
	_rarity_luck_button.pressed.connect(_on_rarity_luck_buy)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_buttons())
	_update_buttons()


func _update_buttons() -> void:
	_update_damage_button()
	_update_missile_charge_button()
	_update_rarity_luck_button()


func _update_damage_button() -> void:
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


func _update_missile_charge_button() -> void:
	var mc_cfg: Dictionary = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("missile_charge_upgrade", {})
	var mc_name: String = mc_cfg.get("name", "Arcane Reservoir")
	var mc_cost: int = mc_cfg.get("cost", 150)
	if MetaManager.is_missile_extra_charge_owned:
		_missile_charge_button.text = "{n} — Purchased".format({"n": mc_name})
		_missile_charge_button.disabled = true
		return
	if MetaManager.can_spend(mc_cost):
		_missile_charge_button.text = "{n} — {c} shards".format({"n": mc_name, "c": mc_cost})
		_missile_charge_button.disabled = false
	else:
		_missile_charge_button.text = "{n} — {c} shards (insufficient)".format({"n": mc_name, "c": mc_cost})
		_missile_charge_button.disabled = true


func _on_damage_buy() -> void:
	MetaManager.purchase_damage_upgrade()
	_update_buttons()


func _on_missile_charge_buy() -> void:
	MetaManager.purchase_missile_extra_charge()
	_update_buttons()


func _update_rarity_luck_button() -> void:
	var cfg: Dictionary = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("rarity_luck_upgrade", {})
	var rl_name: String = cfg.get("name", "Rarity Luck")
	var rl_cost: int = cfg.get("cost", 350)
	if MetaManager.is_rarity_luck_owned:
		_rarity_luck_button.text = "{n} — Purchased".format({"n": rl_name})
		_rarity_luck_button.disabled = true
		return
	if MetaManager.can_spend(rl_cost):
		_rarity_luck_button.text = "{n} — {c} shards".format({"n": rl_name, "c": rl_cost})
		_rarity_luck_button.disabled = false
	else:
		_rarity_luck_button.text = "{n} — {c} shards (insufficient)".format({"n": rl_name, "c": rl_cost})
		_rarity_luck_button.disabled = true


func _on_rarity_luck_buy() -> void:
	MetaManager.purchase_rarity_luck()
	_update_buttons()
