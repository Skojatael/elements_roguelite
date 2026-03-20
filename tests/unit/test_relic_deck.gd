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


const STUB_RELICS_HIGH_COUNT: Dictionary = {
	"relics": {
		"common": {
			"relic_a": {"name": "A", "effect_stat": "attack_damage", "effect_mult": 1.10, "deck_count": 3},
			"relic_b": {"name": "B", "effect_stat": "attack_speed",  "effect_mult": 1.05, "deck_count": 3},
			"relic_c": {"name": "C", "effect_stat": "move_speed",    "effect_mult": 1.08, "deck_count": 3},
		},
	}
}


func test_draw_offer_single_unique_relic_returns_one() -> void:
	# Regression: if tier has only one unique relic (even with deck_count > 1),
	# excluding left.id empties the rebuilt deck. _draw_one_from_tier would then
	# reshuffle without exclusion and could return the same relic again.
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool({
		"relics": {"common": {"only_relic": {"name": "Solo", "effect_stat": "attack_damage", "effect_mult": 1.10, "deck_count": 3}}}
	}, STUB_CFG)
	var offer: Array[RelicData] = impl.draw_offer("common")
	assert_eq(offer.size(), 1, "tier with one unique relic must return only 1 offer, not a duplicate pair")
	assert_eq(offer[0].id, "only_relic", "the single available relic must be returned")


func test_draw_offer_distinct_with_high_deck_count() -> void:
	# Regression: deck_count > 1 left duplicate copies in the deck after the first draw,
	# causing the second draw to sometimes return the same relic.
	for i: int in 30:
		var impl: RelicManagerImpl = RelicManagerImpl.new()
		impl.build_pool(STUB_RELICS_HIGH_COUNT, STUB_CFG)
		var offer: Array[RelicData] = impl.draw_offer("common")
		assert_eq(offer.size(), 2, "draw_offer must return 2 relics (deck_count=3 iteration {i})".format({"i": i}))
		assert_ne(offer[0].id, offer[1].id,
			"offer pair must be distinct even when deck_count=3 (iteration {i})".format({"i": i}))


func test_draw_offer_strips_in_place_preserves_exhaustion_state() -> void:
	# Deck is seeded with exactly [relic_b, relic_c] — simulating relic_a already exhausted.
	# After the offer, relic_a must NOT reappear; deck must not be fully rebuilt.
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_HIGH_COUNT, STUB_CFG)
	var relic_b: RelicData = impl._relics_by_id["relic_b"]
	var relic_c: RelicData = impl._relics_by_id["relic_c"]
	impl._decks["common"] = [relic_b, relic_c]
	var offer: Array[RelicData] = impl.draw_offer("common")
	assert_eq(offer.size(), 2, "offer must return 2 relics")
	assert_ne(offer[0].id, offer[1].id, "offer relics must be distinct")
	# deck has at most 0 cards left; crucially relic_a must not have re-entered via a full rebuild
	for r: RelicData in (impl._decks["common"] as Array):
		assert_ne(r.id, "relic_a",
			"relic_a was exhausted before the offer — in-place strip must not trigger a full rebuild that restores it")


func test_draw_offer_fallback_rebuild_excludes_left_when_strip_empties_deck() -> void:
	# Deck seeded with only copies of relic_a. After drawing left=relic_a, stripping
	# relic_a empties the deck → fallback full rebuild. Right must NOT be relic_a.
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_HIGH_COUNT, STUB_CFG)
	var relic_a: RelicData = impl._relics_by_id["relic_a"]
	impl._decks["common"] = [relic_a, relic_a, relic_a]
	var offer: Array[RelicData] = impl.draw_offer("common")
	assert_eq(offer.size(), 2, "fallback rebuild must still produce 2 relics")
	assert_eq(offer[0].id, "relic_a", "left must be relic_a — the only relic in the seeded deck")
	assert_ne(offer[1].id, "relic_a",
		"right must not be relic_a — fallback rebuild must exclude left.id")


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
	_impl.pick_relic("relic_a")  # +0.10 attack_damage
	_impl.pick_relic("relic_d")  # +0.18 attack_damage
	assert_almost_eq(_impl.compute_stat_mult("attack_damage"), 1.0 + 0.10 + 0.18, 0.0001,
		"two attack_damage relics stack additively: 1.0 + 0.10 + 0.18 = 1.28")


func test_compute_stat_mult_cross_stat_isolation() -> void:
	_impl.pick_relic("relic_a")  # attack_damage
	assert_almost_eq(_impl.compute_stat_mult("move_speed"), 1.0, 0.0001,
		"holding an attack_damage relic must not affect move_speed mult")


