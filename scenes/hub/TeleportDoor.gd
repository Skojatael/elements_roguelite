class_name TeleportDoor
extends Node2D

signal teleport_activated(domain: String)

@export var button: Button
@export var domain: String = "forest"


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	if not RunManager.is_run_active:
		teleport_activated.emit(domain)
