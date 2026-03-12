class_name SaveManagerImpl
extends RefCounted

const SAVE_PATH: String = "user://meta_save.json"


func save_meta_state(state: MetaState) -> void:
	var data: Dictionary = {
		"total_shards": state.total_shards,
		"damage_upgrade_level": state.damage_upgrade_level,
		"relic_offers_active": state.relic_offers_active,
		"first_boss_killed": state.first_boss_killed,
		"adventuring_gear_owned": state.adventuring_gear_owned,
		"endless_boss_kill_count": state.endless_boss_kill_count,
		"boss_run_unlocked": state.boss_run_unlocked,
		"magic_forge_unlocked": state.magic_forge_unlocked,
		"mage_tower_unlocked": state.mage_tower_unlocked,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open save file for writing — path={path}".format({"path": SAVE_PATH}))
		return
	file.store_string(JSON.stringify(data))
	file.close()


func load_meta_state() -> MetaState:
	var state := MetaState.new()
	if not FileAccess.file_exists(SAVE_PATH):
		return state
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: failed to open save file for reading — path={path}".format({"path": SAVE_PATH}))
		return state
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		state.total_shards = int((parsed as Dictionary).get("total_shards", 0))
		state.damage_upgrade_level = int((parsed as Dictionary).get("damage_upgrade_level", 0))
		state.relic_offers_active = bool((parsed as Dictionary).get("relic_offers_active", false))
		state.first_boss_killed = bool((parsed as Dictionary).get("first_boss_killed", false))
		state.adventuring_gear_owned = bool((parsed as Dictionary).get("adventuring_gear_owned", false))
		state.endless_boss_kill_count = int((parsed as Dictionary).get("endless_boss_kill_count", 0))
		state.boss_run_unlocked = bool((parsed as Dictionary).get("boss_run_unlocked", false))
		state.magic_forge_unlocked = bool((parsed as Dictionary).get("magic_forge_unlocked", false))
		state.mage_tower_unlocked = bool((parsed as Dictionary).get("mage_tower_unlocked", false))
	return state
