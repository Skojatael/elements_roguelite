extends GutTest

const MetaManagerImpl = preload("res://scripts/managers/MetaManager.gd")
const MetaState = preload("res://scripts/data_models/MetaState.gd")


class StubSaveManager:
	extends Node
	var saved: bool = false
	func save_meta_state(_state: MetaState) -> void:
		saved = true


var _impl: MetaManagerImpl
var _save: StubSaveManager


func before_each() -> void:
	_impl = MetaManagerImpl.new()
	_impl.meta_state = MetaState.new()
	_impl.meta_state.total_shards = 1000
	_save = StubSaveManager.new()


func after_each() -> void:
	_save.free()


func test_success_deducts_shards_and_sets_flag() -> void:
	var result: bool = _impl.purchase_alchemy_lab(500, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 500)
	assert_true(_impl.meta_state.alchemy_lab_unlocked)
	assert_true(_save.saved)


func test_insufficient_shards_returns_false() -> void:
	_impl.meta_state.total_shards = 499
	var result: bool = _impl.purchase_alchemy_lab(500, _save)
	assert_false(result)
	assert_false(_impl.meta_state.alchemy_lab_unlocked)
	assert_eq(_impl.meta_state.total_shards, 499)


func test_already_unlocked_returns_false() -> void:
	_impl.meta_state.alchemy_lab_unlocked = true
	var result: bool = _impl.purchase_alchemy_lab(500, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.total_shards, 1000)


func test_idempotent_second_call_returns_false() -> void:
	_impl.purchase_alchemy_lab(500, _save)
	_save.saved = false
	var result: bool = _impl.purchase_alchemy_lab(500, _save)
	assert_false(result)
	assert_false(_save.saved)


func test_essence_gain_multiplier_at_level_zero_is_one() -> void:
	_impl.meta_state.essence_gain_level = 0
	assert_eq(_impl.get_essence_gain_multiplier(0.05), 1.0)


func test_essence_gain_multiplier_at_level_one() -> void:
	_impl.meta_state.essence_gain_level = 1
	assert_almost_eq(_impl.get_essence_gain_multiplier(0.05), 1.05, 0.0001)


func test_essence_gain_multiplier_respects_per_level_value() -> void:
	_impl.meta_state.essence_gain_level = 1
	assert_almost_eq(_impl.get_essence_gain_multiplier(0.10), 1.10, 0.0001)
