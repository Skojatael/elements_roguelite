extends Control

@export var _button: Button


func _ready() -> void:
	_button.pressed.connect(_on_buy_pressed)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_button())
	_update_button()


func _update_button() -> void:
	var cfg: Dictionary = ResourceManager.get_meta_config().get("damage_upgrade", {})
	var max_levels: int = cfg.get("max_levels", 10)
	if MetaManager.meta_state.damage_upgrade_level >= max_levels:
		_button.text = "Damage Multiplier — MAX"
		_button.disabled = true
		return
	var cost: int = MetaManager.get_next_upgrade_cost()
	_button.text = "Damage Multiplier — {cost} shards".format({"cost": cost})
	_button.disabled = not MetaManager.can_spend(cost)


func _on_buy_pressed() -> void:
	MetaManager.purchase_damage_upgrade()
	_update_button()
