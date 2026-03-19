extends GutTest

const StatsComponent = preload("res://scenes/player/components/StatsComponent.gd")

var _stats: StatsComponent


func before_each() -> void:
	_stats = StatsComponent.new()
	_stats.is_player = false
	_stats.max_health = 100.0
	add_child_autoqfree(_stats)


# --- compute_reduced_damage (static helper) ---

func test_no_reduction() -> void:
	assert_almost_eq(
		StatsComponent.compute_reduced_damage(100.0, 0.0),
		100.0, 0.0001,
		"zero reduction must return full amount"
	)


func test_ten_percent_reduction() -> void:
	assert_almost_eq(
		StatsComponent.compute_reduced_damage(100.0, 0.10),
		90.0, 0.0001,
		"10% reduction must return 90"
	)


func test_fifty_percent_reduction() -> void:
	assert_almost_eq(
		StatsComponent.compute_reduced_damage(100.0, 0.50),
		50.0, 0.0001,
		"50% reduction must return 50"
	)


func test_zero_amount() -> void:
	assert_almost_eq(
		StatsComponent.compute_reduced_damage(0.0, 0.10),
		0.0, 0.0001,
		"zero damage input must return 0 regardless of reduction"
	)


# --- take_damage (mitigated) ---

func test_take_damage_applies_reduction() -> void:
	_stats.damage_reduction = 0.20
	_stats.take_damage(50.0)
	assert_almost_eq(_stats.current_health, 60.0, 0.0001,
		"take_damage with 20% DR on 50 damage must leave 60 HP")


func test_take_damage_no_reduction_unchanged() -> void:
	_stats.damage_reduction = 0.0
	_stats.take_damage(30.0)
	assert_almost_eq(_stats.current_health, 70.0, 0.0001,
		"take_damage with 0% DR must behave as before")


func test_health_floor_at_zero() -> void:
	_stats.damage_reduction = 0.0
	_stats.take_damage(200.0)
	assert_almost_eq(_stats.current_health, 0.0, 0.0001,
		"current_health must never go below 0")


# --- take_damage_raw (unmitigated) ---

func test_take_damage_raw_ignores_reduction() -> void:
	_stats.damage_reduction = 0.50
	_stats.take_damage_raw(50.0)
	assert_almost_eq(_stats.current_health, 50.0, 0.0001,
		"take_damage_raw must ignore damage_reduction entirely")


func test_take_damage_raw_no_reduction_full_amount() -> void:
	_stats.damage_reduction = 0.0
	_stats.take_damage_raw(40.0)
	assert_almost_eq(_stats.current_health, 60.0, 0.0001,
		"take_damage_raw with 0 DR must apply full amount")


func test_take_damage_raw_floor_at_zero() -> void:
	_stats.damage_reduction = 0.50
	_stats.take_damage_raw(300.0)
	assert_almost_eq(_stats.current_health, 0.0, 0.0001,
		"take_damage_raw must still floor at 0")


# --- additive stacking (US3) ---

func test_additive_stacking_two_sources() -> void:
	var combined: float = 0.10 + 0.10
	assert_almost_eq(
		StatsComponent.compute_reduced_damage(100.0, combined),
		80.0, 0.0001,
		"two 10% sources must add to 20% total reduction"
	)


func test_additive_stacking_three_sources() -> void:
	var combined: float = 0.10 + 0.10 + 0.20
	assert_almost_eq(
		StatsComponent.compute_reduced_damage(100.0, combined),
		60.0, 0.0001,
		"three sources (10+10+20) must add to 40% total reduction"
	)


func test_cap_enforced_at_fifty_percent() -> void:
	var raw_total: float = 0.10 * 6.0  # six relics = 0.60, over cap
	var capped: float = minf(0.5, raw_total)
	assert_almost_eq(
		StatsComponent.compute_reduced_damage(100.0, capped),
		50.0, 0.0001,
		"six 10% relics must be capped at 50% reduction"
	)
