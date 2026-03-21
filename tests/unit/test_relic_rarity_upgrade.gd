extends GutTest

const RelicManagerImpl = preload("res://scripts/managers/RelicManagerImpl.gd")

var _impl: RelicManagerImpl

# Inline stub pool with 2 common, 2 uncommon, 2 rare relics.
const STUB_RELICS: Dictionary = {
	"domain": {
		"neutral": {
			"c1": { "tier": "common",   "name": "C1", "tags": [], "effect_stat": "attack_damage", "effect_mult": 1.1, "description": "", "deck_count": 2 },
			"c2": { "tier": "common",   "name": "C2", "tags": [], "effect_stat": "attack_speed",  "effect_mult": 1.1, "description": "", "deck_count": 2 },
			"u1": { "tier": "uncommon", "name": "U1", "tags": [], "effect_stat": "max_health",    "effect_mult": 1.2, "description": "", "deck_count": 2 },
			"u2": { "tier": "uncommon", "name": "U2", "tags": [], "effect_stat": "move_speed",    "effect_mult": 1.2, "description": "", "deck_count": 2 },
			"r1": { "tier": "rare",     "name": "R1", "tags": [], "effect_stat": "attack_damage", "effect_mult": 1.3, "description": "", "deck_count": 1 },
			"r2": { "tier": "rare",     "name": "R2", "tags": [], "effect_stat": "attack_speed",  "effect_mult": 1.3, "description": "", "deck_count": 1 },
		},
	}
}

# Pool with only common relics (no uncommon/rare tiers at all).
const COMMON_ONLY_RELICS: Dictionary = {
	"domain": {
		"neutral": {
			"c1": { "tier": "common", "name": "C1", "tags": [], "effect_stat": "attack_damage", "effect_mult": 1.1, "description": "", "deck_count": 2 },
			"c2": { "tier": "common", "name": "C2", "tags": [], "effect_stat": "attack_speed",  "effect_mult": 1.1, "description": "", "deck_count": 2 },
		},
	}
}


func before_each() -> void:
	_impl = RelicManagerImpl.new()
	_impl.build_pool(STUB_RELICS, {})


func test_next_tier_common() -> void:
	assert_eq(_impl._next_tier("common"), "uncommon")


func test_next_tier_uncommon() -> void:
	assert_eq(_impl._next_tier("uncommon"), "rare")


func test_next_tier_rare() -> void:
	assert_eq(_impl._next_tier("rare"), "")


func test_next_tier_unknown_returns_empty() -> void:
	assert_eq(_impl._next_tier("legendary"), "")


func test_no_promotion_when_chance_zero() -> void:
	for _i: int in 20:
		var offer: Array[RelicData] = _impl.draw_offer("common", 0.0)
		for r: RelicData in offer:
			assert_eq(r.tier, "common", "Expected common tier relic but got tier={t}".format({"t": r.tier}))


func test_promotion_when_chance_one() -> void:
	for _i: int in 10:
		var offer: Array[RelicData] = _impl.draw_offer("common", 1.0)
		assert_true(offer.size() > 0, "Offer should not be empty")
		for r: RelicData in offer:
			assert_eq(r.tier, "uncommon", "With promotion_chance=1.0 all draws should be uncommon")


func test_promotion_fallback_when_next_tier_empty() -> void:
	_impl.reset()
	_impl.build_pool(COMMON_ONLY_RELICS, {})
	for _i: int in 10:
		var offer: Array[RelicData] = _impl.draw_offer("common", 1.0)
		assert_true(offer.size() > 0, "Offer should not be empty even with no next tier")
		for r: RelicData in offer:
			assert_eq(r.tier, "common", "Should fall back to common when uncommon tier absent")


func test_offer_cards_are_distinct() -> void:
	for _i: int in 20:
		var offer: Array[RelicData] = _impl.draw_offer("common", 1.0)
		if offer.size() < 2:
			continue
		assert_ne(offer[0].id, offer[1].id, "Both offer cards must be distinct relics")


func test_elite_promotion_uncommon_to_rare() -> void:
	for _i: int in 10:
		var offer: Array[RelicData] = _impl.draw_offer("uncommon", 1.0)
		assert_true(offer.size() > 0, "Elite offer should not be empty")
		for r: RelicData in offer:
			assert_eq(r.tier, "rare", "Elite promotion_chance=1.0 should yield rare relics")


func test_default_no_promotion() -> void:
	# Calling draw_offer with only one argument should behave identically to promotion_chance=0.0
	for _i: int in 20:
		var offer: Array[RelicData] = _impl.draw_offer("common")
		for r: RelicData in offer:
			assert_eq(r.tier, "common", "Default call (no promotion_chance arg) must not promote")
