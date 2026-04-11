extends GutTest

## Tests for the pursuit stop-threshold logic in Enemy.gd.
## The standoff distance is maxf(0.0, attack_range - 10.0).
## These tests validate the arithmetic in isolation using inline values.

func _standoff(attack_range: float) -> float:
	return maxf(0.0, attack_range - 10.0)


func test_normal_range_standoff() -> void:
	# attack_range = 100 → standoff = 90
	assert_eq(_standoff(100.0), 90.0)


func test_range_just_above_ten() -> void:
	# attack_range = 11 → standoff = 1
	assert_eq(_standoff(11.0), 1.0)


func test_range_exactly_ten() -> void:
	# attack_range = 10 → standoff = 0
	assert_eq(_standoff(10.0), 0.0)


func test_range_below_ten_clamps_to_zero() -> void:
	# attack_range = 5 → standoff = 0 (clamped, not negative)
	assert_eq(_standoff(5.0), 0.0)


func test_range_zero_clamps_to_zero() -> void:
	assert_eq(_standoff(0.0), 0.0)


func test_enemy_continues_when_dist_above_standoff() -> void:
	# dist = 91 > standoff 90 → enemy should NOT stop
	var standoff: float = _standoff(100.0)
	var dist: float = 91.0
	assert_true(dist > standoff, "Enemy should keep moving when dist > standoff")


func test_enemy_stops_when_dist_equals_standoff() -> void:
	# dist = 90 == standoff 90 → enemy should stop
	var standoff: float = _standoff(100.0)
	var dist: float = 90.0
	assert_false(dist > standoff, "Enemy should stop when dist equals standoff")


func test_enemy_stops_when_dist_below_standoff() -> void:
	# dist = 89 < standoff 90 → enemy should stop
	var standoff: float = _standoff(100.0)
	var dist: float = 89.0
	assert_false(dist > standoff, "Enemy should stop when dist < standoff")
