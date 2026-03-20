extends GutTest

const MetaManagerImpl = preload("res://scripts/managers/MetaManager.gd")


class StubSaveManager extends Node:
	var saved: bool = false
	func save_meta_state(_state: MetaState) -> void:
		saved = true


# --- purchase_missile_extra_charge ---

func test_purchase_deducts_cost_and_sets_flag() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 200
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_missile_extra_charge(150, stub)
	assert_true(result, "should return true on success")
	assert_eq(impl.meta_state.total_shards, 50, "shards should be deducted by 150")
	assert_true(impl.meta_state.missile_extra_charge_owned, "flag should be set")
	stub.free()


func test_purchase_saves_on_success() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 200
	var stub := StubSaveManager.new()
	impl.purchase_missile_extra_charge(150, stub)
	assert_true(stub.saved, "save should be called on success")
	stub.free()


func test_purchase_returns_false_when_already_owned() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 500
	impl.meta_state.missile_extra_charge_owned = true
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_missile_extra_charge(150, stub)
	assert_false(result, "should return false when already owned")
	assert_eq(impl.meta_state.total_shards, 500, "shards should not be deducted")
	assert_false(stub.saved, "save should not be called")
	stub.free()


func test_purchase_returns_false_when_insufficient_shards() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 100
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_missile_extra_charge(150, stub)
	assert_false(result, "should return false with insufficient shards")
	assert_eq(impl.meta_state.total_shards, 100, "shards should be unchanged")
	assert_false(impl.meta_state.missile_extra_charge_owned, "flag should remain false")
	assert_false(stub.saved, "save should not be called")
	stub.free()


func test_purchase_succeeds_with_exact_cost() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 150
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_missile_extra_charge(150, stub)
	assert_true(result, "should succeed with exact balance")
	assert_eq(impl.meta_state.total_shards, 0, "shards should be zero after exact purchase")
	stub.free()
