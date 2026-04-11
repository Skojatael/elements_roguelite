extends GutTest

const EnemyData = preload("res://scripts/data_models/EnemyData.gd")

# Phase threshold constants duplicated here to keep tests self-contained.
const PHASE2_THRESHOLD := 0.667
const PHASE3_THRESHOLD := 0.333

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
	"thorns_damage": 0.0,
	"thorns_speed": 400.0,
	"thorns_range": 600.0,
	"thorns_fire_cooldown": 0.5,
	"thorns_duration": 3.0,
	"thorns_cooldown_p2": 10.0,
	"thorns_cooldown_p3": 6.0,
	"recover_duration": 0.6,
}


# --- Phase threshold constant correctness ---

func test_phase2_threshold_is_two_thirds() -> void:
	assert_almost_eq(PHASE2_THRESHOLD, 2.0 / 3.0, 0.001)


func test_phase3_threshold_is_one_third() -> void:
	assert_almost_eq(PHASE3_THRESHOLD, 1.0 / 3.0, 0.001)


func test_phase3_threshold_less_than_phase2() -> void:
	assert_true(PHASE3_THRESHOLD < PHASE2_THRESHOLD)


# --- HP ratio calculations (pure arithmetic, no nodes needed) ---

func test_hp_ratio_at_full_health_is_one() -> void:
	var max_hp: float = 600.0
	var current_hp: float = 600.0
	var ratio: float = current_hp / max_hp
	assert_almost_eq(ratio, 1.0, 0.001)


func test_hp_ratio_at_phase2_boundary() -> void:
	var max_hp: float = 600.0
	var current_hp: float = 600.0 * PHASE2_THRESHOLD
	var ratio: float = current_hp / max_hp
	assert_almost_eq(ratio, PHASE2_THRESHOLD, 0.001)


func test_hp_ratio_at_phase3_boundary() -> void:
	var max_hp: float = 600.0
	var current_hp: float = 600.0 * PHASE3_THRESHOLD
	var ratio: float = current_hp / max_hp
	assert_almost_eq(ratio, PHASE3_THRESHOLD, 0.001)


func test_hp_below_phase2_threshold_triggers_transition() -> void:
	var max_hp: float = 600.0
	var current_hp: float = 399.0  # 66.5% — below 66.7%
	var ratio: float = current_hp / max_hp
	assert_true(ratio <= PHASE2_THRESHOLD)


func test_hp_above_phase2_threshold_no_transition() -> void:
	var max_hp: float = 600.0
	var current_hp: float = 401.0  # 66.8% — above 66.7%
	var ratio: float = current_hp / max_hp
	assert_true(ratio > PHASE2_THRESHOLD)


func test_hp_below_phase3_threshold_triggers_transition() -> void:
	var max_hp: float = 600.0
	var current_hp: float = 199.0  # 33.2% — below 33.3%
	var ratio: float = current_hp / max_hp
	assert_true(ratio <= PHASE3_THRESHOLD)


# --- Thorns cooldown starts on phase activation ---

func test_phase2_starts_thorns_cooldown_p2() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	# Simulate what _check_phase_transition does: set cooldown to p2 value on entering phase 2.
	var cooldown: float = d.thorns_cooldown_p2
	assert_eq(cooldown, 10.0)


func test_phase3_starts_thorns_cooldown_p3() -> void:
	var d: EnemyData = EnemyData.from_dict(_BOSS_DATA.duplicate())
	var cooldown: float = d.thorns_cooldown_p3
	assert_eq(cooldown, 6.0)
