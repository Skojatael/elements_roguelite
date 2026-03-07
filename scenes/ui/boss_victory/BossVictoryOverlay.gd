class_name BossVictoryOverlay
extends Control

signal cash_out_pressed
signal continue_pressed

@export var _cash_out_button: Button
@export var _continue_button: Button


func setup(show_continue: bool) -> void:
	_continue_button.visible = show_continue


func _ready() -> void:
	_cash_out_button.pressed.connect(_on_cash_out_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)


func _on_cash_out_pressed() -> void:
	_cash_out_button.disabled = true
	cash_out_pressed.emit()


func _on_continue_pressed() -> void:
	_continue_button.disabled = true
	_continue_button.text = "Coming Soon..."
	continue_pressed.emit()
