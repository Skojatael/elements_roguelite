extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")

const _BASE := {
	"id": "forest_boss_thorns",
	"display_name": "Thornback Charger",
	"max_health": 600.0,
	"damage": 12.0,
	"move_speed": 50.0,
	"detection_range": 800.0,
	"damage_cooldown": 2.0,
}

const _BOSS_FULL := {
	"id": "forest_boss_thorns",
	"display_name": "Thornback Charger",
	"max_health": 600.0,
	"damage": 12.0,
	"move_speed": 50.0,
	"detection_range": 800.0,
	"damage_cooldown": 2.0,
	"scene_path": "res://scenes/combat/enemies/ForestBossThorns.tscn",
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


# --- Parsing from full boss dict ---

func test_from_dict_reads_scene_path() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.scene_path, "res://scenes/combat/enemies/ForestBossThorns.tscn")


func test_from_dict_reads_thorns_on_hit() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_false(d.thorns_on_hit)


func test_from_dict_reads_thorns_directions_six() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.thorns_directions, 6)


func test_from_dict_reads_thorns_damage() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.thorns_damage, 8.0)


func test_from_dict_reads_thorns_speed() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.thorns_speed, 500.0)


func test_from_dict_reads_thorns_range() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.thorns_range, 800.0)


func test_from_dict_reads_thorns_fire_cooldown() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.thorns_fire_cooldown, 0.3)


func test_from_dict_reads_thorns_duration() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.thorns_duration, 3.0)


func test_from_dict_reads_thorns_cooldown_p2() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.thorns_cooldown_p2, 10.0)


func test_from_dict_reads_thorns_cooldown_p3() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.thorns_cooldown_p3, 6.0)


func test_from_dict_reads_recover_duration() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_eq(d.recover_duration, 0.6)


# --- Defaults when keys absent (non-boss enemy) ---

func test_scene_path_defaults_to_empty() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.scene_path, "")


func test_thorns_on_hit_defaults_false() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_false(d.thorns_on_hit)


func test_thorns_directions_defaults_four() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_directions, 4)


func test_thorns_damage_defaults_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_damage, 0.0)


func test_thorns_speed_defaults_400() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_speed, 400.0)


func test_thorns_range_defaults_600() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_range, 600.0)


func test_thorns_fire_cooldown_defaults_half() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_fire_cooldown, 0.5)


func test_thorns_cooldown_p2_defaults_to_ten() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_cooldown_p2, 10.0)


func test_thorns_cooldown_p3_defaults_to_six() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_cooldown_p3, 6.0)


func test_recover_duration_defaults_to_point_six() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.recover_duration, 0.6)


# --- p3 cooldown shorter than p2 (design invariant) ---

func test_p3_cooldown_shorter_than_p2() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_FULL.duplicate())
	assert_true(d.thorns_cooldown_p3 < d.thorns_cooldown_p2)
