class_name StatsComponent
extends Node

@export var max_health: float = 10.0
@export var is_player: bool = false

var current_health: float
var damage_reduction: float = 0.0
var _base_max_health: float = 0.0
var _damage_reduction_cap: float = 0.5

signal health_changed(new_health: float, max_health: float)
signal died


func _ready() -> void:
	if is_player:
		var stats: Dictionary = ResourceManager.get_player_config().get("stats", {})
		_base_max_health = float(stats.get("max_health", max_health))
		_damage_reduction_cap = float(stats.get("damage_reduction_cap", 0.5))
		max_health = _base_max_health
		RelicManager.relic_applied.connect(_on_relic_applied)
		RelicManager.relics_cleared.connect(func() -> void: _on_relic_applied(""))
	else:
		_base_max_health = max_health
	assert(max_health > 0.0, "StatsComponent: max_health must be greater than 0")
	current_health = max_health


## Returns the amount of damage after applying a damage_reduction multiplier.
## Pure math — no side effects. Testable without autoloads.
static func compute_reduced_damage(amount: float, reduction: float) -> float:
	return amount * (1.0 - reduction)


func take_damage(amount: float) -> void:
	var effective: float = compute_reduced_damage(amount, damage_reduction)
	current_health = maxf(current_health - effective, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health == 0.0:
		died.emit()


## Applies damage bypassing damage_reduction (used for burn DoT).
func take_damage_raw(amount: float) -> void:
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health == 0.0:
		died.emit()


func heal(amount: float) -> void:
	current_health = apply_regen_clamp(current_health, amount, max_health)
	health_changed.emit(current_health, max_health)


func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Returns the raw HP amount regenerated in one frame.
## Pure math — no side effects. Testable without autoloads.
static func regen_tick_amount(rate: float, max_health: float, delta: float) -> float:
	return rate * max_health * delta


## Returns the new current_health after applying a regen heal, clamped to max_health.
## Pure math — no side effects. Testable without autoloads.
static func apply_regen_clamp(current: float, amount: float, max_health: float) -> float:
	return minf(current + amount, max_health)


func _process(delta: float) -> void:
	if not is_player:
		return
	if not RunManager.is_run_active:
		return
	var rate: float = RelicManager.get_stat_addend("hp_regen")
	if rate <= 0.0:
		return
	if current_health >= max_health:
		return
	heal(regen_tick_amount(rate, max_health, delta))


func _on_relic_applied(_relic_id: String) -> void:
	var new_max: float = _base_max_health * RelicManager.get_stat_mult("max_health")
	if not is_equal_approx(new_max, max_health):
		var ratio: float = current_health / max_health
		max_health = new_max
		current_health = clampf(new_max * ratio, 1.0, new_max)
		health_changed.emit(current_health, max_health)
	damage_reduction = minf(_damage_reduction_cap, RelicManager.get_stat_addend("damage_reduction"))
