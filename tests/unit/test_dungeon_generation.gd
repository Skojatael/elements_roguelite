extends GutTest

const DungeonGeneratorClass = preload("res://scripts/dungeon/DungeonGenerator.gd")

const STUB_CONFIG: Dictionary = {
	"combat_room_pool": ["CombatRoom01", "CombatRoom02"],
	"base_room_count": 9,
	"difficulty_scale": 0.12,
	"expansion_room_count": 4,
}



func _all_reachable(gen: DungeonGenerator) -> bool:
	var visited: Dictionary = {}
	var queue: Array = [gen.start_room_id]
	while not queue.is_empty():
		var id: String = queue.pop_back()
		if visited.has(id):
			continue
		visited[id] = true
		for n: String in gen.neighbours_by_id.get(id, []):
			queue.append(n)
	return visited.size() == gen.rooms_by_id.size()


func test_room_count_base() -> void:
	var expansion: bool = false
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, expansion)
	assert_eq(gen.rooms_by_id.size(), 9, "base layout must contain exactly 9 rooms")


func test_room_count_with_expansion() -> void:
	var expansion: bool = true
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, expansion)
	assert_eq(gen.rooms_by_id.size(), 13, "expanded layout must contain exactly 13 rooms")


func test_start_room_always_in_rooms_by_id() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	assert_true(gen.rooms_by_id.has(gen.start_room_id), "start_room_id must be present in rooms_by_id")


func test_start_room_id_is_room_6_6() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	assert_eq(gen.start_room_id, "room_6_6", "start_room_id must always equal 'room_6_6'")


func test_connectivity_run_1() -> void:
	seed(11111)
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	assert_true(_all_reachable(gen), "all rooms must be reachable from start (seed 11111)")


func test_connectivity_run_2() -> void:
	seed(22222)
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	assert_true(_all_reachable(gen), "all rooms must be reachable from start (seed 22222)")


func test_connectivity_run_3() -> void:
	seed(33333)
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	assert_true(_all_reachable(gen), "all rooms must be reachable from start (seed 33333)")


func test_connectivity_run_4() -> void:
	seed(44444)
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	assert_true(_all_reachable(gen), "all rooms must be reachable from start (seed 44444)")


func test_connectivity_run_5() -> void:
	seed(55555)
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	assert_true(_all_reachable(gen), "all rooms must be reachable from start (seed 55555)")


func test_neighbour_symmetry() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	for room_id: String in gen.neighbours_by_id:
		for n: String in gen.neighbours_by_id[room_id]:
			assert_true(
				gen.neighbours_by_id[n].has(room_id),
				"neighbour relationship must be symmetric: {a}↔{b}".format({"a": room_id, "b": n})
			)


# --- Depth ---

func test_start_room_has_depth_zero() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	var depth: int = gen.rooms_by_id[gen.start_room_id]["depth"]
	assert_eq(depth, 0, "start room must have depth 0")


func test_all_rooms_depth_equals_manhattan_distance() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	for room_id: String in gen.rooms_by_id:
		var data: Dictionary = gen.rooms_by_id[room_id]
		var grid_pos: Vector2i = data["grid_pos"]
		var expected_depth: int = abs(grid_pos.x - 6) + abs(grid_pos.y - 6)
		assert_eq(data["depth"], expected_depth,
			"room {id} depth must equal Manhattan distance from center".format({"id": room_id}))


# --- Difficulty multiplier ---

func test_difficulty_mult_matches_depth() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	for room_id: String in gen.rooms_by_id:
		var data: Dictionary = gen.rooms_by_id[room_id]
		var expected: float = 1.0 + 0.12 * float(data["depth"])
		assert_almost_eq(data["difficulty_mult"], expected, 0.0001,
			"room {id} difficulty_mult must equal 1.0 + 0.12 * depth".format({"id": room_id}))


# --- World position ---

func test_start_room_world_pos_is_origin() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	var world_pos: Vector2 = gen.rooms_by_id[gen.start_room_id]["world_pos"]
	assert_eq(world_pos, Vector2(0.0, 0.0), "center room world_pos must be (0, 0)")


func test_world_pos_matches_grid_offset() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	for room_id: String in gen.rooms_by_id:
		var data: Dictionary = gen.rooms_by_id[room_id]
		var grid_pos: Vector2i = data["grid_pos"]
		var expected_x: float = float(grid_pos.x - 6) * 2000.0
		var expected_y: float = float(grid_pos.y - 6) * 1200.0
		assert_almost_eq(data["world_pos"].x, expected_x, 0.001,
			"room {id} world_pos.x incorrect".format({"id": room_id}))
		assert_almost_eq(data["world_pos"].y, expected_y, 0.001,
			"room {id} world_pos.y incorrect".format({"id": room_id}))


# --- Elite promotion ---

func test_elite_rooms_exist_at_even_depths() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	var rooms_by_depth: Dictionary = {}
	for room_id: String in gen.rooms_by_id:
		var d: int = gen.rooms_by_id[room_id]["depth"]
		if not rooms_by_depth.has(d):
			rooms_by_depth[d] = []
		rooms_by_depth[d].append(room_id)
	for d: int in [2, 4, 6, 8]:
		if not rooms_by_depth.has(d):
			continue
		var elite_count: int = 0
		for room_id: String in rooms_by_depth[d]:
			if gen.rooms_by_id[room_id]["room_type_id"] == "EliteRoom01":
				elite_count += 1
		assert_eq(elite_count, 1,
			"exactly one EliteRoom01 must be promoted at depth {d}".format({"d": d}))


func test_no_elite_rooms_at_odd_depths() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	for room_id: String in gen.rooms_by_id:
		var data: Dictionary = gen.rooms_by_id[room_id]
		if data["depth"] % 2 != 0:
			assert_ne(data["room_type_id"], "EliteRoom01",
				"room at odd depth {d} must not be EliteRoom01".format({"d": data["depth"]}))


# --- Expansion depth constraint ---

func test_expansion_rooms_strictly_deeper_than_base_max() -> void:
	seed(12345)
	var gen_base: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen_base._generate_with(STUB_CONFIG, false)
	var base_max_depth: int = 0
	for data: Variant in gen_base.rooms_by_id.values():
		base_max_depth = maxi(base_max_depth, (data as Dictionary)["depth"])

	seed(12345)
	var gen_exp: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen_exp._generate_with(STUB_CONFIG, true)
	for room_id: String in gen_exp.rooms_by_id:
		if gen_base.rooms_by_id.has(room_id):
			continue
		var d: int = gen_exp.rooms_by_id[room_id]["depth"]
		assert_gt(d, base_max_depth,
			"expansion room {id} depth {d} must exceed base max depth {m}".format(
				{"id": room_id, "d": d, "m": base_max_depth}))


# --- Expansion connectivity ---

func test_expansion_connectivity_run_1() -> void:
	seed(11111)
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, true)
	assert_true(_all_reachable(gen), "all 13 rooms must be reachable from start (seed 11111)")


func test_expansion_connectivity_run_2() -> void:
	seed(22222)
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, true)
	assert_true(_all_reachable(gen), "all 13 rooms must be reachable from start (seed 22222)")


func test_expansion_connectivity_run_3() -> void:
	seed(33333)
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, true)
	assert_true(_all_reachable(gen), "all 13 rooms must be reachable from start (seed 33333)")
