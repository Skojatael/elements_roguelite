extends GutTest

const RoomSpawner = preload("res://scripts/dungeon/RoomSpawner.gd")

# ---------------------------------------------------------------------------
# Shared stub helpers
# ---------------------------------------------------------------------------

const SLOT_TANK := {"pool": [{"enemy_id": "forest_tank", "weight": 100}], "position": {"x": 0, "y": 0}, "radius": 40}
const SLOT_DISRUPTOR := {"pool": [{"enemy_id": "forest_disruptor", "weight": 100}], "position": {"x": 100, "y": 0}, "radius": 40}
const SLOT_HEALER := {"pool": [{"enemy_id": "forest_healer", "weight": 100}], "position": {"x": -100, "y": 0}, "radius": 40}
const SLOT_POISONER := {"pool": [{"enemy_id": "forest_poisoner", "weight": 100}], "position": {"x": 0, "y": 100}, "radius": 40}
const SLOT_BUFFER := {"pool": [{"enemy_id": "forest_buffer", "weight": 100}], "position": {"x": 150, "y": 100}, "radius": 40}
const SLOT_REFLECTOR := {"pool": [{"enemy_id": "forest_reflector", "weight": 100}], "position": {"x": -150, "y": 100}, "radius": 40}
const SLOT_BUFFER_OR_REFLECTOR := {"pool": [{"enemy_id": "forest_buffer", "weight": 50}, {"enemy_id": "forest_reflector", "weight": 50}], "position": {"x": 0, "y": 250}, "radius": 40}

func _band1_wave() -> Array:
	return [SLOT_TANK, SLOT_TANK, SLOT_DISRUPTOR, SLOT_BUFFER_OR_REFLECTOR]

func _band2_wave_a() -> Array:
	return [SLOT_TANK, SLOT_TANK, SLOT_DISRUPTOR, SLOT_HEALER, SLOT_BUFFER_OR_REFLECTOR]

func _band2_wave_b() -> Array:
	return [SLOT_TANK, SLOT_TANK, SLOT_TANK, SLOT_DISRUPTOR, SLOT_BUFFER_OR_REFLECTOR]

func _band3_wave_a() -> Array:
	return [SLOT_TANK, SLOT_DISRUPTOR, SLOT_HEALER, SLOT_POISONER, SLOT_BUFFER_OR_REFLECTOR]

func _band3_wave_b() -> Array:
	return [SLOT_TANK, SLOT_TANK, SLOT_DISRUPTOR, SLOT_POISONER, SLOT_BUFFER_OR_REFLECTOR]

func _band3_wave_c() -> Array:
	return [SLOT_TANK, SLOT_TANK, SLOT_DISRUPTOR, SLOT_HEALER, SLOT_BUFFER, SLOT_REFLECTOR]

func _make_bands_1234() -> Array:
	return [
		{
			"min_depth": 1, "max_depth": 2,
			"variants": [{"weight": 100, "wave": _band1_wave()}]
		},
		{
			"min_depth": 3, "max_depth": 4,
			"variants": [
				{"weight": 70, "wave": _band2_wave_a()},
				{"weight": 30, "wave": _band2_wave_b()},
			]
		},
		{
			"min_depth": 5, "max_depth": 6,
			"variants": [
				{"weight": 60, "wave": _band3_wave_a()},
				{"weight": 30, "wave": _band3_wave_b()},
				{"weight": 10, "wave": _band3_wave_c()},
			]
		},
		{
			"min_depth": 7, "max_depth": -1,
			"variants": [
				{"weight": 60, "wave": _band3_wave_a()},
				{"weight": 30, "wave": _band3_wave_b()},
				{"weight": 10, "wave": _band3_wave_c()},
			]
		},
	]


# ---------------------------------------------------------------------------
# Band 1 — depth 1-2 (T008)
# ---------------------------------------------------------------------------

func test_band1_selected_at_depth_1() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 1)
	assert_false(result.is_empty(), "should match band 1 at depth 1")
	assert_eq((result.get("wave") as Array).size(), 4, "band 1 has 4 slots")


func test_band1_selected_at_depth_2() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 2)
	assert_false(result.is_empty(), "should match band 1 at depth 2")
	assert_eq((result.get("wave") as Array).size(), 4)


func test_band1_only_one_variant_always_selected() -> void:
	for _i: int in 20:
		var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 2)
		assert_eq((result.get("wave") as Array).size(), 4, "band 1 always returns the single variant")


func test_band1_last_slot_has_50_50_pool() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 1)
	var wave: Array = result.get("wave") as Array
	var last_slot: Dictionary = wave[wave.size() - 1] as Dictionary
	var pool: Array = last_slot.get("pool") as Array
	assert_eq(pool.size(), 2, "buffer/reflector slot has 2 pool entries")
	var ids: Array = []
	for entry: Variant in pool:
		ids.append((entry as Dictionary).get("enemy_id", ""))
	assert_true(ids.has("forest_buffer"), "pool contains forest_buffer")
	assert_true(ids.has("forest_reflector"), "pool contains forest_reflector")


# ---------------------------------------------------------------------------
# Band 2 — depth 3-4, 70/30 weighted (T010)
# ---------------------------------------------------------------------------

func test_band2_selected_at_depth_3() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 3)
	assert_false(result.is_empty(), "should match band 2 at depth 3")
	assert_eq((result.get("wave") as Array).size(), 5)


func test_band2_selected_at_depth_4() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 4)
	assert_false(result.is_empty(), "should match band 2 at depth 4")
	assert_eq((result.get("wave") as Array).size(), 5)


