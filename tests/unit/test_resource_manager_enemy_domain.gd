extends GutTest

const ResourceManagerImplClass = preload("res://scripts/managers/ResourceManager.gd")

const STUB_ENEMIES: Dictionary = {
	"normal": {
		"forest": {
			"forest_tank": {
				"display_name": "Bramble Beast",
				"max_health": 80.0,
				"base_essence": 10,
				"rooms_required": 0
			},
			"forest_healer": {
				"display_name": "Sapling Healer",
				"max_health": 40.0,
				"base_essence": 12,
				"rooms_required": 0
			}
		}
	},
	"elite": {
		"forest": {
			"forest_buffer": {
				"display_name": "Bramble Weaver",
				"max_health": 50.0,
				"base_essence": 15,
				"rooms_required": 0
			}
		}
	},
	"boss": {
		"forest": {
			"forest_boss_thorns": {
				"display_name": "Thornback Charger",
				"max_health": 600.0,
				"base_essence": 80,
				"rooms_required": 6
			}
		}
	}
}

const STUB_DUNGEON_CONFIG: Dictionary = {
	"combat_room_pools": {
		"forest": ["ForestRoom01"],
		"desert": [],
		"frost": []
	}
}

var _impl: ResourceManagerImpl


func before_each() -> void:
	_impl = ResourceManagerImplClass.new()
	_impl._load_enemy_data_from_dict(STUB_ENEMIES)


func test_all_ids_from_all_tiers_registered() -> void:
	assert_true(_impl.enemy_id_exists("forest_tank"), "forest_tank must be registered (normal tier)")
	assert_true(_impl.enemy_id_exists("forest_healer"), "forest_healer must be registered (normal tier)")
	assert_true(_impl.enemy_id_exists("forest_buffer"), "forest_buffer must be registered (elite tier)")
	assert_true(_impl.enemy_id_exists("forest_boss_thorns"), "forest_boss_thorns must be registered (boss tier)")


func test_unknown_id_not_registered() -> void:
	assert_false(_impl.enemy_id_exists("desert_golem"), "unknown id must not be registered")


func test_base_essence_returns_correct_value() -> void:
	assert_almost_eq(_impl.get_enemy_base_essence("forest_tank"), 10.0, 0.001,
		"forest_tank base_essence must be 10")
	assert_almost_eq(_impl.get_enemy_base_essence("forest_boss_thorns"), 80.0, 0.001,
		"forest_boss_thorns base_essence must be 80")


func test_base_essence_returns_zero_for_unknown() -> void:
	assert_almost_eq(_impl.get_enemy_base_essence("nonexistent"), 0.0, 0.001,
		"unknown id must return 0.0 base_essence")


func test_rooms_required_returns_boss_threshold() -> void:
	assert_eq(_impl.get_enemy_rooms_required("forest_boss_thorns"), 6,
		"forest_boss_thorns rooms_required must be 6")


func test_rooms_required_returns_zero_for_normal() -> void:
	assert_eq(_impl.get_enemy_rooms_required("forest_tank"), 0,
		"normal enemy rooms_required must be 0")


func test_get_combat_room_pool_returns_forest_pool() -> void:
	_impl._dungeon_config_cache = STUB_DUNGEON_CONFIG
	_impl._dungeon_config_loaded = true
	var pool: Array = _impl.get_combat_room_pool("forest")
	assert_eq(pool.size(), 1, "forest pool must have 1 entry")
	assert_eq(pool[0], "ForestRoom01", "forest pool must contain ForestRoom01")


func test_get_combat_room_pool_returns_empty_for_empty_domain() -> void:
	_impl._dungeon_config_cache = STUB_DUNGEON_CONFIG
	_impl._dungeon_config_loaded = true
	var pool: Array = _impl.get_combat_room_pool("desert")
	assert_eq(pool.size(), 0, "desert pool must be empty")


func test_get_combat_room_pool_returns_empty_for_unknown_domain() -> void:
	_impl._dungeon_config_cache = STUB_DUNGEON_CONFIG
	_impl._dungeon_config_loaded = true
	var pool: Array = _impl.get_combat_room_pool("unknown_domain")
	assert_eq(pool.size(), 0, "unknown domain must return empty pool")


# --- Real file integration: loading actual data/enemies.json ---
# These tests catch drift between the JSON schema and the parsing code.
# A stale traversal (e.g. accessing an old "enemies" wrapper) produces an
# empty cache, which these tests would catch immediately.

func test_get_enemy_data_returns_full_dict_with_id() -> void:
	var data: Dictionary = _impl.get_enemy_data("forest_tank")
	assert_false(data.is_empty(), "get_enemy_data must return non-empty dict for known id")
	assert_eq(data.get("id", ""), "forest_tank", "returned dict must include injected id field")
	assert_true(data.has("max_health"), "returned dict must include max_health field")


func test_get_enemy_data_returns_empty_for_unknown() -> void:
	var data: Dictionary = _impl.get_enemy_data("nonexistent_enemy")
	assert_true(data.is_empty(), "get_enemy_data must return empty dict for unknown id")


func test_real_file_registers_normal_enemies() -> void:
	var real_impl: ResourceManagerImpl = ResourceManagerImplClass.new()
	assert_true(real_impl.enemy_id_exists("forest_tank"),
		"forest_tank must be registered from real enemies.json")
	assert_true(real_impl.enemy_id_exists("forest_healer"),
		"forest_healer must be registered from real enemies.json")
	assert_true(real_impl.enemy_id_exists("forest_disruptor"),
		"forest_disruptor must be registered from real enemies.json")
	assert_true(real_impl.enemy_id_exists("forest_poisoner"),
		"forest_poisoner must be registered from real enemies.json")


func test_real_file_registers_elite_enemies() -> void:
	var real_impl: ResourceManagerImpl = ResourceManagerImplClass.new()
	assert_true(real_impl.enemy_id_exists("forest_buffer"),
		"forest_buffer must be registered from real enemies.json")
	assert_true(real_impl.enemy_id_exists("forest_reflector"),
		"forest_reflector must be registered from real enemies.json")


func test_real_file_registers_boss_enemy() -> void:
	var real_impl: ResourceManagerImpl = ResourceManagerImplClass.new()
	assert_true(real_impl.enemy_id_exists("forest_boss_thorns"),
		"forest_boss_thorns must be registered from real enemies.json")


func test_real_file_boss_has_correct_rooms_required() -> void:
	var real_impl: ResourceManagerImpl = ResourceManagerImplClass.new()
	assert_eq(real_impl.get_enemy_rooms_required("forest_boss_thorns"), 6,
		"forest_boss_thorns rooms_required must be 6 in real enemies.json")


func test_real_file_boss_has_correct_essence() -> void:
	var real_impl: ResourceManagerImpl = ResourceManagerImplClass.new()
	assert_almost_eq(real_impl.get_enemy_base_essence("forest_boss_thorns"), 80.0, 0.001,
		"forest_boss_thorns base_essence must be 80 in real enemies.json")
