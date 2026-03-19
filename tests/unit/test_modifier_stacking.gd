extends GutTest

const RelicManagerImpl = preload("res://scripts/managers/RelicManagerImpl.gd")

const STUB: Dictionary = {
	"relics": {
		"common": {
			"dmg_a": {"name": "DmgA", "effect_stat": "attack_damage", "effect_mult": 1.10},
			"dmg_b": {"name": "DmgB", "effect_stat": "attack_damage", "effect_mult": 1.10},
			"dmg_c": {"name": "DmgC", "effect_stat": "attack_damage", "effect_mult": 1.10},
			"spd_a": {"name": "SpdA", "effect_stat": "attack_speed",  "effect_mult": 1.10},
			"spd_b": {"name": "SpdB", "effect_stat": "attack_speed",  "effect_mult": 1.10},
			"hp_a":  {"name": "HpA",  "effect_stat": "max_health",    "effect_mult": 1.15},
			"hp_b":  {"name": "HpB",  "effect_stat": "max_health",    "effect_mult": 1.15},
			"mv_a":  {"name": "MvA",  "effect_stat": "move_speed",    "effect_mult": 1.15},
			"mv_b":  {"name": "MvB",  "effect_stat": "move_speed",    "effect_mult": 1.15},
		},
		"uncommon": {
			"crit_a": {"name": "CritA", "effect_stat": "crit_chance",      "effect_mult": 0.20},
			"crit_b": {"name": "CritB", "effect_stat": "crit_chance",      "effect_mult": 0.20},
			"cm_a":   {"name": "CmA",   "effect_stat": "crit_multiplier",  "effect_mult": 0.10},
			"cm_b":   {"name": "CmB",   "effect_stat": "crit_multiplier",  "effect_mult": 0.10},
			"dr_a":   {"name": "DrA",   "effect_stat": "damage_reduction", "effect_mult": 0.10},
			"dr_b":   {"name": "DrB",   "effect_stat": "damage_reduction", "effect_mult": 0.10},
		},
	}
}

const STUB_CFG: Dictionary = {}

var _impl: RelicManagerImpl


func before_each() -> void:
	_impl = RelicManagerImpl.new()
	_impl.build_pool(STUB, STUB_CFG)


# --- US1: Relic bonuses stack additively ---

func test_two_same_stat_relics_stack_additively() -> void:
	_impl.pick_relic("dmg_a")
	_impl.pick_relic("dmg_b")
	assert_almost_eq(_impl.compute_stat_mult("attack_damage"), 1.20, 0.0001,
		"two x1.10 attack_damage relics → additive: 1.0 + 0.10 + 0.10 = 1.20")


func test_three_same_stat_relics_stack_additively() -> void:
	_impl.pick_relic("dmg_a")
	_impl.pick_relic("dmg_b")
	_impl.pick_relic("dmg_c")
	assert_almost_eq(_impl.compute_stat_mult("attack_damage"), 1.30, 0.0001,
		"three x1.10 attack_damage relics → additive: 1.0 + 0.10 + 0.10 + 0.10 = 1.30")


func test_zero_relics_returns_neutral() -> void:
	assert_almost_eq(_impl.compute_stat_mult("attack_damage"), 1.0, 0.0001,
		"zero relics → neutral factor 1.0")


func test_one_relic_returns_effect_mult() -> void:
	_impl.pick_relic("dmg_a")
	assert_almost_eq(_impl.compute_stat_mult("attack_damage"), 1.10, 0.0001,
		"one x1.10 relic → 1.0 + 0.10 = 1.10")


func test_mixed_stat_damage_mult_not_contaminated_by_speed_relic() -> void:
	_impl.pick_relic("dmg_a")
	_impl.pick_relic("spd_a")
	assert_almost_eq(_impl.compute_stat_mult("attack_damage"), 1.10, 0.0001,
		"speed relic must not contribute to damage mult")


func test_mixed_stat_speed_mult_not_contaminated_by_damage_relic() -> void:
	_impl.pick_relic("dmg_a")
	_impl.pick_relic("spd_a")
	assert_almost_eq(_impl.compute_stat_mult("attack_speed"), 1.10, 0.0001,
		"damage relic must not contribute to speed mult")


# --- US2: Cross-source bonuses multiply ---

func test_cross_source_two_relics_plus_upgrade_factor() -> void:
	_impl.pick_relic("dmg_a")
	_impl.pick_relic("dmg_b")
	var relic_factor: float = _impl.compute_stat_mult("attack_damage")  # 1.20 additive
	var upgrade_factor: float = 1.0 + 1.0 * 0.10                       # 1.10 meta upgrade
	assert_almost_eq(relic_factor * upgrade_factor, 1.32, 0.001,
		"two x1.10 relics (1.20) × upgrade x1.10 → 1.32")


func test_cross_source_zero_relics_upgrade_only() -> void:
	var relic_factor: float = _impl.compute_stat_mult("attack_damage")  # 1.0 (no relics)
	var upgrade_factor: float = 1.10
	assert_almost_eq(relic_factor * upgrade_factor, 1.10, 0.0001,
		"zero relics → relic factor 1.0; combined equals upgrade factor only")


# --- US3: All mult-path stats stack additively ---

func test_max_health_two_relics_stack_additively() -> void:
	_impl.pick_relic("hp_a")
	_impl.pick_relic("hp_b")
	assert_almost_eq(_impl.compute_stat_mult("max_health"), 1.30, 0.0001,
		"two x1.15 max_health relics → additive: 1.0 + 0.15 + 0.15 = 1.30")


func test_move_speed_two_relics_stack_additively() -> void:
	_impl.pick_relic("mv_a")
	_impl.pick_relic("mv_b")
	assert_almost_eq(_impl.compute_stat_mult("move_speed"), 1.30, 0.0001,
		"two x1.15 move_speed relics → additive: 1.0 + 0.15 + 0.15 = 1.30")


func test_attack_speed_two_relics_stack_additively() -> void:
	_impl.pick_relic("spd_a")
	_impl.pick_relic("spd_b")
	assert_almost_eq(_impl.compute_stat_mult("attack_speed"), 1.20, 0.0001,
		"two x1.10 attack_speed relics → additive: 1.0 + 0.10 + 0.10 = 1.20")


# --- US3: Addend-path stats regression (already additive — must remain so) ---

func test_crit_chance_two_relics_stack_additively() -> void:
	_impl.pick_relic("crit_a")
	_impl.pick_relic("crit_b")
	assert_almost_eq(_impl.compute_stat_addend("crit_chance"), 0.40, 0.0001,
		"two +0.20 crit_chance relics → additive sum: 0.40")


func test_damage_reduction_two_relics_stack_additively() -> void:
	_impl.pick_relic("dr_a")
	_impl.pick_relic("dr_b")
	assert_almost_eq(_impl.compute_stat_addend("damage_reduction"), 0.20, 0.0001,
		"two +0.10 damage_reduction relics → additive sum: 0.20")


func test_crit_multiplier_two_relics_stack_additively() -> void:
	_impl.pick_relic("cm_a")
	_impl.pick_relic("cm_b")
	assert_almost_eq(_impl.compute_stat_addend("crit_multiplier"), 0.20, 0.0001,
		"two +0.10 crit_multiplier relics → additive sum: 0.20")
