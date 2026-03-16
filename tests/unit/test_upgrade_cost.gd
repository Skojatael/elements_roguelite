extends GutTest

const MetaManagerImpl = preload("res://scripts/managers/MetaManager.gd")

var _impl: MetaManagerImpl


func before_each() -> void:
	_impl = MetaManagerImpl.new()


func test_cost_at_level_0_equals_base() -> void:
	assert_eq(_impl.get_upgrade_cost(0, 50, 1.2), 50, "level 0 should return base cost unchanged")


func test_cost_at_level_1() -> void:
	assert_eq(_impl.get_upgrade_cost(1, 50, 1.2), 60, "floor(50 * 1.2) == 60")


func test_cost_at_level_2() -> void:
	assert_eq(_impl.get_upgrade_cost(2, 50, 1.2), 72, "floor(60 * 1.2) == 72")


func test_cost_levels_3_through_9() -> void:
	var expected: Array = [[3, 86], [4, 103], [5, 123], [6, 147], [7, 176], [8, 211], [9, 253]]
	for pair: Variant in expected:
		var level: int = (pair as Array)[0]
		var cost: int = (pair as Array)[1]
		assert_eq(
			_impl.get_upgrade_cost(level, 50, 1.2),
			cost,
			"level {l} should cost {c}".format({"l": level, "c": cost})
		)


func test_cost_at_level_0_any_base() -> void:
	assert_eq(_impl.get_upgrade_cost(0, 100, 1.2), 100, "level 0 always returns base cost regardless of scale")


func test_cost_zero_base_always_zero() -> void:
	assert_eq(_impl.get_upgrade_cost(5, 0, 1.2), 0, "base_cost=0 produces 0 at any level")


func test_cost_scale_one_never_grows() -> void:
	assert_eq(_impl.get_upgrade_cost(0, 50, 1.0), 50, "scale=1.0 at level 0 returns base cost")
	assert_eq(_impl.get_upgrade_cost(5, 50, 1.0), 50, "scale=1.0 at level 5 still returns base cost unchanged")
