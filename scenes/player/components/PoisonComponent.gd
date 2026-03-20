class_name PoisonComponent
extends Node

## Tracks poison status for a combatant (player or enemy).
## When poisoned, get_damage_mult() returns a value < 1.0 that callers
## multiply against their outgoing attack damage.
##
## Duration stacks additively on re-application; modifier is set only on a
## fresh application (i.e. when not already poisoned).
##
## Used by both Player.tscn (as a permanent child node) and Enemy.gd
## (instantiated in _ready() via PoisonComponent.new() + add_child()).

var _remaining_duration: float = 0.0
var _damage_modifier: float = 0.0

var is_poisoned: bool:
	get: return _remaining_duration > 0.0


## Applies poison. If already poisoned, stacks duration additively and keeps
## the existing modifier. If not poisoned, sets both duration and modifier.
## No-op when duration <= 0.
func apply(duration: float, modifier: float) -> void:
	if duration <= 0.0:
		return
	if is_poisoned:
		_remaining_duration += duration
		return
	_remaining_duration = duration
	_damage_modifier = modifier


## Returns the outgoing-damage multiplier for the poisoned entity.
## Returns (1.0 - damage_modifier) while poisoned; 1.0 when not poisoned.
func get_damage_mult() -> float:
	if not is_poisoned:
		return 1.0
	return 1.0 - _damage_modifier


func _physics_process(delta: float) -> void:
	if _remaining_duration <= 0.0:
		return
	_remaining_duration = maxf(0.0, _remaining_duration - delta)
