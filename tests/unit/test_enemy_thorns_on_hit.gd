extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")

const _BASE := {
	"id": "test_enemy",
	"display_name": "Test",
	"max_health": 10.0,
	"damage": 1.0,
	"move_speed": 50.0,
	"detection_range": 100.0,
	"damage_cooldown": 1.0,
}

const _THORNS_FULL := {
	"id": "forest_reflector",
	"display_name": "Thornback",
	"max_health": 50.0,
	"damage": 6.0,
	"move_speed": 70.0,
	"detection_range": 800.0,
	"damage_cooldown": 1.6,
	"thorns_on_hit": true,
	"thorns_directions": 4,
	"thorns_damage": 5.0,
	"thorns_speed": 400.0,
	"thorns_range": 600.0,
	"thorns_fire_cooldown": 0.5,
}


# --- thorns_on_hit ---

func test_thorns_on_hit_reads_true() -> void:
	var d: EnemyData = EnemyData.from_dict(_THORNS_FULL.duplicate())
	assert_true(d.thorns_on_hit)


func test_thorns_on_hit_defaults_false() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_false(d.thorns_on_hit)


# --- thorns_directions ---

func test_thorns_directions_reads_four() -> void:
	var d: EnemyData = EnemyData.from_dict(_THORNS_FULL.duplicate())
	assert_eq(d.thorns_directions, 4)


func test_thorns_directions_defaults_four() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_directions, 4)


# --- thorns_damage ---

func test_thorns_damage_reads_value() -> void:
	var d: EnemyData = EnemyData.from_dict(_THORNS_FULL.duplicate())
	assert_eq(d.thorns_damage, 5.0)


func test_thorns_damage_defaults_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_damage, 0.0)


# --- thorns_speed ---

func test_thorns_speed_reads_value() -> void:
	var d: EnemyData = EnemyData.from_dict(_THORNS_FULL.duplicate())
	assert_eq(d.thorns_speed, 400.0)


func test_thorns_speed_defaults_400() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_speed, 400.0)


# --- thorns_range ---

func test_thorns_range_reads_value() -> void:
	var d: EnemyData = EnemyData.from_dict(_THORNS_FULL.duplicate())
	assert_eq(d.thorns_range, 600.0)


func test_thorns_range_defaults_600() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_range, 600.0)


# --- thorns_fire_cooldown ---

func test_thorns_fire_cooldown_reads_value() -> void:
	var d: EnemyData = EnemyData.from_dict(_THORNS_FULL.duplicate())
	assert_eq(d.thorns_fire_cooldown, 0.5)


func test_thorns_fire_cooldown_defaults_half() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.thorns_fire_cooldown, 0.5)


# --- boss variant: thorns_on_hit false, directions 6 ---

func test_boss_thorns_on_hit_false() -> void:
	var dict := _BASE.duplicate()
	dict["thorns_on_hit"] = false
	dict["thorns_directions"] = 6
	var d: EnemyData = EnemyData.from_dict(dict)
	assert_false(d.thorns_on_hit)
	assert_eq(d.thorns_directions, 6)
