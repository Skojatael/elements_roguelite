extends Control

@export var _label: Label
@export var _cap_label: Label


func _ready() -> void:
	_label.text = "Gold: {n}".format({"n": floori(MetaManager.total_gold)})
	MetaManager.gold_changed.connect(func(new_floor: int) -> void:
		_label.text = "Gold: {n}".format({"n": new_floor})
	)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_cap_label())
	_update_cap_label()


func _update_cap_label() -> void:
	if not MetaManager.is_gold_generator_owned:
		_cap_label.text = ""
		return
	_cap_label.text = "Cap: {n}h".format({"n": MetaManager.gold_storage_cap_hours})
