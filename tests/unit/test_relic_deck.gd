extends GutTest

const RelicManagerImpl = preload("res://scripts/managers/RelicManagerImpl.gd")

const STUB_RELICS: Dictionary = {
	"relics": {
		"common": {
			"relic_a": {"name": "A", "effect_stat": "attack_damage", "effect_mult": 1.10},
			"relic_b": {"name": "B", "effect_stat": "attack_speed",  "effect_mult": 1.05},
			"relic_c": {"name": "C", "effect_stat": "move_speed",    "effect_mult": 1.08},
		},
		"uncommon": {
			"relic_d": {"name": "D", "effect_stat": "attack_damage", "effect_mult": 1.18},
			"relic_e": {"name": "E", "effect_stat": "max_health",    "effect_mult": 1.15},
			"relic_f": {"name": "F", "effect_stat": "move_speed",    "effect_mult": 1.12},
		},
		"rare": {
			"relic_x": {"name": "X", "effect_stat": "attack_damage", "effect_mult": 1.25},
			"relic_y": {"name": "Y", "effect_stat": "max_health",    "effect_mult": 1.30},
		},
	}
}

# Matches data/meta_config.json relic_tier_weights exactly.
# rare is present but excluded from _tier_weights by build_pool — standard draws never yield rare.
const STUB_CFG: Dictionary = {
	"relic_tier_weights": {"common": 0.6, "uncommon": 0.3, "rare": 0.1}
}

var _impl: RelicManagerImpl


func before_each() -> void:
	_impl = RelicManagerImpl.new()
	_impl.build_pool(STUB_RELICS, STUB_CFG)


func test_no_duplicates_single_pass() -> void:
	var a: RelicData = _impl._draw_one()
	var b: RelicData = _impl._draw_one()
	var c: RelicData = _impl._draw_one()
	assert_ne(a.id, b.id, "first and second draws must differ")
	assert_ne(b.id, c.id, "second and third draws must differ")


func test_draw_offer_pair_distinct() -> void:
	for i: int in 10:
		_impl.build_pool(STUB_RELICS, STUB_CFG)
		var offer: Array[RelicData] = _impl.draw_offer()
		assert_eq(offer.size(), 2, "draw_offer should return exactly 2 relics")
		assert_ne(offer[0].id, offer[1].id, "offer pair must contain distinct relics (iteration {i})".format({"i": i}))


func test_draw_offer_never_returns_rare() -> void:
	for i: int in 20:
		var offer: Array[RelicData] = _impl.draw_offer()
		for relic: RelicData in offer:
			assert_ne(relic.tier, "rare", "draw_offer must never return rare relics")


func test_boss_offer_only_rare() -> void:
	var offer: Array[RelicData] = _impl.draw_boss_offer()
	assert_true(offer.size() > 0, "boss offer should contain at least one relic")
	for relic: RelicData in offer:
		assert_eq(relic.tier, "rare", "draw_boss_offer must return only rare relics")


func test_boss_offer_excludes_held_relic() -> void:
	_impl.pick_relic("relic_x")
	var offer: Array[RelicData] = _impl.draw_boss_offer()
	for relic: RelicData in offer:
		assert_ne(relic.id, "relic_x", "held relic must not appear in boss offer")


func test_boss_offer_empty_when_all_rares_held() -> void:
	_impl.pick_relic("relic_x")
	_impl.pick_relic("relic_y")
	var offer: Array[RelicData] = _impl.draw_boss_offer()
	assert_eq(offer.size(), 0, "boss offer should be empty when all rare relics are held")


# --- compute_stat_mult ---

func test_compute_stat_mult_no_relics_returns_one() -> void:
	assert_almost_eq(_impl.compute_stat_mult("attack_damage"), 1.0, 0.0001,
		"no relics held → mult must be 1.0")


func test_compute_stat_mult_single_relic() -> void:
	_impl.pick_relic("relic_a")
	assert_almost_eq(_impl.compute_stat_mult("attack_damage"), 1.10, 0.0001,
		"relic_a (×1.10 attack_damage) should produce 1.10")


func test_compute_stat_mult_two_relics_same_stat() -> void:
	_impl.pick_relic("relic_a")
	_impl.pick_relic("relic_d")
	assert_almost_eq(_impl.compute_stat_mult("attack_damage"), 1.10 * 1.18, 0.0001,
		"two attack_damage relics should multiply: 1.10 × 1.18")


func test_compute_stat_mult_cross_stat_isolation() -> void:
	_impl.pick_relic("relic_a")  # attack_damage
	assert_almost_eq(_impl.compute_stat_mult("move_speed"), 1.0, 0.0001,
		"holding an attack_damage relic must not affect move_speed mult")


