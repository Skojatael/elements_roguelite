class_name BookOfSkillInterior
extends Control

signal close_pressed

@export var _close_button: Button


func _ready() -> void:
	_close_button.pressed.connect(func() -> void: close_pressed.emit())
