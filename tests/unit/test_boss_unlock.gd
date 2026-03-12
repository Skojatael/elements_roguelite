extends GutTest


func test_unavailable_below_threshold() -> void:
	assert_false(ExplorationHUD.is_boss_available(5, 6), "5 cleared rooms must not unlock boss (threshold 6)")


func test_available_at_exact_threshold() -> void:
	assert_true(ExplorationHUD.is_boss_available(6, 6), "exactly 6 cleared rooms must unlock boss (threshold 6)")


func test_available_above_threshold() -> void:
	assert_true(ExplorationHUD.is_boss_available(10, 6), "10 cleared rooms must unlock boss (threshold 6)")


func test_unavailable_at_zero_cleared() -> void:
	assert_false(ExplorationHUD.is_boss_available(0, 6), "0 cleared rooms must not unlock boss (threshold 6)")


func test_available_when_threshold_is_zero() -> void:
	assert_true(ExplorationHUD.is_boss_available(0, 0), "0 cleared rooms unlocks boss when threshold is 0")
