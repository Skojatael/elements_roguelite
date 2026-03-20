extends GutTest

const RootComponent = preload("res://scenes/player/components/RootComponent.gd")

var _root: RootComponent


func before_each() -> void:
	_root = RootComponent.new()
	add_child_autofree(_root)


func test_not_rooted_by_default() -> void:
	assert_false(_root.is_rooted)


func test_apply_root_sets_rooted() -> void:
	_root.apply_root(1.0)
	assert_true(_root.is_rooted)


func test_apply_root_refresh_to_longest_when_longer() -> void:
	_root.apply_root(1.5)
	_root.apply_root(0.6)
	assert_almost_eq(_root._root_remaining, 1.5, 0.001)


func test_apply_root_refresh_to_longest_when_shorter_applied_first() -> void:
	_root.apply_root(0.6)
	_root.apply_root(1.5)
	assert_almost_eq(_root._root_remaining, 1.5, 0.001)


func test_apply_root_does_not_stack() -> void:
	_root.apply_root(1.0)
	_root.apply_root(1.0)
	assert_almost_eq(_root._root_remaining, 1.0, 0.001)


func test_apply_root_zero_does_not_root() -> void:
	_root.apply_root(0.0)
	assert_false(_root.is_rooted)


func test_root_expires_after_delta() -> void:
	_root.apply_root(0.1)
	_root._physics_process(0.1)
	assert_false(_root.is_rooted)


func test_root_does_not_go_negative() -> void:
	_root.apply_root(0.1)
	_root._physics_process(1.0)
	assert_almost_eq(_root._root_remaining, 0.0, 0.001)


func test_tick_does_nothing_when_not_rooted() -> void:
	_root._physics_process(0.5)
	assert_almost_eq(_root._root_remaining, 0.0, 0.001)
