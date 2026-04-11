extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")

const _BOSS_DATA := {
	"id": "forest_boss_thorns",
	"display_name": "Thornback Charger",
	"max_health": 600.0,
	"damage": 12.0,
	"move_speed": 50.0,
	"detection_range": 800.0,
	"damage_cooldown": 2.0,
	"shield_hp": 200,
	"shield_stun_duration": 3.0,
	"scene_path": "",
	"charge_attack_damage": 0.0,
	"charge_attack_cooldown": 0.0,
	"charge_attack_length": 0.0,
	"thorns_on_hit": false,
	"thorns_directions": 6,
	"thorns_damage": 0.0,
	"thorns_speed": 400.0,
	"thorns_range": 600.0,
	"thorns_fire_cooldown": 0.5,
	"thorns_duration": 3.0,
	"thorns_cooldown_p2": 10.0,
	"thorns_cooldown_p3": 6.0,
	"recover_duration": 0.6,
}


# --- Shield data parsing ---

func test_shield_hp_parsed_correctly() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_eq(d.shield_hp, 200)


func test_shield_stun_duration_parsed_correctly() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_eq(d.shield_stun_duration, 3.0)


func test_shield_hp_defaults_to_zero_for_normal_enemy() -> void:
	var minimal := {
		"id": "forest_tank",
		"display_name": "Bramble Beast",
		"max_health": 80.0,
		"damage": 10.0,
		"move_speed": 60.0,
		"detection_range": 800.0,
		"damage_cooldown": 1.4,
	}
	var d: EnemyData = EnemyData.from_dict(minimal)
	assert_eq(d.shield_hp, 0)


func test_shield_stun_duration_default_three() -> void:
	var data := _BOSS_DATA.duplicate()
	data.erase("shield_stun_duration")
	var d: EnemyData = EnemyData.from_dict(data)
	assert_eq(d.shield_stun_duration, 3.0)


# --- Shield HP > 0 means shield is present ---

func test_shield_present_when_hp_positive() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.shield_hp > 0)


# --- Stun duration is longer than recover duration (design invariant) ---

func test_stun_longer_than_recover() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.shield_stun_duration > d.recover_duration)
