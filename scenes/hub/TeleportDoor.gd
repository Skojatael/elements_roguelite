class_name TeleportDoor
extends Node2D

signal teleport_activated

@export var button: Button


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	if not RunManager.is_run_active:
		teleport_activated.emit()
