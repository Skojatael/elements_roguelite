extends GutTest

const MetaManagerImpl = preload("res://scripts/managers/MetaManager.gd")


class StubSaveManager extends Node:
	var saved: bool = false
	func save_meta_state(_state: MetaState) -> void:
		saved = true


# --- purchase_forest_domain ---

func test_purchase_deducts_cost_and_sets_flag() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 100
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_forest_domain(40, stub)
	assert_true(result, "should return true on success")
	assert_true(impl.meta_state.forest_domain_unlocked, "flag must be set after purchase")
	assert_eq(impl.meta_state.total_shards, 60, "cost must be deducted from shards")
	assert_true(stub.saved, "must save state after purchase")


func test_purchase_returns_false_when_already_owned() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 200
	impl.meta_state.forest_domain_unlocked = true
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_forest_domain(40, stub)
	assert_false(result, "should return false when already owned")
	assert_eq(impl.meta_state.total_shards, 200, "shards must not be deducted when already owned")
	assert_false(stub.saved, "must not save on idempotent call")


func test_purchase_returns_false_when_insufficient_shards() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 10
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_forest_domain(40, stub)
	assert_false(result, "should return false when cannot afford")
	assert_false(impl.meta_state.forest_domain_unlocked, "flag must not be set on failure")
	assert_eq(impl.meta_state.total_shards, 10, "shards must not be deducted on failure")


func test_purchase_succeeds_with_exact_balance() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 40
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_forest_domain(40, stub)
	assert_true(result, "should succeed with exact balance")
	assert_eq(impl.meta_state.total_shards, 0, "shards must reach zero")
	assert_true(impl.meta_state.forest_domain_unlocked, "flag must be set")