# --- should_offer_for_room ---

func test_should_offer_every_standard_room_returns_true() -> void:
	assert_true(_impl.should_offer_for_room("CombatRoom01"),
		"first standard room clear hits OFFER_INTERVAL=1, should return true")
	assert_true(_impl.should_offer_for_room("CombatRoom01"),
		"every subsequent standard room clear also triggers offer")


func test_should_offer_elite_always_returns_true() -> void:
	assert_true(_impl.should_offer_for_room("EliteRoom01"),
		"elite room must always trigger offer")


func test_should_offer_elite_does_not_advance_counter() -> void:
	# Elite fires without advancing the standard counter.
	# With OFFER_INTERVAL=1, every standard clear triggers regardless, so this just
	# verifies the elite path doesn't corrupt state.
	_impl.should_offer_for_room("EliteRoom01")    # counter stays 0, elite offers
	assert_true(_impl.should_offer_for_room("CombatRoom01"),
		"elite must not advance counter — next standard clear must still trigger at interval")


# --- get_hit_damage_mult ---

const STUB_RELICS_CONDITIONAL: Dictionary = {
	"relics": {
		"rare": {
			"executioners_mark": {
				"name": "Executioner's Mark", "tags": ["combat"],
				"effect_stat": "", "effect_mult": 1.0,
				"condition_type": "target_hp_below", "condition_threshold": 0.30, "condition_mult": 1.35,
				"deck_count": 1
			},
			"berserker_stone": {
				"name": "Berserker Stone", "tags": ["combat"],
				"effect_stat": "", "effect_mult": 1.0,
				"condition_type": "attacker_hp_below", "condition_threshold": 0.50, "condition_mult": 1.30,
				"deck_count": 1
			},
			"burn_damage": {
				"name": "Searing Seal", "tags": ["burn_unlocked"],
				"effect_stat": "", "effect_mult": 1.0,
				"condition_type": "target_is_burning", "condition_threshold": 0.0, "condition_mult": 1.50,
				"deck_count": 1
			},
		},
	}
}


func test_get_hit_damage_mult_no_conditional_relics_returns_one() -> void:
	assert_almost_eq(_impl.get_hit_damage_mult(0.5, 0.5, false), 1.0, 0.0001,
		"no conditional relics → mult is 1.0")


func test_get_hit_damage_mult_executioners_mark_below_threshold() -> void:
	_impl.build_pool(STUB_RELICS_CONDITIONAL, {})
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("executioners_mark")
	assert_almost_eq(_impl.get_hit_damage_mult(0.29, 0.6, false), 1.35, 0.0001,
		"executioner's mark fires at target_hp_ratio < 0.30")


func test_get_hit_damage_mult_executioners_mark_at_threshold_no_bonus() -> void:
	_impl.build_pool(STUB_RELICS_CONDITIONAL, {})
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("executioners_mark")
	assert_almost_eq(_impl.get_hit_damage_mult(0.30, 0.6, false), 1.0, 0.0001,
		"executioner's mark must NOT fire at exactly 0.30")


func test_get_hit_damage_mult_berserker_stone_below_threshold() -> void:
	_impl.build_pool(STUB_RELICS_CONDITIONAL, {})
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("berserker_stone")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.49, false), 1.30, 0.0001,
		"berserker stone fires at attacker_hp_ratio < 0.50")


func test_get_hit_damage_mult_berserker_stone_at_threshold_no_bonus() -> void:
	_impl.build_pool(STUB_RELICS_CONDITIONAL, {})
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("berserker_stone")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.50, false), 1.0, 0.0001,
		"berserker stone must NOT fire at exactly 0.50")


func test_get_hit_damage_mult_both_relics_stacked() -> void:
	_impl.build_pool(STUB_RELICS_CONDITIONAL, {})
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("executioners_mark")
	_impl.active_relic_ids.append("berserker_stone")
	assert_almost_eq(_impl.get_hit_damage_mult(0.20, 0.30, false), 1.35 * 1.30, 0.0001,
		"both conditional relics active and both thresholds met → stacked mult")


func test_searing_seal_no_bonus_when_target_not_burning() -> void:
	_impl.build_pool(STUB_RELICS_CONDITIONAL, {})
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("burn_damage")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.8, false), 1.0, 0.0001,
		"searing_seal must apply no bonus when target is not burning")


func test_searing_seal_bonus_when_target_burning() -> void:
	_impl.build_pool(STUB_RELICS_CONDITIONAL, {})
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("burn_damage")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.8, true), 1.50, 0.0001,
		"searing_seal must apply 1.50x multiplier when target is burning")


