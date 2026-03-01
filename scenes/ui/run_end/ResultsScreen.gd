class_name ResultsScreen
extends Control

signal return_pressed

@export var _essence_row: StatRow
@export var _enemies_row: StatRow
@export var _rooms_row: StatRow
@export var _return_button: Button

var _return_activated: bool = false


func _ready() -> void:
	_return_button.pressed.connect(_on_return_pressed)


func setup(summary: RunSummary) -> void:
	_essence_row.set_value(summary.essence_cashed_out)
	_enemies_row.set_value(summary.enemies_slain)
	_rooms_row.set_value(summary.rooms_cleared)


func _on_return_pressed() -> void:
	if _return_activated:
		return
	_return_activated = true
	return_pressed.emit()
