extends GutTest

const Utilities = preload("res://scripts/Utilities.gd")

# Tests for Utilities.apply_crit(damage, crit_chance, crit_multiplier).
# Uses boundary values (0.0 and 1.0) so outcomes are deterministic
# without seeding the RNG: randf() is always in [0.0, 1.0), so:
#   crit_chance = 0.0  → randf() >= 0.0 always → never crits
#   crit_chance = 1.0  → randf() < 1.0  always → always crits


func test_no_crit_when_chance_is_zero() -> void:
	# With crit_chance=0.0 the roll is always >= 0.0, so no crit ever fires.
	var result: float = Utilities.apply_crit(20.0, 0.0, 0.5)
	assert_eq(result, 20.0)


func test_always_crits_when_chance_is_one() -> void:
	# With crit_chance=1.0 the roll is always < 1.0, so every hit crits.
	var result: float = Utilities.apply_crit(20.0, 1.0, 0.5)
	assert_eq(result, 30.0)  # floorf(20.0 * 1.5)


func test_crit_formula_floors_result() -> void:
	# floorf ensures the result is an integer — 15.0 * 1.5 = 22.5 → 22.0
	var result: float = Utilities.apply_crit(15.0, 1.0, 0.5)
	assert_eq(result, 22.0)


func test_zero_multiplier_crit_equals_base() -> void:
	# crit_multiplier=0.0 → floorf(dmg * 1.0) = same value as base
	var result: float = Utilities.apply_crit(20.0, 1.0, 0.0)
	assert_eq(result, 20.0)


func test_double_damage_multiplier() -> void:
	# crit_multiplier=1.0 → floorf(dmg * 2.0) = double damage
	var result: float = Utilities.apply_crit(20.0, 1.0, 1.0)
	assert_eq(result, 40.0)


func test_no_crit_returns_exact_input() -> void:
	# Non-integer base damage passes through unchanged when no crit
	var result: float = Utilities.apply_crit(13.7, 0.0, 0.5)
	assert_eq(result, 13.7)


func test_crit_on_fractional_base_floors() -> void:
	# Base 13.7 * 1.5 = 20.55 → floorf = 20.0
	var result: float = Utilities.apply_crit(13.7, 1.0, 0.5)
	assert_eq(result, 20.0)
