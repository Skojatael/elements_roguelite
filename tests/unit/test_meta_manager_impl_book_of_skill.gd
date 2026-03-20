extends GutTest

const MetaManagerImpl = preload("res://scripts/managers/MetaManager.gd")


class StubSaveManager extends Node:
	var saved: bool = false
	func save_meta_state(_state: MetaState) -> void:
		saved = true


# --- record_book_of_skill_gate ---

func test_record_gate_returns_true_on_first_call() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	var stub := StubSaveManager.new()
	var result: bool = impl.record_book_of_skill_gate(stub)
	assert_true(result, "should return true when gate was not yet reached")
	assert_true(impl.meta_state.book_of_skill_gate_reached, "flag must be set")
	assert_true(stub.saved, "should save after setting gate")


func test_record_gate_returns_false_on_second_call() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	var stub := StubSaveManager.new()
	impl.record_book_of_skill_gate(stub)
	stub.saved = false
	var result: bool = impl.record_book_of_skill_gate(stub)
	assert_false(result, "should return false when gate already reached")
	assert_false(stub.saved, "should NOT save on idempotent call")


func test_record_gate_does_not_change_flag_on_second_call() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	var stub := StubSaveManager.new()
	impl.record_book_of_skill_gate(stub)
	impl.record_book_of_skill_gate(stub)
	assert_true(impl.meta_state.book_of_skill_gate_reached, "flag must remain true")


# --- purchase_book_of_skill ---

func test_purchase_deducts_cost_and_sets_flag() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 300
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_book_of_skill(250, stub)
	assert_true(result, "should return true on success")
	assert_true(impl.meta_state.book_of_skill_owned, "owned flag must be set")
	assert_eq(impl.meta_state.total_shards, 50, "shards must be deducted")
	assert_true(stub.saved, "should save after purchase")


func test_purchase_returns_false_when_already_owned() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 500
	impl.meta_state.book_of_skill_owned = true
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_book_of_skill(250, stub)
	assert_false(result, "should return false when already owned")
	assert_eq(impl.meta_state.total_shards, 500, "shards must not be deducted")


func test_purchase_returns_false_when_insufficient_shards() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 100
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_book_of_skill(250, stub)
	assert_false(result, "should return false when can't afford")
	assert_false(impl.meta_state.book_of_skill_owned, "owned flag must not be set")
	assert_eq(impl.meta_state.total_shards, 100, "shards must not be deducted")


func test_purchase_succeeds_with_exact_balance() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 250
	var stub := StubSaveManager.new()
	var result: bool = impl.purchase_book_of_skill(250, stub)
	assert_true(result, "should succeed with exact balance")
	assert_eq(impl.meta_state.total_shards, 0, "shards must reach zero")
