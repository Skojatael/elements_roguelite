extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")

# Minimal boss data for charge tests.
const _BOSS_DATA := {
	"id": "forest_boss_thorns",
	"display_name": "Thornback Charger",
	"max_health": 600.0,
	"damage": 12.0,
	"move_speed": 50.0,
	"detection_range": 800.0,
	"damage_cooldown": 2.0,
	"charge_attack_damage": 20.0,
	"charge_attack_cooldown": 5.0,
	"charge_attack_length": 200.0,
	"charge_telegraph_duration": 0.1,
	"charge_speed_mult": 3.0,
	"recover_duration": 0.1,
	"shield_hp": 0,
	"shield_stun_duration": 3.0,
	"scene_path": "",
	"thorns_on_hit": false,
	"thorns_directions": 6,
	"thorns_damage": 0.0,
	"thorns_speed": 400.0,
	"thorns_range": 600.0,
	"thorns_fire_cooldown": 0.5,
	"thorns_duration": 3.0,
	"thorns_cooldown_p2": 10.0,
	"thorns_cooldown_p3": 6.0,
}


# --- EnemyData charge cooldown behaviour ---

func test_charge_cooldown_non_zero_when_set() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.charge_attack_cooldown > 0.0)


func test_charge_telegraph_duration_non_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.charge_telegraph_duration > 0.0)


func test_charge_attack_length_non_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.charge_attack_length > 0.0)


func test_recover_duration_non_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.recover_duration > 0.0)


func test_charge_attack_damage_non_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.charge_attack_damage > 0.0)


# --- charge_speed_mult > 1.0 (boss must move faster than normal) ---

func test_charge_speed_mult_greater_than_one() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.charge_speed_mult > 1.0)


# --- recover_duration defaults ---

func test_recover_duration_default_is_point_six() -> void:
	var minimal := _BOSS_DATA.duplicate()
	minimal.erase("recover_duration")
	var d: EnemyData = EnemyData.from_dict(minimal)
	assert_eq(d.recover_duration, 0.6)