func test_searing_seal_no_bonus_without_relic() -> void:
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.8, true), 1.0, 0.0001,
		"no searing_seal held — no bonus even when target is burning")


func test_searing_seal_stacks_with_executioners_mark() -> void:
	_impl.build_pool(STUB_RELICS_CONDITIONAL, {})
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("burn_damage")
	_impl.active_relic_ids.append("executioners_mark")
	assert_almost_eq(_impl.get_hit_damage_mult(0.20, 0.8, true), 1.50 * 1.35, 0.0001,
		"searing_seal and executioners_mark both active — multiplicative stacking")


func test_searing_seal_stacks_with_berserker_stone() -> void:
	_impl.build_pool(STUB_RELICS_CONDITIONAL, {})
	_impl.active_relic_ids.clear()
	_impl.active_relic_ids.append("burn_damage")
	_impl.active_relic_ids.append("berserker_stone")
	assert_almost_eq(_impl.get_hit_damage_mult(0.8, 0.30, true), 1.50 * 1.30, 0.0001,
		"searing_seal and berserker_stone both active — multiplicative stacking")


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


# --- mechanic unlock ---

const STUB_RELICS_MECHANIC: Dictionary = {
	"relics": {
		"uncommon": {
			"burn": {
				"name": "Burn", "tags": ["burn"],
				"effect_stat": "", "effect_mult": 1.0, "deck_count": 1
			},
			"burn_damage": {
				"name": "Burn Dmg", "tags": ["burn_unlocked"],
				"effect_stat": "", "effect_mult": 1.0, "deck_count": 1
			},
			"chain": {
				"name": "Chain", "tags": ["chain"],
				"effect_stat": "", "effect_mult": 1.0, "deck_count": 1
			},
			"chain_reach": {
				"name": "Chain Reach", "tags": ["chain_unlocked"],
				"effect_stat": "", "effect_mult": 1.0, "deck_count": 1
			},
			"generic": {
				"name": "Generic", "tags": ["combat"],
				"effect_stat": "attack_damage", "effect_mult": 1.1, "deck_count": 1
			},
		},
	}
}

const STUB_RELICS_RARE_UNLOCKED: Dictionary = {
	"relics": {
		"rare": {
			"burn_epic": {
				"name": "Burn Epic", "tags": ["burn_unlocked"],
				"effect_stat": "", "effect_mult": 1.0, "deck_count": 1
			},
			"rare_normal": {
				"name": "Rare Normal", "tags": ["combat"],
				"effect_stat": "attack_damage", "effect_mult": 1.3, "deck_count": 1
			},
		},
	}
}


# T005/T006: mechanic_tag_names and initial deck state

func test_unlocked_relic_absent_before_mechanic_activated() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	var deck: Array[RelicData] = impl._build_expanded_deck("uncommon")
	for r: RelicData in deck:
		assert_ne(r.id, "burn_damage",
			"burn_damage must not appear in initial deck — mechanic not yet activated")
		assert_ne(r.id, "chain_reach",
			"chain_reach must not appear in initial deck — mechanic not yet activated")


func test_mechanic_tag_names_computed_from_pool() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	assert_true(impl._mechanic_tag_names.has("burn"),
		"burn must appear in _mechanic_tag_names (burn_unlocked relic exists)")
	assert_true(impl._mechanic_tag_names.has("chain"),
		"chain must appear in _mechanic_tag_names (chain_unlocked relic exists)")
	assert_false(impl._mechanic_tag_names.has("combat"),
		"combat must not appear in _mechanic_tag_names (no combat_unlocked relic)")


# T009/T010: mechanic activation — exclusion and unlock

func test_mechanic_relic_excluded_after_activation() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	impl.pick_relic("burn")
	var deck: Array[RelicData] = impl._build_expanded_deck("uncommon")
	for r: RelicData in deck:
		assert_ne(r.id, "burn",
			"burn must not appear in deck after mechanic is activated")


func test_unlocked_relic_present_after_mechanic_activated() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	impl.pick_relic("burn")
	var deck: Array[RelicData] = impl._build_expanded_deck("uncommon")
	var found: bool = false
	for r: RelicData in deck:
		if r.id == "burn_damage":
			found = true
			break
	assert_true(found, "burn_damage must appear in deck after burn mechanic is activated")


# T011/T012: US2 reset behaviour

func test_activated_mechanics_cleared_on_reset() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	impl.pick_relic("burn")
	assert_true(impl._activated_mechanics.has("burn"),
		"burn must be in _activated_mechanics after pick_relic")
	impl.reset()
	assert_eq(impl._activated_mechanics.size(), 0,
		"_activated_mechanics must be empty after reset()")
	assert_eq(impl._mechanic_tag_names.size(), 0,
		"_mechanic_tag_names must be empty after reset()")


