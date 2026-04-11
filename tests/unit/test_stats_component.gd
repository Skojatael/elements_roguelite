extends GutTest

const StatsComponent = preload("res://scenes/player/components/StatsComponent.gd")


# compute_reduced_damage — pure static, no autoloads.

func test_compute_reduced_damage_zero_reduction() -> void:
	var result: float = StatsComponent.compute_reduced_damage(10.0, 0.0)
	assert_eq(result, 10.0)


func test_compute_reduced_damage_full_reduction() -> void:
	var result: float = StatsComponent.compute_reduced_damage(10.0, 1.0)
	assert_eq(result, 0.0)


func test_compute_reduced_damage_partial_reduction() -> void:
	var result: float = StatsComponent.compute_reduced_damage(10.0, 0.5)
	assert_eq(result, 5.0)


# regen_tick_amount — pure static.

func test_regen_tick_amount_basic() -> void:
	var result: float = StatsComponent.regen_tick_amount(0.1, 100.0, 1.0)
	assert_almost_eq(result, 10.0, 0.001)


func test_regen_tick_amount_zero_rate() -> void:
	var result: float = StatsComponent.regen_tick_amount(0.0, 100.0, 1.0)
	assert_eq(result, 0.0)


# apply_regen_clamp — pure static.

func test_apply_regen_clamp_does_not_exceed_max() -> void:
	var result: float = StatsComponent.apply_regen_clamp(95.0, 10.0, 100.0)
	assert_eq(result, 100.0)


func test_apply_regen_clamp_below_max() -> void:
	var result: float = StatsComponent.apply_regen_clamp(80.0, 5.0, 100.0)
	assert_almost_eq(result, 85.0, 0.001)


# reflect — take_damage with optional attacker parameter.
# is_player = false avoids autoload calls in _ready().

func test_reflect_fires_to_attacker() -> void:
	var receiver: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	receiver.max_health = 100.0
	receiver.current_health = 100.0
	receiver.reflect_amount = 0.5

	var attacker: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	attacker.max_health = 100.0
	attacker.current_health = 100.0

	receiver.take_damage(20.0, attacker)

	assert_eq(receiver.current_health, 80.0)
	assert_eq(attacker.current_health, 90.0)  # floori(20 * 0.5) = 10 reflected


func test_reflect_no_fire_when_attacker_null() -> void:
	var receiver: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	receiver.max_health = 100.0
	receiver.current_health = 100.0
	receiver.reflect_amount = 0.5

	receiver.take_damage(20.0)

	assert_eq(receiver.current_health, 80.0)


func test_reflect_no_fire_when_reflect_amount_zero() -> void:
	var receiver: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	receiver.max_health = 100.0
	receiver.current_health = 100.0

	var attacker: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	attacker.max_health = 100.0
	attacker.current_health = 100.0

	receiver.take_damage(20.0, attacker)

	assert_eq(attacker.current_health, 100.0)


func test_reflect_does_not_chain() -> void:
	# attacker also has reflect_amount > 0; the reflect call passes null → no second reflect
	var receiver: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	receiver.max_health = 100.0
	receiver.current_health = 100.0
	receiver.reflect_amount = 0.5

	var attacker: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	attacker.max_health = 100.0
	attacker.current_health = 100.0
	attacker.reflect_amount = 0.5  # would chain if not prevented

	receiver.take_damage(20.0, attacker)

	# receiver took 20, reflected 10 to attacker; attacker took 10 (no further reflect)
	assert_eq(receiver.current_health, 80.0)
	assert_eq(attacker.current_health, 90.0)


func test_reflect_respects_attacker_damage_reduction() -> void:
	var receiver: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	receiver.max_health = 100.0
	receiver.current_health = 100.0
	receiver.reflect_amount = 1.0

	var attacker: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	attacker.max_health = 100.0
	attacker.current_health = 100.0
	attacker.damage_reduction = 0.5  # attacker absorbs 50% of reflected damage

	receiver.take_damage(20.0, attacker)

	# reflect sends floori(20*1.0)=20 to attacker, attacker DR halves it to 10
	assert_eq(receiver.current_health, 80.0)
	assert_eq(attacker.current_health, 90.0)


func test_reflect_floors_fractional_result() -> void:
	var receiver: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	receiver.max_health = 100.0
	receiver.current_health = 100.0
	receiver.reflect_amount = 0.15

	var attacker: StatsComponent = add_child_autofree(StatsComponent.new()) as StatsComponent
	attacker.max_health = 100.0
	attacker.current_health = 100.0

	receiver.take_damage(7.0, attacker)

	# floori(7 * 0.15) = floori(1.05) = 1
	assert_eq(attacker.current_health, 99.0)
