extends Node

signal shards_changed(new_total: int)

var meta_state: MetaState:
	get: return _impl.meta_state

var _impl: MetaManagerImpl = MetaManagerImpl.new()


func _ready() -> void:
	_impl.load(SaveManager)
	RunManager.run_ended.connect(func(r: RunManager.EndReason) -> void: _on_run_ended(r))


func can_spend(cost: int) -> bool:
	return _impl.can_spend(cost)


func spend(cost: int) -> bool:
	var success: bool = _impl.spend(cost, SaveManager)
	if success and cost > 0:
		shards_changed.emit(meta_state.total_shards)
	return success


func add_shards(amount: int) -> void:
	_impl.add_shards(amount, SaveManager)
	if amount > 0:
		shards_changed.emit(meta_state.total_shards)


var damage_multiplier: float:
	get:
		var cfg: Dictionary = ResourceManager.get_meta_config().get("damage_upgrade", {})
		return _impl.get_damage_multiplier(cfg.get("damage_per_level", 0.1))


func get_next_upgrade_cost() -> int:
	var cfg: Dictionary = ResourceManager.get_meta_config().get("damage_upgrade", {})
	return _impl.get_upgrade_cost(
		meta_state.damage_upgrade_level,
		cfg.get("base_cost", 50),
		cfg.get("cost_scale", 1.2)
	)


func purchase_damage_upgrade() -> bool:
	var cfg: Dictionary = ResourceManager.get_meta_config().get("damage_upgrade", {})
	if meta_state.damage_upgrade_level >= cfg.get("max_levels", 10):
		return false
	var cost: int = get_next_upgrade_cost()
	var success: bool = _impl.purchase_damage_upgrade(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func _on_run_ended(_reason: RunManager.EndReason) -> void:
	var summary := RunManager.run_summary
	if summary == null:
		return
	var divisor: int = ResourceManager.get_meta_config().get("shard_divisor", 3)
	var earned: int = summary.essence_cashed_out / divisor
	add_shards(earned)
	print("[MetaManager] {shards} shards earned — total={total}".format({
		"shards": earned,
		"total": meta_state.total_shards,
	}))
