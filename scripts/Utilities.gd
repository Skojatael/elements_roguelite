class_name Utilities
extends Node


## Returns damage after a per-hit crit roll.
## crit_chance: probability in [0.0, 1.0]. crit_multiplier: bonus additive to 1.0.
## On crit: floorf(damage * (1.0 + crit_multiplier)). On miss: damage unchanged.
static func apply_crit(damage: float, crit_chance: float, crit_multiplier: float) -> float:
	if randf() >= crit_chance:
		return damage
	return floorf(damage * (1.0 + crit_multiplier))


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass
