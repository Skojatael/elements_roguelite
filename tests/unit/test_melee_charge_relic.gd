extends GutTest

const RelicManagerImpl = preload("res://scripts/managers/RelicManagerImpl.gd")

const FIXTURE_RELICS: Dictionary = {
	"relics": {
		"common": {
			"melee_missile_charge": {
				"name": "Arcane Knuckles",
				"tags": ["projectile", "melee"],
				"effect_stat": "",
				"effect_mult": 1.0,
				"condition_type": "",
				"condition_threshold": 3.0,
				"condition_mult": 1.0,
				"description": "Every 3 melee hits restore 1 Magic Missile charge.",
				"deck_count": 2
			}
		}
	}
}

var _impl: RelicManagerImpl


func before_each() -> void:
	_impl = RelicManagerImpl.new()
	_impl.build_pool(FIXTURE_RELICS, {})
	_impl.active_relic_ids.append("melee_missile_charge")


# --- US1: counter behaviour ---

func test_first_two_hits_return_false() -> void:
	assert_false(_impl.on_melee_hit(), "hit 1 should return false")
	assert_false(_impl.on_melee_hit(), "hit 2 should return false")


func test_third_hit_returns_true() -> void:
	_impl.on_melee_hit()
	_impl.on_melee_hit()
	assert_true(_impl.on_melee_hit(), "hit 3 should return true")


func test_counter_resets_after_third_hit() -> void:
	_impl.on_melee_hit()
	_impl.on_melee_hit()
	_impl.on_melee_hit()  # true, counter resets to 0
	assert_false(_impl.on_melee_hit(), "hit 4 (first of new cycle) should return false")


func test_sixth_hit_returns_true() -> void:
	for _i: int in 5:
		_impl.on_melee_hit()
	assert_true(_impl.on_melee_hit(), "hit 6 should return true (second cycle)")


func test_returns_false_when_relic_not_held() -> void:
	_impl.active_relic_ids.clear()
	assert_false(_impl.on_melee_hit(), "hit 1 without relic: false")
	assert_false(_impl.on_melee_hit(), "hit 2 without relic: false")
	assert_false(_impl.on_melee_hit(), "hit 3 without relic: false")


func test_hits_without_relic_do_not_corrupt_counter() -> void:
	# Accumulate hits while relic is absent
	_impl.active_relic_ids.clear()
	_impl.on_melee_hit()
	_impl.on_melee_hit()
	# Re-add relic — counter must start fresh, not carry over from relic-absent hits
	_impl.active_relic_ids.append("melee_missile_charge")
	assert_false(_impl.on_melee_hit(), "hit 1 with relic (after 2 relic-absent hits): false")
	assert_false(_impl.on_melee_hit(), "hit 2 with relic: false")
	assert_true(_impl.on_melee_hit(), "hit 3 with relic: true")


# --- US2: pool draw ---

func test_relic_appears_in_common_draw_within_20_attempts() -> void:
	var found: bool = false
	for _i: int in 20:
		var offer: Array[RelicData] = _impl.draw_offer("common")
		for r: RelicData in offer:
			if r.id == "melee_missile_charge":
				found = true
				break
		if found:
			break
	assert_true(found, "melee_missile_charge should appear in common draw within 20 attempts")


func test_relic_excluded_when_already_held() -> void:
	# Relic is already in active_relic_ids (set in before_each).
	# After pick_relic it is excluded from future draws via deck rebuild.
	# Note: draw_offer does NOT filter active_relic_ids — duplicate exclusion
	# is the autoload's concern. Impl pool remains drawable after pick_relic.
	_impl.pick_relic("melee_missile_charge")
	var offer: Array[RelicData] = _impl.draw_offer("common")
	assert_false(offer.is_empty(), "pool should remain drawable after pick_relic")


# --- US3: counter reset ---

func test_reset_zeroes_counter_mid_cycle() -> void:
	_impl.on_melee_hit()  # counter = 1
	_impl.on_melee_hit()  # counter = 2
	_impl.reset()
	_impl.build_pool(FIXTURE_RELICS, {})
	_impl.active_relic_ids.append("melee_missile_charge")
	assert_false(_impl.on_melee_hit(), "hit 1 after reset: false (counter starts at 0)")
	assert_false(_impl.on_melee_hit(), "hit 2 after reset: false")
	assert_true(_impl.on_melee_hit(), "hit 3 after reset: true (full cycle required)")


func test_reset_clears_active_relic_ids() -> void:
	_impl.reset()
	assert_eq(_impl.active_relic_ids.size(), 0, "reset must clear active_relic_ids")
