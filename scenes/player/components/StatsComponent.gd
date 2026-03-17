class_name StatsComponent
extends Node

@export var max_health: float = 10.0
@export var is_player: bool = false

var current_health: float
var _base_max_health: float = 0.0

signal health_changed(new_health: float, max_health: float)
signal died


func _ready() -> void:
	if is_player:
		var stats: Dictionary = ResourceManager.get_player_config().get("stats", {})
		_base_max_health = float(stats.get("max_health", max_health))
		max_health = _base_max_health
		RelicManager.relic_applied.connect(_on_relic_applied)
		RelicManager.relics_cleared.connect(func() -> void: _on_relic_applied(""))
	else:
		_base_max_health = max_health
	assert(max_health > 0.0, "StatsComponent: max_health must be greater than 0")
	current_health = max_health


func take_damage(amount: float) -> void:
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health == 0.0:
		died.emit()


func heal(amount: float) -> void:
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func _on_relic_applied(_relic_id: String) -> void:
	var new_max: float = _base_max_health * RelicManager.get_stat_mult("max_health")
	if is_equal_approx(new_max, max_health):
		return
	var ratio: float = current_health / max_health
	max_health = new_max
	current_health = clampf(new_max * ratio, 1.0, new_max)
	health_changed.emit(current_health, max_health)
