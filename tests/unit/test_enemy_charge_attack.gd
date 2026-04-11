extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")

const _BASE := {
	"id": "test_charger",
	"display_name": "Charger",
	"max_health": 100.0,
	"damage": 5.0,
	"move_speed": 60.0,
	"detection_range": 400.0,
	"damage_cooldown": 1.5,
}


# --- EnemyData charge field parsing ---

func test_from_dict_reads_all_charge_fields() -> void:
	var data := _BASE.duplicate()
	data["charge_attack_damage"] = 25.0
	data["charge_attack_cooldown"] = 8.0
	data["charge_attack_length"] = 300.0
	var d: EnemyData = EnemyData.from_dict(data)
	assert_eq(d.charge_attack_damage, 25.0)
	assert_eq(d.charge_attack_cooldown, 8.0)
	assert_eq(d.charge_attack_length, 300.0)


func test_from_dict_charge_fields_default_to_zero() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	assert_eq(d.charge_attack_damage, 0.0)
	assert_eq(d.charge_attack_cooldown, 0.0)
	assert_eq(d.charge_attack_length, 0.0)


func test_charge_cooldown_zero_is_opt_out_sentinel() -> void:
	var d: EnemyData = EnemyData.from_dict(_BASE.duplicate())
	# A cooldown of 0.0 means "no charge attack"; the check in Enemy.gd guards on > 0.0.
	assert_true(d.charge_attack_cooldown == 0.0)


# --- Cooldown field non-zero when explicitly set ---

func test_charge_attack_cooldown_nonzero() -> void:
	var data := _BASE.duplicate()
	data["charge_attack_cooldown"] = 5.0
	var d: EnemyData = EnemyData.from_dict(data)
	assert_true(d.charge_attack_cooldown > 0.0)


# --- forest_boss_thorns JSON values ---

func test_forest_boss_thorns_has_charge_params() -> void:
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	assert_not_null(file, "enemies.json must be readable")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert_true(parsed is Dictionary, "root must be Dictionary")

	var boss_dict: Variant = (parsed as Dictionary).get("boss", {})
	assert_true(boss_dict is Dictionary, "boss tier must be a Dictionary")
	var forest_dict: Variant = (boss_dict as Dictionary).get("forest", {})
	assert_true(forest_dict is Dictionary, "boss.forest must be a Dictionary")
	var entry: Variant = (forest_dict as Dictionary).get("forest_boss_thorns", {})
	assert_true(entry is Dictionary and not (entry as Dictionary).is_empty(),
		"forest_boss_thorns must exist in enemies.json")

	assert_eq(int((entry as Dictionary)["charge_attack_damage"]), 10)
	assert_eq(int((entry as Dictionary)["charge_attack_cooldown"]), 10)
	assert_eq(int((entry as Dictionary)["charge_attack_length"]), 10)


func test_non_charge_enemy_has_zero_charge_fields() -> void:
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	assert_not_null(file, "enemies.json must be readable")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	var normal_dict: Variant = (parsed as Dictionary).get("normal", {})
	assert_true(normal_dict is Dictionary, "normal tier must be a Dictionary")
	var forest_dict: Variant = (normal_dict as Dictionary).get("forest", {})
	assert_true(forest_dict is Dictionary, "normal.forest must be a Dictionary")
	var entry: Variant = (forest_dict as Dictionary).get("forest_tank", {})
	assert_true(entry is Dictionary and not (entry as Dictionary).is_empty(),
		"forest_tank must exist in enemies.json")

	var data: Dictionary = (entry as Dictionary).duplicate()
	data["id"] = "forest_tank"
	var d: EnemyData = EnemyData.from_dict(data)
	assert_eq(d.charge_attack_damage, 0.0)
	assert_eq(d.charge_attack_cooldown, 0.0)
	assert_eq(d.charge_attack_length, 0.0)
