extends GutTest

const SpawnPointData = preload("res://scripts/data_models/SpawnPointData.gd")


func _make_sp(pool: Array) -> SpawnPointData:
	var sp := SpawnPointData.new()
	sp.enemy_pool = pool
	sp.position = Vector2.ZERO
	sp.radius = 0.0
	return sp


func test_single_entry_100_always_returns_that_id() -> void:
	var sp := _make_sp([{"enemy_id": "forest_tank", "weight": 100}])
	for i: int in 20:
		assert_eq(sp.pick_enemy_id(), "forest_tank")


func test_empty_pool_returns_empty_string() -> void:
	var sp := _make_sp([])
	assert_eq(sp.pick_enemy_id(), "")


func test_single_entry_non_100_weight_still_always_returns_that_id() -> void:
	var sp := _make_sp([{"enemy_id": "forest_healer", "weight": 50}])
	for i: int in 20:
		assert_eq(sp.pick_enemy_id(), "forest_healer")


func test_50_50_pool_both_entries_appear_over_many_samples() -> void:
	var sp := _make_sp([
		{"enemy_id": "forest_tank", "weight": 50},
		{"enemy_id": "forest_poisoner", "weight": 50},
	])
	var counts: Dictionary = {"forest_tank": 0, "forest_poisoner": 0}
	for i: int in 200:
		var result: String = sp.pick_enemy_id()
		counts[result] = counts.get(result, 0) + 1
	assert_gt(counts["forest_tank"], 0, "forest_tank should appear at least once in 200 samples")
	assert_gt(counts["forest_poisoner"], 0, "forest_poisoner should appear at least once in 200 samples")


func test_70_10_10_10_pool_dominant_entry_wins_majority() -> void:
	var sp := _make_sp([
		{"enemy_id": "forest_tank", "weight": 70},
		{"enemy_id": "forest_healer", "weight": 10},
		{"enemy_id": "forest_poisoner", "weight": 10},
		{"enemy_id": "forest_disruptor", "weight": 10},
	])
	var tank_count: int = 0
	for i: int in 200:
		if sp.pick_enemy_id() == "forest_tank":
			tank_count += 1
	assert_gt(tank_count, 100, "forest_tank (70%%) should win majority over 200 samples")


func test_from_dict_legacy_enemy_id_sets_pool() -> void:
	var data := {"enemy_id": "slime", "position": {"x": 0.0, "y": 0.0}, "radius": 20.0}
	var sp := SpawnPointData.from_dict(data)
	assert_eq(sp.enemy_id, "slime")
	assert_eq(sp.enemy_pool.size(), 1)
	assert_eq((sp.enemy_pool[0] as Dictionary).get("enemy_id", ""), "slime")
	assert_eq((sp.enemy_pool[0] as Dictionary).get("weight", 0), 100)


func test_from_dict_pool_key_sets_pool() -> void:
	var data := {
		"pool": [
			{"enemy_id": "forest_tank", "weight": 90},
			{"enemy_id": "forest_disruptor", "weight": 10},
		],
		"position": {"x": 0.0, "y": 250.0},
		"radius": 40.0,
	}
	var sp := SpawnPointData.from_dict(data)
	assert_eq(sp.enemy_pool.size(), 2)
	assert_eq((sp.enemy_pool[0] as Dictionary).get("enemy_id", ""), "forest_tank")
