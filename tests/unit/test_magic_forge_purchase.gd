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


# --- purchase_magic_forge ---

func test_forge_success_deducts_shards_and_sets_flag() -> void:
	var result: bool = _impl.purchase_magic_forge(120, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 880)
	assert_true(_impl.meta_state.magic_forge_unlocked)
	assert_true(_save.saved)


func test_forge_insufficient_shards_returns_false() -> void:
	_impl.meta_state.total_shards = 119
	var result: bool = _impl.purchase_magic_forge(120, _save)
	assert_false(result)
	assert_false(_impl.meta_state.magic_forge_unlocked)
	assert_eq(_impl.meta_state.total_shards, 119)
	assert_false(_save.saved)


func test_forge_already_unlocked_returns_false() -> void:
	_impl.meta_state.magic_forge_unlocked = true
	var result: bool = _impl.purchase_magic_forge(120, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.total_shards, 1000)
	assert_false(_save.saved)


func test_forge_exact_balance_succeeds() -> void:
	_impl.meta_state.total_shards = 120
	var result: bool = _impl.purchase_magic_forge(120, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 0)
	assert_true(_impl.meta_state.magic_forge_unlocked)


func test_forge_idempotent_second_call_returns_false() -> void:
	_impl.purchase_magic_forge(120, _save)
	_save.saved = false
	var result: bool = _impl.purchase_magic_forge(120, _save)
	assert_false(result)
	assert_false(_save.saved)


# --- purchase_damage_upgrade ---

func test_damage_upgrade_success_deducts_shards_and_increments_level() -> void:
	var result: bool = _impl.purchase_damage_upgrade(50, 10, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 950)
	assert_eq(_impl.meta_state.damage_upgrade_level, 1)
	assert_true(_save.saved)


func test_damage_upgrade_insufficient_shards_returns_false() -> void:
	_impl.meta_state.total_shards = 49
	var result: bool = _impl.purchase_damage_upgrade(50, 10, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.damage_upgrade_level, 0)
	assert_false(_save.saved)


func test_damage_upgrade_at_max_level_returns_false() -> void:
	_impl.meta_state.damage_upgrade_level = 10
	var result: bool = _impl.purchase_damage_upgrade(50, 10, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.damage_upgrade_level, 10)
	assert_eq(_impl.meta_state.total_shards, 1000)
	assert_false(_save.saved)


func test_damage_upgrade_exact_balance_succeeds() -> void:
	_impl.meta_state.total_shards = 50
	var result: bool = _impl.purchase_damage_upgrade(50, 10, _save)
	assert_true(result)
	assert_eq(_impl.meta_state.total_shards, 0)
	assert_eq(_impl.meta_state.damage_upgrade_level, 1)


func test_damage_upgrade_increments_level_each_call() -> void:
	_impl.purchase_damage_upgrade(50, 10, _save)
	_impl.purchase_damage_upgrade(50, 10, _save)
	assert_eq(_impl.meta_state.damage_upgrade_level, 2)
	assert_eq(_impl.meta_state.total_shards, 900)


func test_damage_upgrade_stops_at_max_level() -> void:
	_impl.meta_state.damage_upgrade_level = 9
	_impl.purchase_damage_upgrade(50, 10, _save)
	assert_eq(_impl.meta_state.damage_upgrade_level, 10)
	var result: bool = _impl.purchase_damage_upgrade(50, 10, _save)
	assert_false(result)
	assert_eq(_impl.meta_state.damage_upgrade_level, 10)


# --- get_damage_multiplier ---

func test_damage_multiplier_at_level_zero_is_one() -> void:
	_impl.meta_state.damage_upgrade_level = 0
	assert_almost_eq(_impl.get_damage_multiplier(0.1), 1.0, 0.0001)


func test_damage_multiplier_at_level_one() -> void:
	_impl.meta_state.damage_upgrade_level = 1
	assert_almost_eq(_impl.get_damage_multiplier(0.1), 1.1, 0.0001)


func test_damage_multiplier_at_level_two_is_compounding() -> void:
	_impl.meta_state.damage_upgrade_level = 2
	assert_almost_eq(_impl.get_damage_multiplier(0.1), 1.21, 0.0001)


func test_damage_multiplier_respects_per_level_value() -> void:
	_impl.meta_state.damage_upgrade_level = 1
	assert_almost_eq(_impl.get_damage_multiplier(0.2), 1.2, 0.0001)


func test_damage_multiplier_at_max_level_10() -> void:
	_impl.meta_state.damage_upgrade_level = 10
	assert_almost_eq(_impl.get_damage_multiplier(0.1), pow(1.1, 10.0), 0.0001)
