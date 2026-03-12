class_name MageTowerUpgradeScreen
extends Control

signal close_pressed

@export var _de_button: Button
@export var _rs_button: Button
@export var _bc_button: Button
@export var _close_button: Button

var _entries: Array[Dictionary]


func _ready() -> void:
	var upgrades: Dictionary = ResourceManager.get_meta_config().get("mage_tower", {}).get("upgrades", {})
	_entries = [
		upgrades.get("dungeon_expansion", {}).merged({"button": _de_button, "owned_prop": "is_adventuring_gear_owned", "purchase": MetaManager.purchase_adventuring_gear}),
		upgrades.get("relic_system",      {}).merged({"button": _rs_button, "owned_prop": "is_relic_offers_active",    "purchase": MetaManager.purchase_mage_tower_relic_system}),
		upgrades.get("boss_challenge",    {}).merged({"button": _bc_button, "owned_prop": "is_boss_run_unlocked",      "purchase": MetaManager.purchase_boss_run, "gate_prop": "is_first_boss_killed", "gate_text": upgrades.get("boss_challenge", {}).get("gate_text", "")}),
	]
	for entry in _entries:
		(entry.get("button") as Button).pressed.connect(func() -> void: (entry.get("purchase") as Callable).call(); _update_entries())
	_close_button.pressed.connect(func() -> void: close_pressed.emit())
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_entries())
	_update_entries()


func _update_entries() -> void:
	for cfg in _entries:
		_apply_entry(cfg)


func _apply_entry(cfg: Dictionary) -> void:
	var button: Button = cfg.get("button")
	var gate_prop: String = cfg.get("gate_prop", "")
	if gate_prop != "" and not MetaManager.get(gate_prop):
		button.text = cfg.get("gate_text", "")
		button.disabled = true
		return
	var name: String = cfg.get("name", "")
	var cost: int = cfg.get("cost", 0)
	var owned: bool = MetaManager.get(cfg.get("owned_prop", ""))
	if owned:
		button.text = "{n} — Unlocked".format({"n": name})
		button.disabled = true
	else:
		button.text = "{n} — {c} shards".format({"n": name, "c": cost})
		button.disabled = not MetaManager.can_spend(cost)
