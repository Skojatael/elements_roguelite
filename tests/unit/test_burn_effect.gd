extends GutTest

const BurnEffect = preload("res://scripts/data_models/BurnEffect.gd")

var _burn: BurnEffect


func before_each() -> void:
	_burn = BurnEffect.new()


# --- apply() ---

func test_apply_sets_tick_damage_and_duration() -> void:
	_burn.apply(5.0, 2.0)
	assert_almost_eq(_burn.tick_damage, 5.0, 0.0001, "apply must store tick_damage")
	assert_almost_eq(_burn.remaining_duration, 2.0, 0.0001, "apply must store remaining_duration")


func test_apply_sets_tick_timer_to_one_second() -> void:
	_burn.apply(5.0, 2.0)
	assert_almost_eq(_burn._seconds_until_next_tick, 1.0, 0.0001, "apply must reset tick timer to 1.0")


# --- is_active() ---

func test_is_active_false_before_apply() -> void:
	assert_false(_burn.is_active(), "fresh BurnEffect must not be active")


func test_is_active_true_after_apply() -> void:
	_burn.apply(5.0, 2.0)
	assert_true(_burn.is_active(), "after apply must be active")


func test_is_active_false_after_duration_expires() -> void:
	_burn.apply(5.0, 0.5)
	_burn.process(0.5)
	assert_false(_burn.is_active(), "is_active must return false once remaining_duration reaches 0")


# --- process() tick timing ---

func test_first_tick_does_not_fire_at_0_9s() -> void:
	_burn.apply(5.0, 2.0)
	var dmg: float = _burn.process(0.9)
	assert_almost_eq(dmg, 0.0, 0.0001, "tick must not fire before 1.0s elapsed")


func test_first_tick_fires_at_exactly_1_0s() -> void:
	_burn.apply(5.0, 2.0)
	_burn.process(0.9)
	var dmg: float = _burn.process(0.1)
	assert_almost_eq(dmg, 5.0, 0.0001, "tick must fire at exactly 1.0s")


func test_second_tick_fires_at_2_0s() -> void:
	_burn.apply(5.0, 3.0)
	_burn.process(1.0)  # first tick
	var dmg: float = _burn.process(1.0)  # second tick
	assert_almost_eq(dmg, 5.0, 0.0001, "second tick must fire at t=2.0s")


func test_process_returns_zero_when_inactive() -> void:
	var dmg: float = _burn.process(1.0)
	assert_almost_eq(dmg, 0.0, 0.0001, "process must return 0.0 when inactive")


func test_process_no_tick_between_seconds() -> void:
	_burn.apply(5.0, 3.0)
	_burn.process(1.0)  # first tick
	var dmg: float = _burn.process(0.5)  # mid-second, no tick
	assert_almost_eq(dmg, 0.0, 0.0001, "process must return 0.0 between tick intervals")


# --- extend() ---

func test_extend_adds_to_remaining_duration() -> void:
	_burn.apply(5.0, 2.0)
	_burn.extend(2.0)
	assert_almost_eq(_burn.remaining_duration, 4.0, 0.0001, "extend must add seconds to remaining_duration")


func test_extend_noop_when_amount_zero() -> void:
	_burn.apply(5.0, 2.0)
	_burn.extend(0.0)
	assert_almost_eq(_burn.remaining_duration, 2.0, 0.0001, "extend(0) must be a no-op")


func test_extend_noop_when_amount_negative() -> void:
	_burn.apply(5.0, 2.0)
	_burn.extend(-1.0)
	assert_almost_eq(_burn.remaining_duration, 2.0, 0.0001, "extend with negative value must be a no-op")


# --- re-hit behaviour (simulated via apply/extend directly) ---

func test_re_hit_on_active_burn_extends_duration() -> void:
	_burn.apply(5.0, 2.0)
	_burn.process(0.5)  # burn is active, 1.5s remaining
	_burn.extend(2.0)
	assert_true(_burn.remaining_duration > 2.0, "re-hit on active burn must increase duration beyond 2s")


func test_re_hit_on_expired_burn_fresh_apply() -> void:
	_burn.apply(5.0, 0.5)
	_burn.process(0.5)  # expire
	assert_false(_burn.is_active(), "burn must be expired")
	_burn.apply(5.0, 2.0)
	assert_true(_burn.is_active(), "re-applying on expired burn must activate it fresh")
	assert_almost_eq(_burn.remaining_duration, 2.0, 0.0001, "fresh apply must set full duration")
