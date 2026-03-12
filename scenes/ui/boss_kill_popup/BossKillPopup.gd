class_name BossKillPopup
extends Control

signal ok_pressed

@export var _message_label: Label
@export var _ok_button: Button


func _ready() -> void:
	_ok_button.pressed.connect(func() -> void: ok_pressed.emit())


func setup(message: String) -> void:
	_message_label.text = message
