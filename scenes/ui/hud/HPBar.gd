class_name HPBar
extends Control

@export var _bg: ColorRect
@export var _fill: ColorRect
@export var _label: Label


func setup(stats: StatsComponent) -> void:
	stats.health_changed.connect(_on_health_changed)
	_on_health_changed(stats.current_health, stats.max_health)


func _on_health_changed(new_health: float, max_hp: float) -> void:
	if max_hp <= 0.0:
		return
	var ratio: float = clampf(new_health / max_hp, 0.0, 1.0)
	_fill.size.x = _bg.size.x * ratio
	_label.text = "{cur} / {max}".format({"cur": floori(new_health), "max": floori(max_hp)})
