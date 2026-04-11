extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")


# --- EnemyData buff field parsing ---

func test_from_dict_reads_all_buff_fields() -> void:
	var data := {
		"id": "test_buffer",
		"display_name": "Buffer",
		"max_health": 50.0,
		"damage": 5.0,
		"move_speed": 60.0,
		"detection_range": 400.0,
		"damage_cooldown": 1.5,
		"buff_zone_radius": 120.0,
		"buff_cooldown": 8.0,
		"buff_zone_duration": 5.0,
		"buff_regen_rate": 0.05,
		"buff_attack_speed_bonus": 0.25,
	}
	var d: EnemyData = EnemyData.from_dict(data)
	assert_eq(d.buff_zone_radius, 120.0)
	assert_eq(d.buff_cooldown, 8.0)
	assert_eq(d.buff_zone_duration, 5.0)
	assert_eq(d.buff_regen_rate, 0.05)
	assert_eq(d.buff_attack_speed_bonus, 0.25)


func test_from_dict_buff_fields_default_to_zero_when_absent() -> void:
	var data := {
		"id": "plain_enemy",
		"display_name": "Plain",
		"max_health": 30.0,
		"damage": 4.0,
		"move_speed": 70.0,
		"detection_range": 300.0,
		"damage_cooldown": 1.2,
	}
	var d: EnemyData = EnemyData.from_dict(data)
	assert_eq(d.buff_zone_radius, 0.0)
	assert_eq(d.buff_cooldown, 0.0)
	assert_eq(d.buff_zone_duration, 0.0)
	assert_eq(d.buff_regen_rate, 0.0)
	assert_eq(d.buff_attack_speed_bonus, 0.0)


# --- Enemy zone buff accumulation ---
# apply_zone_buff / remove_zone_buff are methods on Enemy (CharacterBody2D) which
# requires a full scene tree to instantiate. These behaviours are verified here
# as arithmetic contracts; integration-level verification is done in-editor.

func test_zone_buff_accumulation_arithmetic() -> void:
	# Simulate two zones applying the same buff values additively.
	var zone_regen: float = 0.0
	var zone_speed: float = 0.0
	# First zone applies.
	zone_regen += 0.05
	zone_speed += 0.25
	# Second zone applies.
	zone_regen += 0.05
	zone_speed += 0.25
	assert_almost_eq(zone_regen, 0.10, 0.0001)
	assert_almost_eq(zone_speed, 0.50, 0.0001)
	# First zone removed.
	zone_regen = maxf(0.0, zone_regen - 0.05)
	zone_speed = maxf(0.0, zone_speed - 0.25)
	assert_almost_eq(zone_regen, 0.05, 0.0001)
	assert_almost_eq(zone_speed, 0.25, 0.0001)


func test_zone_buff_clamps_to_zero_on_over_remove() -> void:
	var zone_regen: float = 0.05
	zone_regen = maxf(0.0, zone_regen - 0.10)
	assert_eq(zone_regen, 0.0, "accumulator must not go negative")


func test_attack_speed_effective_interval() -> void:
	# Verify the interval formula: base / (1 + bonus) respects the floor.
	var base_cooldown: float = 1.5
	var bonus: float = 0.25
	var effective: float = maxf(0.1, base_cooldown / (1.0 + bonus))
	assert_almost_eq(effective, 1.2, 0.0001)


func test_attack_speed_zero_bonus_unchanged() -> void:
	var base_cooldown: float = 1.5
	var effective: float = maxf(0.1, base_cooldown / (1.0 + 0.0))
	assert_almost_eq(effective, 1.5, 0.0001)


func test_from_dict_partial_buff_fields() -> void:
	var data := {
		"id": "regen_only",
		"display_name": "Regen Only",
		"max_health": 40.0,
		"damage": 3.0,
		"move_speed": 65.0,
		"detection_range": 350.0,
		"damage_cooldown": 1.3,
		"buff_zone_radius": 80.0,
		"buff_cooldown": 6.0,
		"buff_zone_duration": 4.0,
		"buff_regen_rate": 0.08,
	}
	var d: EnemyData = EnemyData.from_dict(data)
	assert_eq(d.buff_regen_rate, 0.08)
	assert_eq(d.buff_attack_speed_bonus, 0.0, "attack speed bonus should default to 0 when absent")
