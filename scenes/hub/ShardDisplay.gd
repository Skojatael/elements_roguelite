extends Control

@export var _label: Label


func _ready() -> void:
	MetaManager.shards_changed.connect(func(new_total: int) -> void:
		_label.text = "Shards: {n}".format({"n": new_total})
	)
	_label.text = "Shards: {n}".format({"n": MetaManager.meta_state.total_shards})
