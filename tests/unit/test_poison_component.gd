extends GutTest

const PoisonComponent = preload("res://scenes/player/components/PoisonComponent.gd")

var _poison: PoisonComponent


func before_each() -> void:
	_poison = PoisonComponent.new()
	add_child(_poison)


func after_each() -> void:
	_poison.queue_free()


## Fresh apply sets duration and modifier correctly.
func test_fresh_apply_sets_duration_and_modifier() -> void:
	_poison.apply(3.0, 0.15)
	assert_true(_poison.is_poisoned)
	assert_eq(_poison.get_damage_mult(), 1.0 - 0.15)


## Re-apply while poisoned stacks duration additively.
func test_reapply_stacks_duration() -> void:
	_poison.apply(3.0, 0.15)
	_poison.apply(3.0, 0.15)
	# Duration should be ~6.0 (no time elapsed)
	assert_almost_eq(_poison._remaining_duration, 6.0, 0.001)


## Re-apply while poisoned keeps the original modifier.
func test_reapply_keeps_modifier() -> void:
	_poison.apply(3.0, 0.15)
	_poison.apply(3.0, 0.99)  # Attempt to change modifier mid-poison
	assert_almost_eq(_poison._damage_modifier, 0.15, 0.001)


## get_damage_mult returns 1.0 when not poisoned.
func test_damage_mult_is_one_when_not_poisoned() -> void:
	assert_eq(_poison.get_damage_mult(), 1.0)


## get_damage_mult returns (1.0 - modifier) while poisoned.
func test_damage_mult_reduces_by_modifier() -> void:
	_poison.apply(5.0, 0.20)
	assert_almost_eq(_poison.get_damage_mult(), 0.80, 0.001)


## apply with duration <= 0 is a no-op.
func test_apply_with_zero_duration_is_noop() -> void:
	_poison.apply(0.0, 0.15)
	assert_false(_poison.is_poisoned)
	assert_eq(_poison.get_damage_mult(), 1.0)


## apply with negative duration is a no-op.
func test_apply_with_negative_duration_is_noop() -> void:
	_poison.apply(-1.0, 0.15)
	assert_false(_poison.is_poisoned)


## is_poisoned returns false after duration expires (simulated via direct field set).
func test_is_poisoned_false_after_expiry() -> void:
	_poison.apply(0.001, 0.15)
	# Force expiry by running physics process with large delta
	_poison._physics_process(1.0)
	assert_false(_poison.is_poisoned)
	assert_eq(_poison.get_damage_mult(), 1.0)
