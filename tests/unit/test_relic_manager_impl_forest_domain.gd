extends GutTest

const RelicManagerImpl = preload("res://scripts/managers/RelicManagerImpl.gd")

var _impl: RelicManagerImpl

## Relics dict with one neutral relic and one forest relic.
const RELICS_STUB: Dictionary = {
	"domain": {
		"neutral": {
			"common_damage": {
				"tier": "common",
				"name": "Whetstone",
				"tags": ["combat"],
				"effect_stat": "attack_damage",
				"effect_mult": 1.10,
				"description": "+10% attack damage",
				"deck_count": 1,
			}
		},
		"forest": {
			"root_relic": {
				"tier": "uncommon",
				"name": "Rootweave Band",
				"tags": ["melee"],
				"effect_stat": "",
				"effect_mult": 1.0,
				"condition_type": "root_on_melee_hit",
				"root_chance": 1.0,
				"root_duration": 0.6,
				"description": "test",
				"deck_count": 1,
			}
		}
	}
}


func before_each() -> void:
	_impl = RelicManagerImpl.new()


# --- forest domain excluded when not unlocked ---

func test_forest_relic_excluded_from_pool_when_domain_locked() -> void:
	_impl.build_pool(RELICS_STUB, {}, false)
	assert_false(_impl._relics_by_id.has("root_relic"),
		"root_relic must not be in pool when forest_domain_unlocked=false")


func test_neutral_relic_included_when_forest_domain_locked() -> void:
	_impl.build_pool(RELICS_STUB, {}, false)
	assert_true(_impl._relics_by_id.has("common_damage"),
		"neutral relics must always be in pool regardless of forest gate")


func test_forest_relic_absent_from_tier_deck_when_domain_locked() -> void:
	_impl.build_pool(RELICS_STUB, {}, false)
	# root_relic is the only uncommon; with forest locked, the tier must be absent entirely.
	assert_false(_impl._all_by_tier.has("uncommon"),
		"uncommon tier must not exist when the only uncommon relic is in the locked forest domain")


# --- forest domain included when unlocked ---

func test_forest_relic_included_in_pool_when_domain_unlocked() -> void:
	_impl.build_pool(RELICS_STUB, {}, true)
	assert_true(_impl._relics_by_id.has("root_relic"),
		"root_relic must be in pool when forest_domain_unlocked=true")


func test_both_relics_present_when_domain_unlocked() -> void:
	_impl.build_pool(RELICS_STUB, {}, true)
	assert_eq(_impl._relics_by_id.size(), 2,
		"both neutral and forest relics must be in pool when unlocked")


func test_forest_relic_in_tier_deck_when_domain_unlocked() -> void:
	_impl.build_pool(RELICS_STUB, {}, true)
	var uncommon_list: Array = _impl._all_by_tier.get("uncommon", []) as Array
	var found: bool = false
	for r: Variant in uncommon_list:
		if (r as RelicData).id == "root_relic":
			found = true
	assert_true(found, "root_relic must appear in uncommon deck when forest domain unlocked")
