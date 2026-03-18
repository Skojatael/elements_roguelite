extends GutTest

const WaveConfigScript = preload("res://scripts/data_models/WaveConfig.gd")


func test_full_dict_populates_all_fields() -> void:
	var data: Dictionary = {
		"waves": [3, 2, 1],
		"trigger_threshold": 1,
		"alive_cap": 4,
		"min_spawn_distance": 200.0,
	}
	var cfg: WaveConfig = WaveConfigScript.from_dict(data)
	assert_eq(cfg.waves, [3, 2, 1], "waves must match input array")
	assert_eq(cfg.trigger_threshold, 1, "trigger_threshold must be 1")
	assert_eq(cfg.alive_cap, 4, "alive_cap must be 4")
	assert_almost_eq(cfg.min_spawn_distance, 200.0, 0.001, "min_spawn_distance must be 200.0")


func test_empty_dict_returns_safe_defaults() -> void:
	var cfg: WaveConfig = WaveConfigScript.from_dict({})
	assert_eq(cfg.waves, [], "waves must default to empty array")
	assert_eq(cfg.trigger_threshold, 1, "trigger_threshold must default to 1")
	assert_eq(cfg.alive_cap, 4, "alive_cap must default to 4")
	assert_almost_eq(cfg.min_spawn_distance, 200.0, 0.001, "min_spawn_distance must default to 200.0")


func test_waves_values_stored_as_int() -> void:
	var data: Dictionary = {"waves": [3, 2, 1]}
	var cfg: WaveConfig = WaveConfigScript.from_dict(data)
	for v: int in cfg.waves:
		assert_true(typeof(v) == TYPE_INT, "each wave value must be TYPE_INT")


func test_waves_sum_matches_expected_total() -> void:
	var data: Dictionary = {"waves": [3, 2, 1]}
	var cfg: WaveConfig = WaveConfigScript.from_dict(data)
	var total: int = 0
	for v: int in cfg.waves:
		total += v
	assert_eq(total, 6, "sum of default waves must be 6")


func test_custom_values_respected() -> void:
	var data: Dictionary = {
		"waves": [5, 3],
		"trigger_threshold": 2,
		"alive_cap": 6,
		"min_spawn_distance": 150.0,
	}
	var cfg: WaveConfig = WaveConfigScript.from_dict(data)
	assert_eq(cfg.waves, [5, 3], "custom waves must be stored")
	assert_eq(cfg.trigger_threshold, 2, "custom trigger_threshold must be stored")
	assert_eq(cfg.alive_cap, 6, "custom alive_cap must be stored")
	assert_almost_eq(cfg.min_spawn_distance, 150.0, 0.001, "custom min_spawn_distance must be stored")
