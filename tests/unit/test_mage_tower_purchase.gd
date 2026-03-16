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


# --- purchase_mage_tower ---

func test_tower_success_deducts_shards_and_sets_flag() -> void:
	var result: bool = _impl.purchase_mage_tower(200, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 800)
	assert_true(_impl.meta_state.mage_tower_unlocked)
	assert_true(_save.saved)


func test_tower_insufficient_shards_returns_false() -> void:
	_impl.meta_state.total_shards = 199
	var result: bool = _impl.purchase_mage_tower(200, _save)
	assert_false(result)
	assert_false(_impl.meta_state.mage_tower_unlocked)
	assert_eq(_impl.meta_state.total_shards, 199)


func test_tower_already_unlocked_returns_false() -> void:
	_impl.meta_state.mage_tower_unlocked = true
	var result: bool = _impl.purchase_mage_tower(200, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.total_shards, 1000)


func test_tower_idempotent_second_call_returns_false() -> void:
	_impl.purchase_mage_tower(200, _save)
	_save.saved = false
	var result: bool = _impl.purchase_mage_tower(200, _save)
	assert_false(result)
	assert_false(_save.saved)


# --- purchase_mage_tower_relic_system ---

func test_relic_system_success_deducts_shards_and_sets_flag() -> void:
	var result: bool = _impl.purchase_mage_tower_relic_system(100, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 900)
	assert_true(_impl.meta_state.relic_offers_active)
	assert_true(_save.saved)


func test_relic_system_insufficient_shards_returns_false() -> void:
	_impl.meta_state.total_shards = 99
	var result: bool = _impl.purchase_mage_tower_relic_system(100, _save)
	assert_false(result)
	assert_false(_impl.meta_state.relic_offers_active)


func test_relic_system_already_active_returns_false() -> void:
	_impl.meta_state.relic_offers_active = true
	var result: bool = _impl.purchase_mage_tower_relic_system(100, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.total_shards, 1000)


func test_relic_system_idempotent_second_call_returns_false() -> void:
	_impl.purchase_mage_tower_relic_system(100, _save)
	_save.saved = false
	var result: bool = _impl.purchase_mage_tower_relic_system(100, _save)
	assert_false(result)
	assert_false(_save.saved)


# --- purchase_adventuring_gear ---

func test_adventuring_gear_success_deducts_shards_and_sets_flag() -> void:
	var result: bool = _impl.purchase_adventuring_gear(200, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 800)
	assert_true(_impl.meta_state.adventuring_gear_owned)
	assert_true(_save.saved)


func test_adventuring_gear_insufficient_shards_returns_false() -> void:
	_impl.meta_state.total_shards = 199
	var result: bool = _impl.purchase_adventuring_gear(200, _save)
	assert_false(result)
	assert_false(_impl.meta_state.adventuring_gear_owned)


func test_adventuring_gear_already_owned_returns_false() -> void:
	_impl.meta_state.adventuring_gear_owned = true
	var result: bool = _impl.purchase_adventuring_gear(200, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.total_shards, 1000)


func test_adventuring_gear_idempotent_second_call_returns_false() -> void:
	_impl.purchase_adventuring_gear(200, _save)
	_save.saved = false
	var result: bool = _impl.purchase_adventuring_gear(200, _save)
	assert_false(result)
	assert_false(_save.saved)


# --- purchase_boss_run ---

func test_boss_run_success_deducts_shards_and_sets_flag() -> void:
	var result: bool = _impl.purchase_boss_run(200, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 800)
	assert_true(_impl.meta_state.boss_run_unlocked)
	assert_true(_save.saved)


func test_boss_run_insufficient_shards_returns_false() -> void:
	_impl.meta_state.total_shards = 199
	var result: bool = _impl.purchase_boss_run(200, _save)
	assert_false(result)
	assert_false(_impl.meta_state.boss_run_unlocked)


func test_boss_run_already_unlocked_returns_false() -> void:
	_impl.meta_state.boss_run_unlocked = true
	var result: bool = _impl.purchase_boss_run(200, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.total_shards, 1000)


func test_boss_run_idempotent_second_call_returns_false() -> void:
	_impl.purchase_boss_run(200, _save)
	_save.saved = false
	var result: bool = _impl.purchase_boss_run(200, _save)
	assert_false(result)
	assert_false(_save.saved)


# --- record_boss_kill ---

func test_record_boss_kill_first_call_sets_flag_and_saves() -> void:
	var result: bool = _impl.record_boss_kill(_save)
	assert_true(result, "first boss kill should return true")
	assert_true(_impl.meta_state.first_boss_killed, "first_boss_killed flag must be set")
	assert_true(_save.saved, "save must be called on first boss kill")


func test_record_boss_kill_second_call_is_idempotent() -> void:
	_impl.record_boss_kill(_save)
	_save.saved = false
	var result: bool = _impl.record_boss_kill(_save)
	assert_false(result, "second boss kill must return false")
	assert_false(_save.saved, "save must not be called on duplicate boss kill")


# --- increment_endless_boss_kills ---

func test_increment_endless_boss_kills_increments_counter() -> void:
	_impl.increment_endless_boss_kills(_save)
	assert_eq(_impl.meta_state.endless_boss_kill_count, 1,
		"counter should be 1 after one increment")


func test_increment_endless_boss_kills_saves() -> void:
	_impl.increment_endless_boss_kills(_save)
	assert_true(_save.saved, "increment must call save")


func test_increment_endless_boss_kills_accumulates() -> void:
	_impl.increment_endless_boss_kills(_save)
	_impl.increment_endless_boss_kills(_save)
	assert_eq(_impl.meta_state.endless_boss_kill_count, 2,
		"counter should accumulate across calls")
