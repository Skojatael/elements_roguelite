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
const RATES: Array = [2, 3, 5]


func before_each() -> void:
	_impl = MetaManagerImpl.new()
	_impl.meta_state = MetaState.new()
	_impl.meta_state.total_gold = 9999.0
	_save = StubSaveManager.new()


func after_each() -> void:
	_save.free()


# --- get_shard_rate_per_hour ---

func test_rate_at_level_zero_is_zero() -> void:
	_impl.meta_state.shard_generator_level = 0
	assert_eq(_impl.get_shard_rate_per_hour(RATES), 0.0)


func test_rate_at_level_one_is_first_entry() -> void:
	_impl.meta_state.shard_generator_level = 1
	assert_eq(_impl.get_shard_rate_per_hour(RATES), 2.0)


func test_rate_at_level_two() -> void:
	_impl.meta_state.shard_generator_level = 2
	assert_eq(_impl.get_shard_rate_per_hour(RATES), 3.0)


func test_rate_at_level_three_is_last_entry() -> void:
	_impl.meta_state.shard_generator_level = 3
	assert_eq(_impl.get_shard_rate_per_hour(RATES), 5.0)


# --- tick_shard_generator ---

func test_tick_at_level_zero_returns_zero() -> void:
	_impl.meta_state.shard_generator_level = 0
	var earned: int = _impl.tick_shard_generator(3600.0, RATES)
	assert_eq(earned, 0)
	assert_almost_eq(_impl.meta_state.shard_accumulator, 0.0, 0.0001)


func test_tick_accumulates_fractional_shards() -> void:
	_impl.meta_state.shard_generator_level = 1  # 2/hr
	# 900 seconds = 0.25 hours → 0.5 shards (no whole shard yet)
	var earned: int = _impl.tick_shard_generator(900.0, RATES)
	assert_eq(earned, 0)
	assert_almost_eq(_impl.meta_state.shard_accumulator, 0.5, 0.0001)


func test_tick_drains_whole_shards_and_returns_count() -> void:
	_impl.meta_state.shard_generator_level = 1  # 2/hr
	# 1800 seconds = 0.5 hours → 1.0 shard earned
	var earned: int = _impl.tick_shard_generator(1800.0, RATES)
	assert_eq(earned, 1)
	assert_almost_eq(_impl.meta_state.shard_accumulator, 0.0, 0.0001)


func test_tick_does_not_double_count_remainder() -> void:
	_impl.meta_state.shard_generator_level = 1  # 2/hr
	# 2700 seconds = 0.75 hours → 1.5 shards: earn 1, keep 0.5
	var earned: int = _impl.tick_shard_generator(2700.0, RATES)
	assert_eq(earned, 1)
	assert_almost_eq(_impl.meta_state.shard_accumulator, 0.5, 0.0001)


func test_tick_accumulates_across_multiple_calls() -> void:
	_impl.meta_state.shard_generator_level = 1  # 2/hr
	_impl.tick_shard_generator(900.0, RATES)   # +0.5, earn 0
	var earned: int = _impl.tick_shard_generator(900.0, RATES)  # +0.5 = 1.0, earn 1
	assert_eq(earned, 1)
	assert_almost_eq(_impl.meta_state.shard_accumulator, 0.0, 0.0001)


# --- apply_offline_shards ---

func test_offline_returns_zero_at_level_zero() -> void:
	_impl.meta_state.shard_generator_level = 0
	_impl.meta_state.gold_last_saved_timestamp = 1000
	var earned: int = _impl.apply_offline_shards(2000, RATES, 86400, _save)
	assert_eq(earned, 0)
	assert_false(_save.saved)


func test_offline_returns_zero_when_timestamp_is_zero() -> void:
	_impl.meta_state.shard_generator_level = 1
	_impl.meta_state.gold_last_saved_timestamp = 0
	var earned: int = _impl.apply_offline_shards(3600, RATES, 86400, _save)
	assert_eq(earned, 0)
	assert_false(_save.saved)


func test_offline_returns_zero_for_zero_elapsed() -> void:
	_impl.meta_state.shard_generator_level = 1
	_impl.meta_state.gold_last_saved_timestamp = 5000
	var earned: int = _impl.apply_offline_shards(5000, RATES, 86400, _save)
	assert_eq(earned, 0)


func test_offline_returns_zero_for_negative_elapsed() -> void:
	_impl.meta_state.shard_generator_level = 1
	_impl.meta_state.gold_last_saved_timestamp = 9000
	var earned: int = _impl.apply_offline_shards(5000, RATES, 86400, _save)
	assert_eq(earned, 0)


func test_offline_credits_one_hour_at_level_one() -> void:
	_impl.meta_state.shard_generator_level = 1  # 2/hr
	_impl.meta_state.gold_last_saved_timestamp = 0
	_impl.meta_state.total_shards = 0
	_impl.meta_state.gold_last_saved_timestamp = 1000
	var earned: int = _impl.apply_offline_shards(1000 + 3600, RATES, 86400, _save)
	assert_eq(earned, 2)
	assert_eq(_impl.meta_state.total_shards, 2)
	assert_true(_save.saved)


func test_offline_caps_at_cap_seconds() -> void:
	_impl.meta_state.shard_generator_level = 3  # 5/hr
	_impl.meta_state.total_shards = 0
	_impl.meta_state.gold_last_saved_timestamp = 1000
	# 10 hours elapsed (36000s) but cap is 4 hours (14400s) → floor(5 * 4) = 20
	var earned: int = _impl.apply_offline_shards(1000 + 36000, RATES, 14400, _save)
	assert_eq(earned, 20)


# --- purchase_shard_generator ---

func test_purchase_level_one_succeeds_and_deducts_gold() -> void:
	_impl.meta_state.shard_generator_level = 0
	_impl.meta_state.total_gold = 600.0
	var result: bool = _impl.purchase_shard_generator(600, 3, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.shard_generator_level, 1)
	assert_almost_eq(_impl.meta_state.total_gold, 0.0, 0.001)


func test_purchase_returns_false_at_max_level() -> void:
	_impl.meta_state.shard_generator_level = 3
	_impl.meta_state.total_gold = 9999.0
	_save.saved = false
	var result: bool = _impl.purchase_shard_generator(2400, 3, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.shard_generator_level, 3)


func test_purchase_returns_false_when_gold_insufficient() -> void:
	_impl.meta_state.shard_generator_level = 0
	_impl.meta_state.total_gold = 599.0
	_save.saved = false
	var result: bool = _impl.purchase_shard_generator(600, 3, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.shard_generator_level, 0)
	assert_almost_eq(_impl.meta_state.total_gold, 599.0, 0.001)


func test_purchase_returns_false_one_gold_below_cost() -> void:
	_impl.meta_state.shard_generator_level = 1
	_impl.meta_state.total_gold = 1199.0
	var result: bool = _impl.purchase_shard_generator(1200, 3, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.shard_generator_level, 1)


func test_purchase_exact_balance_succeeds() -> void:
	_impl.meta_state.shard_generator_level = 2
	_impl.meta_state.total_gold = 2400.0
	var result: bool = _impl.purchase_shard_generator(2400, 3, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.shard_generator_level, 3)
	assert_almost_eq(_impl.meta_state.total_gold, 0.0, 0.001)
