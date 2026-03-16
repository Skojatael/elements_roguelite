extends GutTest

const MetaManagerImpl = preload("res://scripts/managers/MetaManager.gd")


class FakeSaveManager extends Node:
	func save_meta_state(_state: MetaState) -> void:
		pass


class StubSaveManager extends Node:
	var saved: bool = false
	func save_meta_state(_state: MetaState) -> void:
		saved = true


# --- tick_gold ---

func test_tick_gold_one_hour_gives_100() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	var floor_val: int = impl.tick_gold(3600.0, 100.0)
	assert_eq(floor_val, 100, "3600s at 100/hr should return floor 100")
	assert_almost_eq(impl.meta_state.total_gold, 100.0, 0.001, "total_gold should be 100.0")


func test_tick_gold_small_delta_floor_zero() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	var floor_val: int = impl.tick_gold(1.0, 100.0)
	assert_eq(floor_val, 0, "1s at 100/hr is less than 1 gold — floor is 0")


func test_tick_gold_does_not_update_timestamp() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 99999
	impl.tick_gold(3600.0, 100.0)
	assert_eq(impl.meta_state.gold_last_saved_timestamp, 99999,
		"tick_gold must not write gold_last_saved_timestamp")


func test_tick_gold_accumulates_across_calls() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	for _i in 3600:
		impl.tick_gold(1.0, 100.0)
	assert_almost_eq(impl.meta_state.total_gold, 100.0, 0.001,
		"3600 calls of 1s each should accumulate 100 gold")


# --- apply_offline_gold ---

func test_apply_offline_gold_new_player_no_credit() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	# timestamp == 0 → first-boot init, no gold credited
	impl.apply_offline_gold(1000000, 100.0, 14400, fake_save)
	assert_eq(impl.meta_state.total_gold, 0.0, "new player (timestamp=0) gets no offline gold")
	fake_save.queue_free()


func test_apply_offline_gold_clock_rollback_no_credit() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 2000000
	# elapsed = 1000000 - 2000000 = -1000000 → early return
	impl.apply_offline_gold(1000000, 100.0, 14400, null)
	assert_eq(impl.meta_state.total_gold, 0.0, "clock rollback gives 0 gold")


func test_apply_offline_gold_zero_elapsed_no_credit() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 1000000
	impl.apply_offline_gold(1000000, 100.0, 14400, null)
	assert_eq(impl.meta_state.total_gold, 0.0, "zero elapsed gives 0 gold")


func test_apply_offline_gold_one_hour() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 1000000
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	impl.apply_offline_gold(1000000 + 3600, 100.0, 14400, fake_save)
	assert_almost_eq(impl.meta_state.total_gold, 100.0, 0.001,
		"3600s offline at 100/hr should credit 100 gold")
	fake_save.queue_free()


func test_apply_offline_gold_half_hour() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 1000000
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	impl.apply_offline_gold(1000000 + 1800, 100.0, 14400, fake_save)
	assert_almost_eq(impl.meta_state.total_gold, 50.0, 0.001,
		"1800s offline at 100/hr should credit 50 gold")
	fake_save.queue_free()


func test_apply_offline_gold_updates_timestamp() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 1000000
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	impl.apply_offline_gold(1003600, 100.0, 14400, fake_save)
	assert_gt(impl.meta_state.gold_last_saved_timestamp, 1000000,
		"timestamp should be updated to current time after offline credit")
	fake_save.queue_free()


# --- gold_generator gate ---

func test_tick_gold_gated_returns_floor_without_mutating() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = false
	impl.meta_state.total_gold = 5.7
	var floor_val: int = impl.tick_gold(3600.0, 100.0)
	assert_eq(floor_val, 5, "gate: tick_gold should return current floor (5) without accumulating")
	assert_almost_eq(impl.meta_state.total_gold, 5.7, 0.001,
		"gate: tick_gold must not mutate total_gold when generator not owned")


func test_tick_gold_gated_zero_balance_stays_zero() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = false
	impl.tick_gold(3600.0, 100.0)
	assert_almost_eq(impl.meta_state.total_gold, 0.0, 0.001,
		"gate: total_gold must remain 0 when generator not owned")


