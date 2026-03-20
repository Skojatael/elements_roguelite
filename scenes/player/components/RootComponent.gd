class_name RootComponent
extends Node

var _root_remaining: float = 0.0

var is_rooted: bool:
	get: return _root_remaining > 0.0


func apply_root(duration: float) -> void:
	_root_remaining = maxf(_root_remaining, duration)


func _physics_process(delta: float) -> void:
	if _root_remaining <= 0.0:
		return
	_root_remaining = maxf(0.0, _root_remaining - delta)