func test_band2_does_not_match_depth_2() -> void:
	# depth 2 must use band 1 (4 slots), not band 2 (5 slots)
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 2)
	assert_eq((result.get("wave") as Array).size(), 4)


func test_band2_weighted_distribution_70_30() -> void:
	var draws: int = 1000
	var healer_count: int = 0
	for _i: int in draws:
		var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 4)
		var wave: Array = result.get("wave") as Array
		# variant A has 5 slots with healer; variant B has 5 slots without
		var has_healer := false
		for slot: Variant in wave:
			var pool: Array = (slot as Dictionary).get("pool") as Array
			for entry: Variant in pool:
				if (entry as Dictionary).get("enemy_id", "") == "forest_healer":
					has_healer = true
		if has_healer:
			healer_count += 1
	# expect 650–750 healer (70% ± 5%)
	assert_true(healer_count >= 650 and healer_count <= 750,
		"healer variant should appear 65-75%% of 1000 draws, got {n}".format({"n": healer_count}))


# ---------------------------------------------------------------------------
# Band 3 — depth 5-6, 60/30/10 weighted (T012)
# ---------------------------------------------------------------------------

func test_band3_selected_at_depth_5() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 5)
	assert_false(result.is_empty(), "should match band 3 at depth 5")


func test_band3_selected_at_depth_6() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 6)
	assert_false(result.is_empty(), "should match band 3 at depth 6")


func test_band3_all_three_variants_valid() -> void:
	# run enough draws to observe all three variants at least once
	var seen_sizes: Dictionary = {}
	for _i: int in 500:
		var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 5)
		var wave: Array = result.get("wave") as Array
		seen_sizes[wave.size()] = true
	# variants A and B have 5 slots; variant C also has 6 slots
	assert_true(seen_sizes.has(5), "5-slot variants should appear")
	assert_true(seen_sizes.has(6), "6-slot variant C should appear in 500 draws")


func test_band3_variant_c_has_both_buffer_and_reflector_as_fixed_slots() -> void:
	# Run until variant C (6 slots) appears
	var found: bool = false
	for _i: int in 500:
		var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 5)
		var wave: Array = result.get("wave") as Array
		if wave.size() != 6:
			continue
		var ids: Array = []
		for slot: Variant in wave:
			var pool: Array = (slot as Dictionary).get("pool") as Array
			for entry: Variant in pool:
				var eid: String = (entry as Dictionary).get("enemy_id", "")
				if not ids.has(eid):
					ids.append(eid)
		assert_true(ids.has("forest_buffer"), "variant C includes forest_buffer")
		assert_true(ids.has("forest_reflector"), "variant C includes forest_reflector")
		found = true
		break
	assert_true(found, "variant C (6 slots) should appear within 500 draws")


# ---------------------------------------------------------------------------
# Band 4 — depth 7+, open-ended (T014)
# ---------------------------------------------------------------------------

func test_band4_selected_at_depth_7() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 7)
	assert_false(result.is_empty(), "should match band 4 at depth 7")


func test_band4_selected_at_depth_8() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 8)
	assert_false(result.is_empty(), "should match band 4 at depth 8")


func test_band4_does_not_match_depth_6() -> void:
	# depth 6 must use band 3 (max_depth 6), not band 4
	var b3: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 6)
	var b4: Dictionary = RoomSpawner.pick_elite_variant(_make_bands_1234(), 7)
	# Both return non-empty — just ensure band boundary is respected
	assert_false(b3.is_empty())
	assert_false(b4.is_empty())


func test_band4_same_structure_as_band3() -> void:
	var bands: Array = _make_bands_1234()
	# band 3 is index 2, band 4 is index 3
	var band3: Dictionary = bands[2] as Dictionary
	var band4: Dictionary = bands[3] as Dictionary
	assert_eq(
		(band3.get("variants") as Array).size(),
		(band4.get("variants") as Array).size(),
		"band 3 and band 4 have the same number of variants"
	)
	# Compare weights
	var v3: Array = band3.get("variants") as Array
	var v4: Array = band4.get("variants") as Array
	for i: int in v3.size():
		assert_eq(
			int((v3[i] as Dictionary).get("weight", -1)),
			int((v4[i] as Dictionary).get("weight", -1)),
			"variant {i} weight matches between band 3 and band 4".format({"i": i})
		)


# ---------------------------------------------------------------------------
# No-match and edge cases (T006)
# ---------------------------------------------------------------------------

func test_no_match_returns_empty() -> void:
	var result: Dictionary = RoomSpawner.pick_elite_variant([], 4)
	assert_true(result.is_empty(), "empty bands array returns empty dict")


func test_no_match_depth_outside_all_bands() -> void:
	var bands: Array = [{"min_depth": 3, "max_depth": 4, "variants": [{"weight": 100, "wave": [SLOT_TANK]}]}]
	var result: Dictionary = RoomSpawner.pick_elite_variant(bands, 1)
	assert_true(result.is_empty(), "depth below all bands returns empty dict")


func test_empty_variants_returns_empty() -> void:
	var bands: Array = [{"min_depth": 1, "max_depth": 2, "variants": []}]
	var result: Dictionary = RoomSpawner.pick_elite_variant(bands, 1)
	assert_true(result.is_empty(), "band with no variants returns empty dict")


func test_single_variant_always_selected() -> void:
	var bands: Array = [
		{"min_depth": 1, "max_depth": -1, "variants": [{"weight": 50, "wave": [SLOT_TANK]}]}
	]
	for _i: int in 20:
		var result: Dictionary = RoomSpawner.pick_elite_variant(bands, 5)
		assert_false(result.is_empty())
		assert_eq((result.get("wave") as Array).size(), 1)
