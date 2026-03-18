extends GutTest

const DepthTierConfigScript = preload("res://scripts/data_models/DepthTierConfig.gd")


func test_from_dict_full_populates_all_fields() -> void:
	var data: Dictionary = {
		"depth_min": 3, "depth_max": 4, "waves": [4, 2],
		"trigger_threshold": 2, "alive_cap": 4, "min_spawn_distance": 200.0,
	}
	var cfg := DepthTierConfigScript.from_dict(data) as DepthTierConfigScript
	assert_eq(cfg.depth_min, 3, "depth_min must be 3")
	assert_eq(cfg.depth_max, 4, "depth_max must be 4")
	assert_eq(cfg.waves, [4, 2], "waves must match")
	assert_eq(cfg.trigger_threshold, 2, "trigger_threshold must be 2")
	assert_eq(cfg.alive_cap, 4, "alive_cap must be 4")
	assert_almost_eq(cfg.min_spawn_distance, 200.0, 0.001, "min_spawn_distance must be 200.0")


func test_from_dict_empty_returns_safe_defaults() -> void:
	var cfg := DepthTierConfigScript.from_dict({}) as DepthTierConfigScript
	assert_eq(cfg.depth_min, 1, "depth_min default must be 1")
	assert_eq(cfg.depth_max, -1, "depth_max default must be -1")
	assert_eq(cfg.waves, [], "waves default must be empty")
	assert_eq(cfg.trigger_threshold, 2, "trigger_threshold default must be 2")
	assert_eq(cfg.alive_cap, 4, "alive_cap default must be 4")
	assert_almost_eq(cfg.min_spawn_distance, 200.0, 0.001, "min_spawn_distance default must be 200.0")


func test_from_dict_waves_stored_as_int() -> void:
	var cfg := DepthTierConfigScript.from_dict({"waves": [4, 2, 1]}) as DepthTierConfigScript
	for v: int in cfg.waves:
		assert_true(typeof(v) == TYPE_INT, "each wave value must be TYPE_INT")


func _make_tiers() -> Array:
	return [
		DepthTierConfigScript.from_dict({"depth_min": 1, "depth_max": 1,  "waves": [3]}),
		DepthTierConfigScript.from_dict({"depth_min": 2, "depth_max": 2,  "waves": [4]}),
		DepthTierConfigScript.from_dict({"depth_min": 3, "depth_max": 4,  "waves": [4, 2]}),
		DepthTierConfigScript.from_dict({"depth_min": 5, "depth_max": -1, "waves": [4, 2, 1]}),
	]


func test_find_for_depth_1_returns_tier_a() -> void:
	var tier := DepthTierConfigScript.find_for_depth(_make_tiers(), 1) as DepthTierConfigScript
	assert_not_null(tier, "tier must not be null for depth 1")
	assert_eq(tier.waves, [3], "depth 1 tier must have waves [3]")


func test_find_for_depth_3_returns_tier_c() -> void:
	var tier := DepthTierConfigScript.find_for_depth(_make_tiers(), 3) as DepthTierConfigScript
	assert_not_null(tier, "tier must not be null for depth 3")
	assert_eq(tier.waves, [4, 2], "depth 3 tier must have waves [4, 2]")


func test_find_for_depth_5_returns_unbounded_tier() -> void:
	var tier := DepthTierConfigScript.find_for_depth(_make_tiers(), 5) as DepthTierConfigScript
	assert_not_null(tier, "tier must not be null for depth 5")
	assert_eq(tier.waves, [4, 2, 1], "depth 5 tier must have waves [4, 2, 1]")


func test_find_for_depth_0_returns_null() -> void:
	var tier: Resource = DepthTierConfigScript.find_for_depth(_make_tiers(), 0)
	assert_null(tier, "depth 0 must return null — no tier covers it")