func test_tick_gold_resumes_after_gate_cleared() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = false
	impl.tick_gold(3600.0, 100.0)
	impl.meta_state.gold_generator_owned = true
	var floor_val: int = impl.tick_gold(3600.0, 100.0)
	assert_eq(floor_val, 100, "after gate cleared, tick_gold should accumulate normally")


func test_apply_offline_gold_gated_no_credit() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = false
	impl.meta_state.gold_last_saved_timestamp = 1000000
	impl.apply_offline_gold(1003600, 100.0, 14400, null)
	assert_almost_eq(impl.meta_state.total_gold, 0.0, 0.001,
		"gate: apply_offline_gold must award 0 gold when generator not owned")


func test_apply_offline_gold_gated_timestamp_not_advanced() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = false
	impl.meta_state.gold_last_saved_timestamp = 1000000
	impl.apply_offline_gold(1003600, 100.0, 14400, null)
	assert_eq(impl.meta_state.gold_last_saved_timestamp, 1000000,
		"gate: apply_offline_gold must not advance timestamp when generator not owned")


# --- purchase_gold_generator ---

func test_purchase_gold_generator_success() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 100
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	var result: bool = impl.purchase_gold_generator(50, fake_save)
	assert_true(result, "purchase should succeed with sufficient shards")
	assert_true(impl.meta_state.gold_generator_owned, "flag should be set after purchase")
	assert_eq(impl.meta_state.total_shards, 50, "shards should be deducted")
	fake_save.queue_free()


func test_purchase_gold_generator_insufficient_shards() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 30
	var result: bool = impl.purchase_gold_generator(50, null)
	assert_false(result, "purchase should fail with insufficient shards")
	assert_false(impl.meta_state.gold_generator_owned, "flag must not be set on failure")
	assert_eq(impl.meta_state.total_shards, 30, "shards must not be deducted on failure")


func test_purchase_gold_generator_idempotent() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 200
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	impl.purchase_gold_generator(50, fake_save)
	var second: bool = impl.purchase_gold_generator(50, fake_save)
	assert_false(second, "second purchase should return false")
	assert_eq(impl.meta_state.total_shards, 150, "shards should only be deducted once")
	fake_save.queue_free()


func test_purchase_gold_generator_exact_balance() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 50
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	var result: bool = impl.purchase_gold_generator(50, fake_save)
	assert_true(result, "purchase should succeed when shards equal exactly the cost")
	assert_eq(impl.meta_state.total_shards, 0, "balance reaches 0 after exact spend")
	fake_save.queue_free()


# --- cap enforcement (T004) ---

func test_apply_offline_gold_over_cap_is_clamped() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 1000000
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	# 6 hours elapsed, 4 hour cap (14400 s) → only 4h gold credited
	impl.apply_offline_gold(1000000 + 21600, 100.0, 14400, fake_save)
	assert_almost_eq(impl.meta_state.total_gold, 400.0, 0.001,
		"6h elapsed with 4h cap should credit only 400 gold (4 × 100)")
	fake_save.queue_free()


func test_apply_offline_gold_under_cap_not_clamped() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 1000000
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	# 2 hours elapsed, 4 hour cap → full 2h credited
	impl.apply_offline_gold(1000000 + 7200, 100.0, 14400, fake_save)
	assert_almost_eq(impl.meta_state.total_gold, 200.0, 0.001,
		"2h elapsed under 4h cap should credit full 200 gold")
	fake_save.queue_free()


func test_apply_offline_gold_exactly_at_cap() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 1000000
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	# exactly at cap — should credit full cap amount
	impl.apply_offline_gold(1000000 + 14400, 100.0, 14400, fake_save)
	assert_almost_eq(impl.meta_state.total_gold, 400.0, 0.001,
		"exactly at cap should credit 400 gold")
	fake_save.queue_free()


func test_apply_offline_gold_updates_timestamp_to_now() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 1000000
	var fake_save := FakeSaveManager.new()
	add_child(fake_save)
	impl.apply_offline_gold(1003600, 100.0, 14400, fake_save)
	assert_gt(impl.meta_state.gold_last_saved_timestamp, 1000000,
		"timestamp must be advanced beyond old value after crediting gold")
	fake_save.queue_free()


