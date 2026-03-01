class_name StatRow
extends HBoxContainer

@export var _name_label: Label
@export var _value_label: Label


func set_value(n: int) -> void:
	_value_label.text = "{n}".format({"n": n})
