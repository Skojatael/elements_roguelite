extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")

const FULL_DICT: Dictionary = {
	"id": "test_enemy",
	"display_name": "Test Enemy",
	"max_health": 100.0,
	"damage": 5.0,
	"move_speed": 60.0,
	"detection_range": 200.0,
	"damage_cooldown": 1.0,
	"regen_rate": 0.02,
	"heal_amount": 8.0,
	"heal_radius": 80.0,
	"heal_cooldown": 3.0,
}

const MINIMAL_DICT: Dictionary = {
	"id": "test_enemy",
	"display_name": "Test Enemy",
	"max_health": 100.0,
	"damage": 5.0,
	"move_speed": 60.0,
	"detection_range": 200.0,
	"damage_cooldown": 1.0,
}


func test_full_dict_populates_regen_rate() -> void:
	var d: EnemyData = EnemyData.from_dict(FULL_DICT)
	assert_eq(d.regen_rate, 0.02)


func test_full_dict_populates_heal_amount() -> void:
	var d: EnemyData = EnemyData.from_dict(FULL_DICT)
	assert_eq(d.heal_amount, 8.0)


func test_full_dict_populates_heal_radius() -> void:
	var d: EnemyData = EnemyData.from_dict(FULL_DICT)
	assert_eq(d.heal_radius, 80.0)


func test_full_dict_populates_heal_cooldown() -> void:
	var d: EnemyData = EnemyData.from_dict(FULL_DICT)
	assert_eq(d.heal_cooldown, 3.0)


func test_missing_fields_default_regen_rate_to_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(MINIMAL_DICT)
	assert_eq(d.regen_rate, 0.0)


func test_missing_fields_default_heal_amount_to_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(MINIMAL_DICT)
	assert_eq(d.heal_amount, 0.0)


func test_missing_fields_default_heal_radius_to_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(MINIMAL_DICT)
	assert_eq(d.heal_radius, 0.0)


func test_missing_fields_default_heal_cooldown_to_five() -> void:
	var d: EnemyData = EnemyData.from_dict(MINIMAL_DICT)
	assert_eq(d.heal_cooldown, 5.0)


func test_zero_heal_cooldown_in_dict_stored_as_is() -> void:
	var dict: Dictionary = MINIMAL_DICT.duplicate()
	dict["heal_cooldown"] = 0
	var d: EnemyData = EnemyData.from_dict(dict)
	assert_eq(d.heal_cooldown, 0.0)
