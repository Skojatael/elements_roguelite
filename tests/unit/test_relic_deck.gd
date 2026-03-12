extends GutTest

const RelicManagerImpl = preload("res://scripts/managers/RelicManagerImpl.gd")

const STUB_RELICS: Dictionary = {
	"relics": {
		"common": {
			"relic_a": {"name": "A", "effect_stat": "attack_damage", "effect_mult": 1.10},
			"relic_b": {"name": "B", "effect_stat": "attack_speed",  "effect_mult": 1.05},
			"relic_c": {"name": "C", "effect_stat": "move_speed",    "effect_mult": 1.08},
		},
		"rare": {
			"relic_x": {"name": "X", "effect_stat": "attack_damage", "effect_mult": 1.25},
			"relic_y": {"name": "Y", "effect_stat": "max_health",    "effect_mult": 1.30},
		},
	}
}

const STUB_CFG: Dictionary = {
	"relic_tier_weights": {"common": 1.0}
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
	assert_ne(a.id, c.id, "first and third draws must differ")


func test_reshuffle_restores_full_deck() -> void:
	# Exhaust the 3-relic common deck
	_impl._draw_one()
	_impl._draw_one()
	_impl._draw_one()
	# Second pass after reshuffle
	var d: RelicData = _impl._draw_one()
	var e: RelicData = _impl._draw_one()
	var f: RelicData = _impl._draw_one()
	assert_ne(d.id, e.id, "post-reshuffle: first and second draws must differ")
	assert_ne(e.id, f.id, "post-reshuffle: second and third draws must differ")
	assert_ne(d.id, f.id, "post-reshuffle: first and third draws must differ")


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
