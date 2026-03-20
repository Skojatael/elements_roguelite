extends GutTest

const StatsComponent = preload("res://scenes/player/components/StatsComponent.gd")


# compute_reduced_damage — pure static, no autoloads.

func test_compute_reduced_damage_zero_reduction() -> void:
	var result: float = StatsComponent.compute_reduced_damage(10.0, 0.0)
	assert_eq(result, 10.0)


func test_compute_reduced_damage_full_reduction() -> void:
	var result: float = StatsComponent.compute_reduced_damage(10.0, 1.0)
	assert_eq(result, 0.0)


func test_compute_reduced_damage_partial_reduction() -> void:
	var result: float = StatsComponent.compute_reduced_damage(10.0, 0.5)
	assert_eq(result, 5.0)


# regen_tick_amount — pure static.

func test_regen_tick_amount_basic() -> void:
	var result: float = StatsComponent.regen_tick_amount(0.1, 100.0, 1.0)
	assert_almost_eq(result, 10.0, 0.001)


func test_regen_tick_amount_zero_rate() -> void:
	var result: float = StatsComponent.regen_tick_amount(0.0, 100.0, 1.0)
	assert_eq(result, 0.0)


# apply_regen_clamp — pure static.

func test_apply_regen_clamp_does_not_exceed_max() -> void:
	var result: float = StatsComponent.apply_regen_clamp(95.0, 10.0, 100.0)
	assert_eq(result, 100.0)


func test_apply_regen_clamp_below_max() -> void:
	var result: float = StatsComponent.apply_regen_clamp(80.0, 5.0, 100.0)
	assert_almost_eq(result, 85.0, 0.001)
