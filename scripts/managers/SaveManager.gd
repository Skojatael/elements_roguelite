class_name SaveManagerImpl
extends RefCounted

const SAVE_PATH: String = "user://meta_save.json"


func save_meta_state(state: MetaState) -> void:
	var data: Dictionary = {
		"total_shards": state.total_shards,
		"damage_upgrade_level": state.damage_upgrade_level,
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
	return state
