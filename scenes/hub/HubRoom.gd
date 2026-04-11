class_name HubRoom
extends Node2D

signal hub_exited(domain: String)
signal hub_boss_run_pressed

@export var teleport_door: TeleportDoor
@export var _boss_run_button: BossRunButton


func _ready() -> void:
	teleport_door.teleport_activated.connect(_on_teleport_activated)
	_boss_run_button.boss_run_pressed.connect(_on_boss_run_pressed)


func _on_teleport_activated(domain: String) -> void:
	hub_exited.emit(domain)
	queue_free()


func _on_boss_run_pressed() -> void:
	hub_boss_run_pressed.emit()
	queue_free()
