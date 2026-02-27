class_name HubRoom
extends Node2D

signal hub_exited

@export var teleport_door: TeleportDoor


func _ready() -> void:
	teleport_door.teleport_activated.connect(_on_teleport_activated)


func _on_teleport_activated() -> void:
	hub_exited.emit()
	queue_free()
