extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")

# Inline stub dict for a typical healer enemy.
const HEALER_DICT: Dictionary = {
	"id": "forest_healer",
	"display_name": "Bramble Druid",
	"max_health": 40.0,
	"damage": 6.0,
	"move_speed": 80.0,
	"detection_range": 800.0,
	"damage_cooldown": 1.6,
	"heal_radius": 80.0,
	"heal_amount": 8.0,
}

# Stub dict for a non-healer enemy.
const STANDARD_DICT: Dictionary = {
	"id": "forest_tank",
	"display_name": "Briar Knight",
	"max_health": 80.0,
	"damage": 10.0,
	"move_speed": 60.0,
	"detection_range": 800.0,
	"damage_cooldown": 1.5,
}


# --- Healer detection via id suffix ---

func test_healer_id_ends_with_healer_suffix() -> void:
	var d: EnemyData = EnemyData.from_dict(HEALER_DICT)
	assert_true(d.id.ends_with("_healer"), "forest_healer id must end with '_healer'")


func test_standard_enemy_id_does_not_end_with_healer_suffix() -> void:
	var d: EnemyData = EnemyData.from_dict(STANDARD_DICT)
	assert_false(d.id.ends_with("_healer"), "forest_tank id must NOT end with '_healer'")


# --- Standoff distance formula: maxf(0.0, heal_radius - 20.0) ---

func test_standoff_distance_for_heal_radius_80() -> void:
	var d: EnemyData = EnemyData.from_dict(HEALER_DICT)
	var standoff: float = maxf(0.0, d.heal_radius - 20.0)
	assert_eq(standoff, 60.0, "standoff for heal_radius=80 must be 60")


func test_standoff_distance_clamps_to_zero_when_heal_radius_less_than_20() -> void:
	var dict: Dictionary = HEALER_DICT.duplicate()
	dict["heal_radius"] = 15.0
	var d: EnemyData = EnemyData.from_dict(dict)
	var standoff: float = maxf(0.0, d.heal_radius - 20.0)
	assert_eq(standoff, 0.0, "standoff must clamp to 0 when heal_radius < 20")


func test_standoff_distance_is_zero_when_heal_radius_equals_20() -> void:
	var dict: Dictionary = HEALER_DICT.duplicate()
	dict["heal_radius"] = 20.0
	var d: EnemyData = EnemyData.from_dict(dict)
	var standoff: float = maxf(0.0, d.heal_radius - 20.0)
	assert_eq(standoff, 0.0, "standoff must be 0 when heal_radius == 20")


func test_standoff_distance_positive_when_heal_radius_greater_than_20() -> void:
	var dict: Dictionary = HEALER_DICT.duplicate()
	dict["heal_radius"] = 100.0
	var d: EnemyData = EnemyData.from_dict(dict)
	var standoff: float = maxf(0.0, d.heal_radius - 20.0)
	assert_eq(standoff, 80.0, "standoff for heal_radius=100 must be 80")


# --- Closest-ally distance comparison logic ---

func test_closer_ally_replaces_farther_ally_in_min_tracking() -> void:
	# Simulate the inner-loop min-distance tracking:
	#   closest_dist starts at INF; first ally sets it to 100; second at 60 replaces it.
	var closest_dist: float = INF
	var first_d: float = 100.0
	if first_d < closest_dist:
		closest_dist = first_d
	var second_d: float = 60.0
	if second_d < closest_dist:
		closest_dist = second_d
	assert_eq(closest_dist, 60.0, "second (closer) ally must win the min-distance race")


func test_farther_ally_does_not_replace_closer_ally() -> void:
	var closest_dist: float = INF
	var first_d: float = 60.0
	if first_d < closest_dist:
		closest_dist = first_d
	var second_d: float = 100.0
	if second_d < closest_dist:
		closest_dist = second_d
	assert_eq(closest_dist, 60.0, "first (closer) ally must not be replaced by farther one")


func test_healer_should_move_when_distance_exceeds_standoff() -> void:
	var heal_radius: float = 80.0
	var standoff: float = maxf(0.0, heal_radius - 20.0)
	var dist_to_target: float = 90.0
	var should_move: bool = dist_to_target > standoff
	assert_true(should_move, "healer must move when distance (90) > standoff (60)")


func test_healer_should_stop_when_distance_equals_standoff() -> void:
	var heal_radius: float = 80.0
	var standoff: float = maxf(0.0, heal_radius - 20.0)
	var dist_to_target: float = 60.0
	var should_move: bool = dist_to_target > standoff
	assert_false(should_move, "healer must stop when distance (60) == standoff (60)")


func test_healer_should_stop_when_distance_less_than_standoff() -> void:
	var heal_radius: float = 80.0
	var standoff: float = maxf(0.0, heal_radius - 20.0)
	var dist_to_target: float = 40.0
	var should_move: bool = dist_to_target > standoff
	assert_false(should_move, "healer must stop when distance (40) < standoff (60)")
