class_name BurnEffect
extends RefCounted

var remaining_duration: float = 0.0
var tick_damage: float = 0.0
var _seconds_until_next_tick: float = 0.0


## Sets burn state for a fresh application. Resets tick timer to 1.0s.
func apply(p_tick_damage: float, duration: float) -> void:
	tick_damage = p_tick_damage
	remaining_duration = duration
	_seconds_until_next_tick = 1.0


## Adds seconds to remaining_duration. No-op if amount <= 0.
func extend(seconds: float) -> void:
	if seconds <= 0.0:
		return
	remaining_duration += seconds


## Advances time by delta. Returns tick_damage if a 1-second tick fired this frame, else 0.0.
## Returns 0.0 without side effects when not active.
func process(delta: float) -> float:
	if not is_active():
		return 0.0
	remaining_duration = maxf(0.0, remaining_duration - delta)
	_seconds_until_next_tick -= delta
	if _seconds_until_next_tick <= 0.0:
		_seconds_until_next_tick += 1.0
		return tick_damage
	return 0.0


## Returns true while remaining_duration > 0.0.
func is_active() -> bool:
	return remaining_duration > 0.0
