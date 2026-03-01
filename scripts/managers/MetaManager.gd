class_name MetaManagerImpl
extends RefCounted

var meta_state: MetaState = MetaState.new()


func load(save_manager: Node) -> void:
	meta_state = save_manager.load_meta_state()


func on_run_ended(summary: RunSummary, divisor: int, save_manager: Node) -> void:
	if summary == null:
		return
	var shards_earned: int = summary.essence_cashed_out / divisor
	meta_state.total_shards += shards_earned
	save_manager.save_meta_state(meta_state)
	print("[MetaManager] {shards} shards earned — total={total}".format({
		"shards": shards_earned,
		"total": meta_state.total_shards,
	}))