# --- should_offer_for_room ---

func test_should_offer_below_interval_returns_false() -> void:
	assert_false(_impl.should_offer_for_room("CombatRoom01"),
		"first standard room clear below OFFER_INTERVAL=2 should return false")


func test_should_offer_at_interval_resets_counter_and_returns_true() -> void:
	_impl.should_offer_for_room("CombatRoom01")
	assert_true(_impl.should_offer_for_room("CombatRoom01"),
		"second standard room clear hits OFFER_INTERVAL=2, should return true")
	assert_false(_impl.should_offer_for_room("CombatRoom01"),
		"counter resets after offer; next clear should return false again")


func test_should_offer_elite_always_returns_true() -> void:
	assert_true(_impl.should_offer_for_room("EliteRoom01"),
		"elite room must always trigger offer")


func test_should_offer_elite_does_not_advance_counter() -> void:
	# After 1 standard clear, elite fires without advancing the counter.
	# Counter is still at 1, so the very next standard clear hits OFFER_INTERVAL=2 and returns true.
	_impl.should_offer_for_room("CombatRoom01")   # counter=1, no offer
	_impl.should_offer_for_room("EliteRoom01")    # counter stays 1, elite offers
	assert_true(_impl.should_offer_for_room("CombatRoom01"),
		"elite must not advance counter — next standard clear must still trigger at interval")


# --- get_hit_damage_mult ---

func test_get_hit_damage_mult_no_conditional_relics_returns_one() -> void:
	assert_almost_eq(_impl.get_hit_damage_mult(0.5, 0.5), 1.0, 0.0001,
		"no conditional relics → mult is 1.0")


func test_get_hit_damage_mult_executioners_mark_below_threshold() -> void:
	_impl.pick_relic("relic_x")  # use a placeholder; inject directly
	# Manually set active_relic_ids to include the conditional relic.
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("executioners_mark")
	assert_almost_eq(_impl.get_hit_damage_mult(0.29, 0.6), 1.35, 0.0001,
		"executioner's mark fires at target_hp_ratio < 0.30")


func test_get_hit_damage_mult_executioners_mark_at_threshold_no_bonus() -> void:
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("executioners_mark")
	assert_almost_eq(_impl.get_hit_damage_mult(0.30, 0.6), 1.0, 0.0001,
		"executioner's mark must NOT fire at exactly 0.30")


func test_get_hit_damage_mult_berserker_stone_below_threshold() -> void:
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("berserker_stone")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.49), 1.30, 0.0001,
		"berserker stone fires at attacker_hp_ratio < 0.50")


func test_get_hit_damage_mult_berserker_stone_at_threshold_no_bonus() -> void:
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("berserker_stone")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.50), 1.0, 0.0001,
		"berserker stone must NOT fire at exactly 0.50")


func test_get_hit_damage_mult_both_relics_stacked() -> void:
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("executioners_mark")
	_impl.active_relic_ids.append("berserker_stone")
	assert_almost_eq(_impl.get_hit_damage_mult(0.20, 0.30), 1.35 * 1.30, 0.0001,
		"both conditional relics active and both thresholds met → stacked mult")


# --- pick_relic side effects ---

func test_pick_relic_adds_to_active_ids() -> void:
	_impl.pick_relic("relic_a")
	assert_true(_impl.active_relic_ids.has("relic_a"),
		"picked relic must appear in active_relic_ids")
	assert_false(_impl.active_relic_ids.has("relic_b"),
		"unpicked relic must not be in active_relic_ids")


func test_tier_exhaustion_reshuffles() -> void:
	# Force all draws into common (3 relics: a, b, c) by setting its weight to 1.0.
	var cfg_common_only: Dictionary = {
		"relic_tier_weights": {"common": 1.0, "uncommon": 0.0, "rare": 0.0}
	}
	_impl.build_pool(STUB_RELICS, cfg_common_only)
	# Exhaust the 3-card common deck.
	var d1: RelicData = _impl._draw_one()
	var d2: RelicData = _impl._draw_one()
	var d3: RelicData = _impl._draw_one()
	assert_ne(d1.id, d2.id, "exhaustion pass: draws 1 and 2 must differ")
	assert_ne(d2.id, d3.id, "exhaustion pass: draws 2 and 3 must differ")
	assert_ne(d1.id, d3.id, "exhaustion pass: draws 1 and 3 must differ")
	# Fourth draw must trigger a reshuffle and still return a valid common relic.
	var d4: RelicData = _impl._draw_one()
	assert_eq(d4.tier, "common", "post-exhaustion draw must still come from common tier")
	assert_true(d4.id in ["relic_a", "relic_b", "relic_c"], "post-exhaustion draw must be a known common relic")
