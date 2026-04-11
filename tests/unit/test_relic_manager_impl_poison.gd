extends GutTest

const RelicManagerImpl = preload("res://scripts/managers/RelicManagerImpl.gd")

var _impl: RelicManagerImpl

## Minimal relics JSON with only the venomous_strike relic (forest domain).
const RELICS_STUB: Dictionary = {
	"domain": {
		"forest": {
			"common": {
				"venomous_strike": {
					"name": "Venom Fang",
					"tags": ["melee", "debuff"],
					"effect_stat": "",
					"effect_mult": 1.0,
					"condition_type": "",
					"poison_chance": 0.25,
					"poison_duration": 3.0,
					"poison_modifier": 0.15,
					"description": "Melee hits have a 25% chance to poison enemies, reducing their damage by 15% for 3s.",
					"deck_count": 2
				}
			}
		}
	}
}


func before_each() -> void:
	_impl = RelicManagerImpl.new()
	_impl.build_pool(RELICS_STUB, {}, true)


## has_poison_relic() returns false when the relic has not been picked.
func test_has_poison_relic_false_when_absent() -> void:
	assert_false(_impl.has_poison_relic())


## has_poison_relic() returns true after the relic is picked.
func test_has_poison_relic_true_after_pick() -> void:
	_impl.pick_relic("venomous_strike")
	assert_true(_impl.has_poison_relic())


## try_apply_poison is a no-op when relic is absent (does not crash with null target).
func test_try_apply_poison_noop_when_absent() -> void:
	# Should not crash even with null target since guard exits early.
	_impl.try_apply_poison(null)
	assert_true(true, "no crash expected when relic absent")


## RelicData fields are read correctly from the JSON stub.
func test_relic_data_fields_parsed_correctly() -> void:
	_impl.pick_relic("venomous_strike")
	var relic: RelicData = _impl._relics_by_id.get("venomous_strike") as RelicData
	assert_not_null(relic)
	assert_almost_eq(relic.poison_chance, 0.25, 0.001)
	assert_almost_eq(relic.poison_duration, 3.0, 0.001)
	assert_almost_eq(relic.poison_modifier, 0.15, 0.001)
