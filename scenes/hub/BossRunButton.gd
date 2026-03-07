class_name BossRunButton
extends Control

signal boss_run_pressed

@export var _button: Button


func _ready() -> void:
	_button.pressed.connect(_on_pressed)
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_visibility())
	_update_visibility()


func _update_visibility() -> void:
	visible = MetaManager.is_boss_run_unlocked


func _on_pressed() -> void:
	if RunManager.is_run_active:
		return
	boss_run_pressed.emit()
