extends GutTest

const Subject = preload("res://scenes/ui/hud/ExplorationHUD.gd")


func test_boss_available_when_cleared_equals_required() -> void:
	assert_true(Subject.is_boss_available(6, 6))


func test_boss_available_when_cleared_exceeds_required() -> void:
	assert_true(Subject.is_boss_available(10, 6))


func test_boss_not_available_when_cleared_below_required() -> void:
	assert_false(Subject.is_boss_available(5, 6))


func test_boss_not_available_when_no_rooms_cleared() -> void:
	assert_false(Subject.is_boss_available(0, 6))


func test_boss_available_with_zero_required() -> void:
	assert_true(Subject.is_boss_available(0, 0))