func test_apply_offline_gold_first_boot_sets_timestamp() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	# timestamp == 0 → first boot: no gold, but timestamp set to now_unix
	var stub := StubSaveManager.new()
	add_child(stub)
	impl.apply_offline_gold(5000000, 100.0, 14400, stub)
	assert_eq(impl.meta_state.total_gold, 0.0, "first boot must not credit gold")
	assert_gt(impl.meta_state.gold_last_saved_timestamp, 0,
		"first boot must set timestamp to current time")
	stub.queue_free()


func test_apply_offline_gold_clock_rollback_no_timestamp_update() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_generator_owned = true
	impl.meta_state.gold_last_saved_timestamp = 2000000
	# clock rollback — elapsed is negative
	impl.apply_offline_gold(1000000, 100.0, 14400, null)
	assert_eq(impl.meta_state.gold_last_saved_timestamp, 2000000,
		"clock rollback must not update timestamp")


# --- get_gold_storage_cap_seconds (T008) ---

func test_get_gold_storage_cap_seconds_level_0() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_storage_cap_level = 0
	assert_eq(impl.get_gold_storage_cap_seconds(4, 4), 14400,
		"base 4h at level 0 should equal 14400 seconds")


func test_get_gold_storage_cap_seconds_level_1() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_storage_cap_level = 1
	assert_eq(impl.get_gold_storage_cap_seconds(4, 4), 28800,
		"4h + 4h per level at level 1 should equal 28800 seconds")


func test_get_gold_storage_cap_seconds_level_2() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.gold_storage_cap_level = 2
	assert_eq(impl.get_gold_storage_cap_seconds(4, 4), 43200,
		"4h + 2×4h at level 2 should equal 43200 seconds (12h)")


# --- purchase_gold_storage_cap (T008) ---

func test_purchase_gold_storage_cap_success() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 200
	var stub := StubSaveManager.new()
	add_child(stub)
	var result: bool = impl.purchase_gold_storage_cap(100, 2, stub)
	assert_true(result, "purchase should succeed with sufficient shards")
	assert_eq(impl.meta_state.gold_storage_cap_level, 1, "level should increment to 1")
	assert_eq(impl.meta_state.total_shards, 100, "100 shards should be deducted")
	assert_true(stub.saved, "save must be called on success")
	stub.queue_free()


func test_purchase_gold_storage_cap_insufficient_shards() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 50
	var stub := StubSaveManager.new()
	add_child(stub)
	var result: bool = impl.purchase_gold_storage_cap(100, 2, stub)
	assert_false(result, "purchase should fail with insufficient shards")
	assert_eq(impl.meta_state.gold_storage_cap_level, 0, "level must not change on failure")
	assert_eq(impl.meta_state.total_shards, 50, "shards must not be deducted on failure")
	assert_false(stub.saved, "save must not be called on failure")
	stub.queue_free()


func test_purchase_gold_storage_cap_at_max_returns_false() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 1000
	impl.meta_state.gold_storage_cap_level = 2
	var stub := StubSaveManager.new()
	add_child(stub)
	var result: bool = impl.purchase_gold_storage_cap(100, 2, stub)
	assert_false(result, "purchase should fail when already at max level")
	assert_eq(impl.meta_state.gold_storage_cap_level, 2, "level must not exceed max")
	assert_false(stub.saved, "save must not be called at max level")
	stub.queue_free()


func test_purchase_gold_storage_cap_idempotent_at_max() -> void:
	var impl := MetaManagerImpl.new()
	impl.meta_state = MetaState.new()
	impl.meta_state.total_shards = 1000
	var stub := StubSaveManager.new()
	add_child(stub)
	impl.purchase_gold_storage_cap(100, 1, stub)
	stub.saved = false
	var second: bool = impl.purchase_gold_storage_cap(100, 1, stub)
	assert_false(second, "second purchase at max must return false")
	assert_eq(impl.meta_state.gold_storage_cap_level, 1, "level stays at 1 after second call")
	assert_eq(impl.meta_state.total_shards, 900, "shards deducted only once")
	assert_false(stub.saved, "save not called on second (failed) purchase")
	stub.queue_free()
