extends GutTest

const StatsComponent = preload("res://scenes/player/components/StatsComponent.gd")

# Tests for the two pure static helpers that drive the regen mechanic:
#   StatsComponent.regen_tick_amount(rate, max_health, delta) -> float
#   StatsComponent.apply_regen_clamp(current, amount, max_health) -> float
#
# These functions have no autoload dependencies and no side effects, so every
# test is deterministic and self-contained.


# ---------------------------------------------------------------------------
# regen_tick_amount — heal amount per frame
# ---------------------------------------------------------------------------

func test_regen_amount_one_second_one_percent() -> void:
	# 1% of 100 HP over a full second = exactly 1.0 HP
	var result: float = StatsComponent.regen_tick_amount(0.01, 100.0, 1.0)
	assert_eq(result, 1.0)


func test_regen_amount_half_second() -> void:
	# Delta = 0.5 s: heal is halved relative to a full second
	var result: float = StatsComponent.regen_tick_amount(0.01, 100.0, 0.5)
	assert_eq(result, 0.5)


func test_regen_amount_two_relics_stacked() -> void:
	# Two common_regen relics → additive rate = 0.02 → 2.0 HP/s at max_health 100
	var result: float = StatsComponent.regen_tick_amount(0.02, 100.0, 1.0)
	assert_eq(result, 2.0)


func test_regen_amount_scales_with_max_health() -> void:
	# Picking up iron_hide boosts max_health to 115; regen amount increases proportionally.
	# Uses assert_almost_eq: 0.01 * 115.0 is not exactly 1.15 in binary float.
	var result: float = StatsComponent.regen_tick_amount(0.01, 115.0, 1.0)
	assert_almost_eq(result, 1.15, 0.0001)


func test_regen_amount_zero_rate_produces_zero() -> void:
	# No relic held → rate = 0.0 → no healing (guard in _process catches this,
	# but the formula itself also returns 0)
	var result: float = StatsComponent.regen_tick_amount(0.0, 100.0, 1.0)
	assert_eq(result, 0.0)


func test_regen_amount_frame_delta_typical() -> void:
	# Simulate a 60 fps frame: delta ≈ 0.01667 s → ~0.0167 HP healed
	var delta: float = 1.0 / 60.0
	var result: float = StatsComponent.regen_tick_amount(0.01, 100.0, delta)
	assert_almost_eq(result, 0.01 * 100.0 * delta, 0.0001)


# ---------------------------------------------------------------------------
# apply_regen_clamp — overheal prevention
# ---------------------------------------------------------------------------

func test_clamp_partial_heal_below_max() -> void:
	# 50 HP + 1 HP heal, max 100 → no clamp needed → 51 HP
	var result: float = StatsComponent.apply_regen_clamp(50.0, 1.0, 100.0)
	assert_eq(result, 51.0)


func test_clamp_heal_exactly_to_max() -> void:
	# 99 HP + 1 HP heal, max 100 → lands exactly at max → 100 HP
	var result: float = StatsComponent.apply_regen_clamp(99.0, 1.0, 100.0)
	assert_eq(result, 100.0)


func test_clamp_overheal_capped_at_max() -> void:
	# 99 HP + 5 HP heal would be 104, but max is 100 → clamped to 100
	var result: float = StatsComponent.apply_regen_clamp(99.0, 5.0, 100.0)
	assert_eq(result, 100.0)


func test_clamp_already_at_max_no_change() -> void:
	# Exactly at max HP + any heal amount → stays at max (guard in _process
	# prevents this call, but the formula itself is safe)
	var result: float = StatsComponent.apply_regen_clamp(100.0, 1.0, 100.0)
	assert_eq(result, 100.0)


func test_clamp_fractional_accumulation() -> void:
	# Many sub-frame ticks accumulate fractional HP correctly
	# e.g. after ~60 frames at 0.01667 HP/frame from 0 HP: should approach 1 HP/s
	var current: float = 0.0
	var delta: float = 1.0 / 60.0
	var amount_per_frame: float = StatsComponent.regen_tick_amount(0.01, 100.0, delta)
	for _i: int in range(60):
		current = StatsComponent.apply_regen_clamp(current, amount_per_frame, 100.0)
	# 60 frames × (0.01 × 100 / 60) ≈ 1.0 HP — allow small float error
	assert_almost_eq(current, 1.0, 0.01)


func test_clamp_with_boosted_max_health() -> void:
	# After picking up iron_hide: max_health = 115. Overheal still capped correctly.
	var result: float = StatsComponent.apply_regen_clamp(114.0, 2.0, 115.0)
	assert_eq(result, 115.0)
