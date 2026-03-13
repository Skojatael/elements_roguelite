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
