class_name Door
extends Area2D

@export var direction: String = ""
@export var target_room_id: String = ""

signal door_activated(direction: String, target_room_id: String)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		door_activated.emit(direction, target_room_id)
