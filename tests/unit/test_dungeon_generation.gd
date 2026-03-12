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
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	assert_eq(gen.rooms_by_id.size(), 9, "base layout must contain exactly 9 rooms")


func test_start_room_always_in_rooms_by_id() -> void:
	var gen: DungeonGenerator = add_child_autofree(DungeonGeneratorClass.new())
	gen._generate_with(STUB_CONFIG, false)
	assert_true(gen.rooms_by_id.has(gen.start_room_id), "start_room_id must be present in rooms_by_id")


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
