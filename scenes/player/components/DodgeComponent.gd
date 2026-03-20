class_name DodgeComponent
extends Node

## Dash speed is derived from distance / DASH_DURATION_SEC.
## Not exposed in config — snappiness is architectural, not a balance value.
const DASH_DURATION_SEC: float = 0.1

## Reference to MovementComponent — assigned in Inspector.
@export var _movement: MovementComponent
## Reference to StatsComponent — assigned in Inspector.
@export var _stats: StatsComponent

## Emitted each frame the cooldown changes and on activation.
## Shape matches SkillComponent.cooldown_changed for HUD compatibility.
signal cooldown_changed(remaining: float, total: float)

var _cooldown: float = 0.0
var _dash_distance: float = 0.0
var _dash_speed: float = 0.0

var _is_dashing: bool = false
var _dash_remaining: float = 0.0
var _dash_direction: Vector2 = Vector2.DOWN
var _cooldown_remaining: float = 0.0


func _ready() -> void:
	var skills: Array = ResourceManager.get_skills()
	var config: Dictionary = {}
	for entry: Dictionary in skills:
		if entry.get("id", "") == "dodge":
			config = entry
			break
	if config.is_empty():
		push_warning("DodgeComponent: 'dodge' entry not found in skills.json — using defaults")
		_dash_speed = _dash_distance / DASH_DURATION_SEC
		return
	_cooldown = float(config.get("cooldown", _cooldown))
	_dash_distance = float(config.get("dash_distance", _dash_distance))
	_dash_speed = _dash_distance / DASH_DURATION_SEC


## Called by Main.gd when the HUD dodge button is pressed.
func activate() -> void:
	if not RunManager.is_run_active:
		return
	if _cooldown_remaining > 0.0:
		return
	if _is_dashing:
		return
	_dash_direction = _movement.last_direction
	_dash_remaining = _dash_distance
	_is_dashing = true
	_stats.is_invulnerable = true
	cooldown_changed.emit(_cooldown, _cooldown)


## Called internally when the dash distance is fully covered.
func _end_dash() -> void:
	_is_dashing = false
	_stats.is_invulnerable = false
	_cooldown_remaining = _cooldown
	cooldown_changed.emit(_cooldown_remaining, _cooldown)


func _physics_process(delta: float) -> void:
	_tick_cooldown(delta)
	if not _is_dashing:
		return
	var step: float = _dash_speed * delta
	_dash_remaining -= step
	get_parent().velocity = _dash_direction * _dash_speed
	get_parent().move_and_slide()
	if _dash_remaining <= 0.0:
		_end_dash()


func _tick_cooldown(delta: float) -> void:
	if _cooldown_remaining <= 0.0:
		return
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	cooldown_changed.emit(_cooldown_remaining, _cooldown)
