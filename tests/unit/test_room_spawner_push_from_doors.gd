extends GutTest

const RoomSpawnerScript = preload("res://scripts/dungeon/RoomSpawner.gd")


# --- positions already far from doors ---

func test_position_far_from_all_doors_unchanged() -> void:
	var pos := Vector2(0.0, 0.0)
	var result: Vector2 = RoomSpawnerScript._push_from_doors(pos)
	assert_eq(result, pos, "center position must not be moved — it is far from all doors")


func test_position_far_from_specific_door_unchanged() -> void:
	# 200px from north door (0, -540) → (0, -340)
	var pos := Vector2(0.0, -340.0)
	var result: Vector2 = RoomSpawnerScript._push_from_doors(pos)
	assert_eq(result, pos, "position 200px from north door must not be moved")


# --- positions too close to a single door ---

func test_north_door_pushes_position_south() -> void:
	# North door is at (0, -540). Place spawn at (0, -500) — 40px away.
	var pos := Vector2(0.0, -500.0)
	var result: Vector2 = RoomSpawnerScript._push_from_doors(pos)
	var dist: float = result.distance_to(Vector2(0.0, -540.0))
	assert_almost_eq(dist, RoomSpawnerScript.MIN_DOOR_DISTANCE, 0.001,
		"pushed position must be exactly MIN_DOOR_DISTANCE from north door")


func test_south_door_pushes_position_north() -> void:
	var pos := Vector2(0.0, 510.0)
	var result: Vector2 = RoomSpawnerScript._push_from_doors(pos)
	var dist: float = result.distance_to(Vector2(0.0, 540.0))
	assert_almost_eq(dist, RoomSpawnerScript.MIN_DOOR_DISTANCE, 0.001,
		"pushed position must be exactly MIN_DOOR_DISTANCE from south door")


func test_east_door_pushes_position_west() -> void:
	var pos := Vector2(920.0, 0.0)
	var result: Vector2 = RoomSpawnerScript._push_from_doors(pos)
	var dist: float = result.distance_to(Vector2(960.0, 0.0))
	assert_almost_eq(dist, RoomSpawnerScript.MIN_DOOR_DISTANCE, 0.001,
		"pushed position must be exactly MIN_DOOR_DISTANCE from east door")


func test_west_door_pushes_position_east() -> void:
	var pos := Vector2(-920.0, 0.0)
	var result: Vector2 = RoomSpawnerScript._push_from_doors(pos)
	var dist: float = result.distance_to(Vector2(-960.0, 0.0))
	assert_almost_eq(dist, RoomSpawnerScript.MIN_DOOR_DISTANCE, 0.001,
		"pushed position must be exactly MIN_DOOR_DISTANCE from west door")


# --- position exactly on a door center (degenerate case) ---

func test_position_on_north_door_center_gets_pushed() -> void:
	var pos := Vector2(0.0, -540.0)
	var result: Vector2 = RoomSpawnerScript._push_from_doors(pos)
	var dist: float = result.distance_to(pos)
	assert_true(dist >= RoomSpawnerScript.MIN_DOOR_DISTANCE - 0.001,
		"position on door center must be pushed at least MIN_DOOR_DISTANCE away")


# --- position just at the threshold ---

func test_position_exactly_at_min_distance_unchanged() -> void:
	# Exactly 100px south of north door (0, -540) → (0, -440)
	var pos := Vector2(0.0, -440.0)
	var result: Vector2 = RoomSpawnerScript._push_from_doors(pos)
	var dist: float = result.distance_to(Vector2(0.0, -540.0))
	assert_almost_eq(dist, RoomSpawnerScript.MIN_DOOR_DISTANCE, 0.001,
		"position exactly at MIN_DOOR_DISTANCE must not be moved")