func test_mechanic_relic_returns_after_reset_and_rebuild() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	impl.pick_relic("burn")
	impl.reset()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	var deck: Array[RelicData] = impl._build_expanded_deck("uncommon")
	var has_burn: bool = false
	var has_burn_damage: bool = false
	for r: RelicData in deck:
		if r.id == "burn":
			has_burn = true
		if r.id == "burn_damage":
			has_burn_damage = true
	assert_true(has_burn,
		"burn must reappear in deck after reset and rebuild")
	assert_false(has_burn_damage,
		"burn_damage must not appear in deck after reset and rebuild (no mechanic active)")


# T013–T016: US3 pair independence

func test_non_mechanic_tag_does_not_activate_mechanic() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	impl.pick_relic("generic")
	assert_eq(impl._activated_mechanics.size(), 0,
		"picking a relic with only a category tag must not activate any mechanic")


func test_mechanic_pairs_independent_burn_does_not_affect_chain() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	impl.pick_relic("burn")
	var deck: Array[RelicData] = impl._build_expanded_deck("uncommon")
	var has_chain: bool = false
	var has_chain_reach: bool = false
	for r: RelicData in deck:
		if r.id == "chain":
			has_chain = true
		if r.id == "chain_reach":
			has_chain_reach = true
	assert_true(has_chain,
		"chain must remain eligible after burn mechanic is activated")
	assert_false(has_chain_reach,
		"chain_reach must not appear — chain mechanic not yet activated")


func test_mechanic_pairs_independent_chain_does_not_affect_burn() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	impl.pick_relic("chain")
	var deck: Array[RelicData] = impl._build_expanded_deck("uncommon")
	var has_burn: bool = false
	var has_burn_damage: bool = false
	for r: RelicData in deck:
		if r.id == "burn":
			has_burn = true
		if r.id == "burn_damage":
			has_burn_damage = true
	assert_true(has_burn,
		"burn must remain eligible after chain mechanic is activated")
	assert_false(has_burn_damage,
		"burn_damage must not appear — burn mechanic not yet activated")


func test_both_mechanics_unlock_both() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_MECHANIC, STUB_CFG)
	impl.pick_relic("burn")
	impl.pick_relic("chain")
	var deck: Array[RelicData] = impl._build_expanded_deck("uncommon")
	var has_burn: bool = false
	var has_chain: bool = false
	var has_burn_damage: bool = false
	var has_chain_reach: bool = false
	for r: RelicData in deck:
		if r.id == "burn":
			has_burn = true
		if r.id == "chain":
			has_chain = true
		if r.id == "burn_damage":
			has_burn_damage = true
		if r.id == "chain_reach":
			has_chain_reach = true
	assert_false(has_burn, "burn must be excluded — mechanic activated")
	assert_false(has_chain, "chain must be excluded — mechanic activated")
	assert_true(has_burn_damage, "burn_damage must appear — burn mechanic is active")
	assert_true(has_chain_reach, "chain_reach must appear — chain mechanic is active")


# T018: boss offer respects mechanic eligibility

func test_boss_offer_excludes_unlocked_relic_when_mechanic_inactive() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_RARE_UNLOCKED, STUB_CFG)
	var offer: Array[RelicData] = impl.draw_boss_offer()
	for r: RelicData in offer:
		assert_ne(r.id, "burn_epic",
			"burn_epic (burn_unlocked) must not appear in boss offer — burn mechanic not active")


# --- pick_relic side effects ---

func test_pick_relic_adds_to_active_ids() -> void:
	_impl.pick_relic("relic_a")
	assert_true(_impl.active_relic_ids.has("relic_a"),
		"picked relic must appear in active_relic_ids")
	assert_false(_impl.active_relic_ids.has("relic_b"),
		"unpicked relic must not be in active_relic_ids")


# --- deck_count expansion ---

const STUB_RELICS_COUNTS: Dictionary = {
	"relics": {
		"common": {
			"relic_a": {"name": "A", "effect_stat": "attack_damage", "effect_mult": 1.10, "deck_count": 3},
			"relic_b": {"name": "B", "effect_stat": "attack_speed",  "effect_mult": 1.05, "deck_count": 1},
		},
	}
}

const STUB_RELICS_ZERO: Dictionary = {
	"relics": {
		"common": {
			"relic_a": {"name": "A", "effect_stat": "attack_damage", "effect_mult": 1.10, "deck_count": 3},
			"relic_b": {"name": "B", "effect_stat": "attack_speed",  "effect_mult": 1.05, "deck_count": 0},
		},
	}
}


