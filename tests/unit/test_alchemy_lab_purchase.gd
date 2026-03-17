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
	assert_false(_save.saved)


func test_already_unlocked_returns_false() -> void:
	_impl.meta_state.alchemy_lab_unlocked = true
	var result: bool = _impl.purchase_alchemy_lab(500, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.total_shards, 1000)
	assert_false(_save.saved)


func test_exact_balance_succeeds() -> void:
	_impl.meta_state.total_shards = 500
	var result: bool = _impl.purchase_alchemy_lab(500, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 0)
	assert_true(_impl.meta_state.alchemy_lab_unlocked)


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


func test_essence_gain_multiplier_compounds_at_level_five() -> void:
	_impl.meta_state.essence_gain_level = 5
	assert_almost_eq(_impl.get_essence_gain_multiplier(0.05), pow(1.05, 5), 0.0001)


func test_can_spend_gold_true_when_balance_sufficient() -> void:
	_impl.meta_state.total_gold = 100.0
	assert_true(_impl.can_spend_gold(100.0))


func test_can_spend_gold_false_when_balance_insufficient() -> void:
	_impl.meta_state.total_gold = 49.9
	assert_false(_impl.can_spend_gold(50.0))


func test_can_spend_gold_false_for_negative_cost() -> void:
	_impl.meta_state.total_gold = 999.0
	assert_false(_impl.can_spend_gold(-1.0))


func test_spend_gold_deducts_on_success() -> void:
	_impl.meta_state.total_gold = 200.0
	var result: bool = _impl.spend_gold(50.0, _save)
	assert_true(result)
	assert_almost_eq(_impl.meta_state.total_gold, 150.0, 0.001)
	assert_true(_save.saved)


func test_spend_gold_rejects_insufficient_balance() -> void:
	_impl.meta_state.total_gold = 30.0
	_save.saved = false
	var result: bool = _impl.spend_gold(50.0, _save)
	assert_false(result)
	assert_almost_eq(_impl.meta_state.total_gold, 30.0, 0.001)
	assert_false(_save.saved)


func test_spend_gold_rejects_negative_cost() -> void:
	_impl.meta_state.total_gold = 999.0
	_save.saved = false
	var result: bool = _impl.spend_gold(-10.0, _save)
	assert_false(result)
	assert_almost_eq(_impl.meta_state.total_gold, 999.0, 0.001)
	assert_false(_save.saved)


func test_purchase_essence_gain_increments_level_and_deducts_gold() -> void:
	_impl.meta_state.total_gold = 200.0
	_impl.meta_state.essence_gain_level = 0
	var result: bool = _impl.purchase_essence_gain(50, 50, 5, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.essence_gain_level, 1)
	assert_almost_eq(_impl.meta_state.total_gold, 150.0, 0.001)


func test_purchase_essence_gain_level2_costs_100() -> void:
	_impl.meta_state.total_gold = 200.0
	_impl.meta_state.essence_gain_level = 1
	var result: bool = _impl.purchase_essence_gain(50, 50, 5, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.essence_gain_level, 2)
	assert_almost_eq(_impl.meta_state.total_gold, 100.0, 0.001)


func test_purchase_essence_gain_returns_false_at_max_level() -> void:
	_impl.meta_state.total_gold = 9999.0
	_impl.meta_state.essence_gain_level = 5
	_save.saved = false
	var result: bool = _impl.purchase_essence_gain(50, 50, 5, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.essence_gain_level, 5)
	assert_false(_save.saved)


func test_purchase_essence_gain_returns_false_when_gold_insufficient() -> void:
	_impl.meta_state.total_gold = 40.0
	_impl.meta_state.essence_gain_level = 0
	_save.saved = false
	var result: bool = _impl.purchase_essence_gain(50, 50, 5, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.essence_gain_level, 0)
	assert_almost_eq(_impl.meta_state.total_gold, 40.0, 0.001)
	assert_false(_save.saved)
