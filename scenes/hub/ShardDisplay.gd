extends Control

@export var _label: Label


func _ready() -> void:
	_label.text = "Shards: {n}".format({"n": MetaManager.meta_state.total_shards})
