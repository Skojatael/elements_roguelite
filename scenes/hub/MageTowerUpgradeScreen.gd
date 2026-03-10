class_name MageTowerUpgradeScreen
extends Control

signal close_pressed

@export var _de_button: Button
@export var _rs_button: Button
@export var _bc_button: Button
@export var _close_button: Button


func _ready() -> void:
	_de_button.pressed.connect(_on_de_buy)
	_rs_button.pressed.connect(_on_rs_buy)
	_bc_button.pressed.connect(_on_bc_buy)
	_close_button.pressed.connect(func() -> void: close_pressed.emit())
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_entries())
	_update_entries()


func _update_entries() -> void:
	var cfg: Dictionary = ResourceManager.get_meta_config()
	var de_cost: int = cfg.get("mage_tower_dungeon_expansion_cost", 200)
	var rs_cost: int = cfg.get("mage_tower_relic_system_cost", 100)
	var bc_cost: int = cfg.get("mage_tower_boss_challenge_cost", 200)

	if MetaManager.is_adventuring_gear_owned:
		_de_button.text = "Dungeon Expansion — Unlocked"
		_de_button.disabled = true
	else:
		_de_button.text = "Dungeon Expansion — {c} shards".format({"c": de_cost})
		_de_button.disabled = not MetaManager.can_spend(de_cost)

	if MetaManager.is_relic_offers_active:
		_rs_button.text = "Relic System — Unlocked"
		_rs_button.disabled = true
	else:
		_rs_button.text = "Relic System — {c} shards".format({"c": rs_cost})
		_rs_button.disabled = not MetaManager.can_spend(rs_cost)

	if MetaManager.is_boss_run_unlocked:
		_bc_button.text = "Boss Challenge Mode — Unlocked"
		_bc_button.disabled = true
	else:
		_bc_button.text = "Boss Challenge Mode — {c} shards".format({"c": bc_cost})
		_bc_button.disabled = not MetaManager.can_spend(bc_cost)


func _on_de_buy() -> void:
	MetaManager.purchase_adventuring_gear()
	_update_entries()


func _on_rs_buy() -> void:
	MetaManager.purchase_mage_tower_relic_system()
	_update_entries()


func _on_bc_buy() -> void:
	MetaManager.purchase_boss_run()
	_update_entries()
