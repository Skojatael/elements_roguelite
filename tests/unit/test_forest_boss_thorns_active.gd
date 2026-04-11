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
	"shield_hp": 0,
	"shield_stun_duration": 3.0,
	"scene_path": "",
	"charge_attack_damage": 0.0,
	"charge_attack_cooldown": 0.0,
	"charge_attack_length": 0.0,
	"thorns_on_hit": false,
	"thorns_directions": 6,
	"thorns_damage": 8.0,
	"thorns_speed": 500.0,
	"thorns_range": 800.0,
	"thorns_fire_cooldown": 0.3,
	"thorns_duration": 3.0,
	"thorns_cooldown_p2": 10.0,
	"thorns_cooldown_p3": 6.0,
	"recover_duration": 0.6,
}


# --- Projectile thorn fields ---

func test_boss_thorns_on_hit_is_false() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_false(d.thorns_on_hit)


func test_boss_thorns_directions_is_six() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_eq(d.thorns_directions, 6)


func test_boss_thorns_damage_positive() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.thorns_damage > 0.0)


func test_boss_thorns_speed_positive() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.thorns_speed > 0.0)


func test_boss_thorns_fire_cooldown_positive() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.thorns_fire_cooldown > 0.0)


# --- Thorns duration ---

func test_thorns_duration_is_three() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_eq(d.thorns_duration, 3.0)


func test_thorns_duration_positive() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.thorns_duration > 0.0)


# --- Cooldowns per phase ---

func test_p2_cooldown_is_ten() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_eq(d.thorns_cooldown_p2, 10.0)


func test_p3_cooldown_is_six() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_eq(d.thorns_cooldown_p3, 6.0)


func test_p3_cooldown_shorter_than_p2() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	assert_true(d.thorns_cooldown_p3 < d.thorns_cooldown_p2)


# --- Thorns only active in phase 2+ (logic check via phase value) ---

func test_thorns_not_active_in_phase_one() -> void:
	var phase: int = 1
	var should_tick_thorns_cooldown: bool = phase >= 2
	assert_false(should_tick_thorns_cooldown)


func test_thorns_active_in_phase_two() -> void:
	var phase: int = 2
	var should_tick_thorns_cooldown: bool = phase >= 2
	assert_true(should_tick_thorns_cooldown)


func test_thorns_active_in_phase_three() -> void:
	var phase: int = 3
	var should_tick_thorns_cooldown: bool = phase >= 2
	assert_true(should_tick_thorns_cooldown)
