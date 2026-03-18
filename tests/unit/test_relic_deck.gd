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

const STUB_CFG: Dictionary = {}

var _impl: RelicManagerImpl


func before_each() -> void:
	_impl = RelicManagerImpl.new()
	_impl.build_pool(STUB_RELICS, STUB_CFG)


func test_no_duplicates_single_pass() -> void:
	var a: RelicData = _impl._draw_one_from_tier("common")
	var b: RelicData = _impl._draw_one_from_tier("common")
	var c: RelicData = _impl._draw_one_from_tier("common")
	assert_ne(a.id, b.id, "first and second draws must differ")
	assert_ne(b.id, c.id, "second and third draws must differ")


func test_draw_offer_pair_distinct() -> void:
	for i: int in 10:
		_impl.build_pool(STUB_RELICS, STUB_CFG)
		var offer: Array[RelicData] = _impl.draw_offer("common")
		assert_eq(offer.size(), 2, "draw_offer should return exactly 2 relics")
		assert_ne(offer[0].id, offer[1].id, "offer pair must contain distinct relics (iteration {i})".format({"i": i}))


func test_draw_offer_common_returns_only_common() -> void:
	for i: int in 20:
		var offer: Array[RelicData] = _impl.draw_offer("common")
		for relic: RelicData in offer:
			assert_eq(relic.tier, "common", "draw_offer(common) must return only common relics")


func test_draw_offer_uncommon_returns_only_uncommon() -> void:
	for i: int in 10:
		_impl.build_pool(STUB_RELICS, STUB_CFG)
		var offer: Array[RelicData] = _impl.draw_offer("uncommon")
		assert_eq(offer.size(), 2, "draw_offer(uncommon) should return exactly 2 relics")
		for relic: RelicData in offer:
			assert_eq(relic.tier, "uncommon", "draw_offer(uncommon) must return only uncommon relics")


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


# --- compute_stat_addend ---

const STUB_RELICS_CRIT: Dictionary = {
	"relics": {
		"common": {
			"crit_a": {"name": "CritA", "effect_stat": "crit_chance",     "effect_mult": 0.10},
			"crit_b": {"name": "CritB", "effect_stat": "crit_chance",     "effect_mult": 0.15},
			"crit_c": {"name": "CritC", "effect_stat": "crit_multiplier", "effect_mult": 0.25},
		},
	}
}


func test_compute_stat_addend_no_relics_returns_zero() -> void:
	assert_almost_eq(_impl.compute_stat_addend("crit_chance"), 0.0, 0.0001,
		"no relics held → addend must be 0.0")


func test_compute_stat_addend_single_crit_chance_relic() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_CRIT, STUB_CFG)
	impl.pick_relic("crit_a")
	assert_almost_eq(impl.compute_stat_addend("crit_chance"), 0.10, 0.0001,
		"one crit_chance relic (0.10) → addend must be 0.10")


func test_compute_stat_addend_two_crit_chance_relics_stacks() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_CRIT, STUB_CFG)
	impl.pick_relic("crit_a")
	impl.pick_relic("crit_b")
	assert_almost_eq(impl.compute_stat_addend("crit_chance"), 0.25, 0.0001,
		"two crit_chance relics (0.10 + 0.15) → addend must be 0.25")


func test_compute_stat_addend_crit_multiplier_relic_no_crit_chance_contamination() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_CRIT, STUB_CFG)
	impl.pick_relic("crit_c")
	assert_almost_eq(impl.compute_stat_addend("crit_chance"), 0.0, 0.0001,
		"holding a crit_multiplier relic must not affect crit_chance addend")


func test_compute_stat_addend_crit_multiplier_relic() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_CRIT, STUB_CFG)
	impl.pick_relic("crit_c")
	assert_almost_eq(impl.compute_stat_addend("crit_multiplier"), 0.25, 0.0001,
		"one crit_multiplier relic (0.25) → addend must be 0.25")


# --- has_burn_relic ---

func test_has_burn_relic_false_when_empty() -> void:
	assert_false(_impl.has_burn_relic(),
		"no relics held → has_burn_relic must return false")


func test_has_burn_relic_true_after_pick() -> void:
	_impl.active_relic_ids.append("burn")
	assert_true(_impl.has_burn_relic(),
		"burn in active_relic_ids → has_burn_relic must return true")


func test_has_burn_relic_false_for_other_relic() -> void:
	_impl.pick_relic("relic_a")
	assert_false(_impl.has_burn_relic(),
		"holding a different relic must not activate has_burn_relic")


# --- has_chain_relic ---

func test_has_chain_relic_false_when_empty() -> void:
	assert_false(_impl.has_chain_relic(),
		"no relics held → has_chain_relic must return false")


func test_has_chain_relic_true_after_pick() -> void:
	_impl.active_relic_ids.append("chaining_stone")
	assert_true(_impl.has_chain_relic(),
		"chaining_stone in active_relic_ids → has_chain_relic must return true")


func test_has_chain_relic_false_for_other_relic() -> void:
	_impl.pick_relic("relic_a")
	assert_false(_impl.has_chain_relic(),
		"holding a different relic must not activate has_chain_relic")


# --- pick_relic side effects ---

func test_pick_relic_adds_to_active_ids() -> void:
	_impl.pick_relic("relic_a")
	assert_true(_impl.active_relic_ids.has("relic_a"),
		"picked relic must appear in active_relic_ids")
	assert_false(_impl.active_relic_ids.has("relic_b"),
		"unpicked relic must not be in active_relic_ids")


func test_tier_exhaustion_reshuffles() -> void:
	# Exhaust the 3-card common deck.
	var d1: RelicData = _impl._draw_one_from_tier("common")
	var d2: RelicData = _impl._draw_one_from_tier("common")
	var d3: RelicData = _impl._draw_one_from_tier("common")
	assert_ne(d1.id, d2.id, "exhaustion pass: draws 1 and 2 must differ")
	assert_ne(d2.id, d3.id, "exhaustion pass: draws 2 and 3 must differ")
	assert_ne(d1.id, d3.id, "exhaustion pass: draws 1 and 3 must differ")
	# Fourth draw must trigger a reshuffle and still return a valid common relic.
	var d4: RelicData = _impl._draw_one_from_tier("common")
	assert_eq(d4.tier, "common", "post-exhaustion draw must still come from common tier")
	assert_true(d4.id in ["relic_a", "relic_b", "relic_c"], "post-exhaustion draw must be a known common relic")
