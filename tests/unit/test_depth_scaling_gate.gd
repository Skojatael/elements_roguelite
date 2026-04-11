extends GutTest

const MetaManagerImpl = preload("res://scripts/managers/MetaManager.gd")

var _impl: MetaManagerImpl


class SaveManagerStub:
	extends Node
	func save_meta_state(_state: MetaState) -> void:
		pass


var _save_mgr: SaveManagerStub


func before_each() -> void:
	_impl = MetaManagerImpl.new()
	_save_mgr = SaveManagerStub.new()


# --- depth_scaling_unlocked defaults false ---

func test_depth_scaling_unlocked_defaults_false() -> void:
	assert_false(_impl.meta_state.depth_scaling_unlocked,
		"depth_scaling_unlocked must default to false on a fresh MetaState")


# --- purchase_depth_scaling: happy path ---

func test_purchase_depth_scaling_succeeds_when_affordable() -> void:
	_impl.meta_state.total_shards = 300
	var result: bool = _impl.purchase_depth_scaling(300, _save_mgr)
	assert_true(result, "purchase must return true when shards are sufficient")


func test_purchase_depth_scaling_sets_flag() -> void:
	_impl.meta_state.total_shards = 300
	_impl.purchase_depth_scaling(300, _save_mgr)
	assert_true(_impl.meta_state.depth_scaling_unlocked,
		"depth_scaling_unlocked must be true after successful purchase")


func test_purchase_depth_scaling_deducts_shards() -> void:
	_impl.meta_state.total_shards = 500
	_impl.purchase_depth_scaling(300, _save_mgr)
	assert_eq(_impl.meta_state.total_shards, 200,
		"shards must be reduced by cost after purchase")


# --- purchase_depth_scaling: already owned ---

func test_purchase_depth_scaling_returns_false_when_already_owned() -> void:
	_impl.meta_state.total_shards = 600
	_impl.purchase_depth_scaling(300, _save_mgr)
	var second: bool = _impl.purchase_depth_scaling(300, _save_mgr)
	assert_false(second, "second purchase attempt must return false")


func test_purchase_depth_scaling_does_not_double_deduct() -> void:
	_impl.meta_state.total_shards = 600
	_impl.purchase_depth_scaling(300, _save_mgr)
	_impl.purchase_depth_scaling(300, _save_mgr)
	assert_eq(_impl.meta_state.total_shards, 300,
		"shards must only be deducted once")


# --- purchase_depth_scaling: insufficient shards ---

func test_purchase_depth_scaling_returns_false_when_insufficient_shards() -> void:
	_impl.meta_state.total_shards = 100
	var result: bool = _impl.purchase_depth_scaling(300, _save_mgr)
	assert_false(result, "purchase must return false when shards are insufficient")


func test_purchase_depth_scaling_does_not_set_flag_when_insufficient() -> void:
	_impl.meta_state.total_shards = 100
	_impl.purchase_depth_scaling(300, _save_mgr)
	assert_false(_impl.meta_state.depth_scaling_unlocked,
		"flag must remain false when purchase fails due to insufficient shards")
