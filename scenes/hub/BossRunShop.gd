class_name BossRunShop
extends Control

@export var _button: Button


func _ready() -> void:
	_button.pressed.connect(_on_buy_pressed)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_visibility())
	GlobalSignals.hub_entered.connect(func() -> void: _update_visibility())
	_update_visibility()


func _update_visibility() -> void:
	var threshold: int = ResourceManager.get_meta_config().get("boss_run_kill_threshold", 3)
	visible = MetaManager.endless_boss_kill_count >= threshold and not MetaManager.is_boss_run_unlocked


func _on_buy_pressed() -> void:
	MetaManager.purchase_boss_run()
	_update_visibility()