func test_deck_count_expansion_total_size() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_COUNTS, STUB_CFG)
	# relic_a × 3 + relic_b × 1 = 4 entries
	var built: Array[RelicData] = impl._build_expanded_deck("common")
	assert_eq(built.size(), 4, "_build_expanded_deck must produce deck_count copies per relic")


func test_deck_count_exclude_id_removes_all_copies() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_COUNTS, STUB_CFG)
	var built: Array[RelicData] = impl._build_expanded_deck("common", "relic_a")
	for r: RelicData in built:
		assert_ne(r.id, "relic_a", "exclude_id must remove ALL copies of the excluded relic")
	assert_eq(built.size(), 1, "only relic_b (count=1) should remain after excluding relic_a")


func test_deck_count_zero_relic_never_drawn() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_ZERO, STUB_CFG)
	var built: Array[RelicData] = impl._build_expanded_deck("common")
	for r: RelicData in built:
		assert_ne(r.id, "relic_b", "relic with deck_count=0 must not appear in the expanded deck")


func test_deck_count_default_one_without_field() -> void:
	# STUB_RELICS has no deck_count fields — all should default to 1
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS, STUB_CFG)
	var built: Array[RelicData] = impl._build_expanded_deck("common")
	assert_eq(built.size(), 3, "relics without deck_count default to 1 — common tier has 3 relics × 1 = 3 entries")


func test_deck_count_higher_relic_drawn_more_often() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_COUNTS, STUB_CFG)
	var count_a: int = 0
	var count_b: int = 0
	# Draw 40 times with reshuffles to get a stable sample
	for _i: int in 40:
		var r: RelicData = impl._draw_one_from_tier("common")
		if r.id == "relic_a":
			count_a += 1
		else:
			count_b += 1
	# relic_a (count=3) should appear ~3× more than relic_b (count=1)
	# With 40 draws: expect ~30 for a, ~10 for b — allow wide tolerance
	assert_true(count_a > count_b, "relic_a (deck_count=3) must appear more often than relic_b (deck_count=1) over 40 draws")


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


# --- get_chain_damage_bonus ---

const STUB_RELICS_CHAIN_BONUS: Dictionary = {
	"relics": {
		"common": {
			"chain_power_stone": {
				"name": "Chain Amplifier", "tags": ["chain_unlocked"],
				"effect_stat": "", "effect_mult": 1.0,
				"condition_type": "chain_damage_bonus", "condition_threshold": 0.0, "condition_mult": 0.15,
				"deck_count": 1
			},
			"chain_power_stone_2": {
				"name": "Chain Amplifier II", "tags": ["chain_unlocked"],
				"effect_stat": "", "effect_mult": 1.0,
				"condition_type": "chain_damage_bonus", "condition_threshold": 0.0, "condition_mult": 0.15,
				"deck_count": 1
			},
			"other_relic": {
				"name": "Other", "tags": ["combat"],
				"effect_stat": "attack_damage", "effect_mult": 1.1,
				"deck_count": 1
			},
		},
	}
}


func test_get_chain_damage_bonus_returns_zero_when_no_relic_held() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_CHAIN_BONUS, STUB_CFG)
	assert_almost_eq(impl.get_chain_damage_bonus(), 0.0, 0.0001,
		"no relics held → chain damage bonus must be 0.0")


func test_get_chain_damage_bonus_returns_bonus_when_held() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_CHAIN_BONUS, STUB_CFG)
	impl.active_relic_ids.append("chain_power_stone")
	assert_almost_eq(impl.get_chain_damage_bonus(), 0.15, 0.0001,
		"chain_power_stone held → chain damage bonus must be 0.15")


func test_get_chain_damage_bonus_additive_stacking() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_CHAIN_BONUS, STUB_CFG)
	impl.active_relic_ids.append("chain_power_stone")
	impl.active_relic_ids.append("chain_power_stone_2")
	assert_almost_eq(impl.get_chain_damage_bonus(), 0.30, 0.0001,
		"two chain_damage_bonus relics held → bonuses add: 0.15 + 0.15 = 0.30")


func test_get_chain_damage_bonus_unrelated_relic_no_effect() -> void:
	var impl: RelicManagerImpl = RelicManagerImpl.new()
	impl.build_pool(STUB_RELICS_CHAIN_BONUS, STUB_CFG)
	impl.active_relic_ids.append("other_relic")
	assert_almost_eq(impl.get_chain_damage_bonus(), 0.0, 0.0001,
		"holding a non-chain-bonus relic must not affect get_chain_damage_bonus")
