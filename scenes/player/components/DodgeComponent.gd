class_name DodgeComponent
extends Node

## Dash speed is derived from distance / DASH_DURATION_SEC.
## Not exposed in config — snappiness is architectural, not a balance value.
const DASH_DURATION_SEC: float = 0.1

## Reference to MovementComponent — assigned in Inspector.
@export var _movement: MovementComponent
## Reference to StatsComponent — assigned in Inspector.
@export var _stats: StatsComponent
## Reference to RootComponent — assigned in Inspector.
@export var _root: RootComponent

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
	if _root != null and _root.is_rooted:
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
	var body := get_parent() as CharacterBody2D
	body.velocity = Vector2.ZERO
	_cooldown_remaining = _cooldown
	cooldown_changed.emit(_cooldown_remaining, _cooldown)


func _physics_process(delta: float) -> void:
	_tick_cooldown(delta)
	if not _is_dashing:
		return

	var body := get_parent() as CharacterBody2D
	var step := _dash_speed * delta
	var motion := _dash_direction * step

	var collision := body.move_and_collide(motion)
	if collision:
		_end_dash()
		return

	_dash_remaining -= step
	if _dash_remaining <= 0.0:
		_end_dash()

func _tick_cooldown(delta: float) -> void:
	if _cooldown_remaining <= 0.0:
		return
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	cooldown_changed.emit(_cooldown_remaining, _cooldown)
