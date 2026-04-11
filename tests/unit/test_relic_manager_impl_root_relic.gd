extends GutTest

const RelicManagerImpl = preload("res://scripts/managers/RelicManagerImpl.gd")

var _impl: RelicManagerImpl

## Minimal relics dict with root_relic at 100% chance, used across most tests.
const _RELICS_FULL_CHANCE: Dictionary = {
	"domain": {
		"forest": {
			"uncommon": {
				"root_relic": {
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
}

## Minimal relics dict with root_relic at 0% chance.
const _RELICS_ZERO_CHANCE: Dictionary = {
	"domain": {
		"forest": {
			"uncommon": {
				"root_relic": {
					"name": "Rootweave Band",
					"tags": ["melee"],
					"effect_stat": "",
					"effect_mult": 1.0,
					"condition_type": "root_on_melee_hit",
					"root_chance": 0.0,
					"root_duration": 0.6,
					"description": "test",
					"deck_count": 1,
				}
			}
		}
	}
}


func before_each() -> void:
	_impl = RelicManagerImpl.new()


# --- has_root_relic ---

func test_has_root_relic_false_when_no_relics_held() -> void:
	_impl.build_pool(_RELICS_FULL_CHANCE, {}, true)
	assert_false(_impl.has_root_relic())


func test_has_root_relic_true_after_pick() -> void:
	_impl.build_pool(_RELICS_FULL_CHANCE, {}, true)
	_impl.pick_relic("root_relic")
	assert_true(_impl.has_root_relic())


func test_has_root_relic_false_after_reset() -> void:
	_impl.build_pool(_RELICS_FULL_CHANCE, {}, true)
	_impl.pick_relic("root_relic")
	_impl.reset()
	assert_false(_impl.has_root_relic())


# --- get_root_on_hit_duration ---

func test_get_root_on_hit_duration_zero_when_relic_not_held() -> void:
	_impl.build_pool(_RELICS_FULL_CHANCE, {}, true)
	# relic not picked — must always return 0.0
	for _i: int in 10:
		assert_almost_eq(_impl.get_root_on_hit_duration(), 0.0, 0.001)


func test_get_root_on_hit_duration_returns_duration_when_chance_is_one() -> void:
	_impl.build_pool(_RELICS_FULL_CHANCE, {}, true)
	_impl.pick_relic("root_relic")
	# root_chance = 1.0 → always returns root_duration (0.6)
	assert_almost_eq(_impl.get_root_on_hit_duration(), 0.6, 0.001)


func test_get_root_on_hit_duration_zero_when_chance_is_zero() -> void:
	_impl.build_pool(_RELICS_ZERO_CHANCE, {}, true)
	_impl.pick_relic("root_relic")
	# root_chance = 0.0 → never returns a duration
	for _i: int in 10:
		assert_almost_eq(_impl.get_root_on_hit_duration(), 0.0, 0.001)


func test_get_root_on_hit_duration_zero_after_reset() -> void:
	_impl.build_pool(_RELICS_FULL_CHANCE, {}, true)
	_impl.pick_relic("root_relic")
	_impl.reset()
	for _i: int in 10:
		assert_almost_eq(_impl.get_root_on_hit_duration(), 0.0, 0.001)
