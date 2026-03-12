extends Node

signal shards_changed(new_total: int)

var meta_state: MetaState:
	get: return _impl.meta_state

var is_relic_offers_active: bool:
	get: return _impl.meta_state.relic_offers_active

var is_first_boss_killed: bool:
	get: return _impl.meta_state.first_boss_killed

var is_adventuring_gear_owned: bool:
	get: return _impl.meta_state.adventuring_gear_owned

var is_boss_run_unlocked: bool:
	get: return _impl.meta_state.boss_run_unlocked

var is_magic_forge_unlocked: bool:
	get: return _impl.meta_state.magic_forge_unlocked

var is_mage_tower_unlocked: bool:
	get: return _impl.meta_state.mage_tower_unlocked

var endless_boss_kill_count: int:
	get: return _impl.meta_state.endless_boss_kill_count

var _impl: MetaManagerImpl = MetaManagerImpl.new()


func _ready() -> void:
	_impl.load(SaveManager)
	RunManager.run_ended.connect(func(r: RunManager.EndReason) -> void: _on_run_ended(r))
	RunManager.room_cleared.connect(_on_room_cleared)


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
		var cfg: Dictionary = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("damage_upgrade", {})
		return _impl.get_damage_multiplier(cfg.get("damage_per_level", 0.1))


func get_next_upgrade_cost() -> int:
	var cfg: Dictionary = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("damage_upgrade", {})
	return _impl.get_upgrade_cost(
		meta_state.damage_upgrade_level,
		cfg.get("base_cost", 50),
		cfg.get("cost_scale", 1.2)
	)


func purchase_damage_upgrade() -> bool:
	var cfg: Dictionary = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("damage_upgrade", {})
	var cost: int = get_next_upgrade_cost()
	var success: bool = _impl.purchase_damage_upgrade(cost, cfg.get("max_levels", 10), SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func purchase_boss_run() -> bool:
	var cost: int = ResourceManager.get_meta_config().get("mage_tower", {}).get("upgrades", {}).get("boss_challenge", {}).get("cost", 200)
	var success: bool = _impl.purchase_boss_run(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func purchase_magic_forge() -> bool:
	var cost: int = ResourceManager.get_meta_config().get("magic_forge", {}).get("cost", 120)
	var success: bool = _impl.purchase_magic_forge(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func purchase_adventuring_gear() -> bool:
	var cost: int = ResourceManager.get_meta_config().get("mage_tower", {}).get("upgrades", {}).get("dungeon_expansion", {}).get("cost", 200)
	var success: bool = _impl.purchase_adventuring_gear(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func purchase_mage_tower() -> bool:
	var cost: int = ResourceManager.get_meta_config().get("mage_tower", {}).get("cost", 200)
	var success: bool = _impl.purchase_mage_tower(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func purchase_mage_tower_relic_system() -> bool:
	var cost: int = ResourceManager.get_meta_config().get("mage_tower", {}).get("upgrades", {}).get("relic_system", {}).get("cost", 100)
	var success: bool = _impl.purchase_mage_tower_relic_system(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func _on_room_cleared(room_id: String) -> void:
	if room_id != "boss_room":
		return
	if RunManager.run_mode != "endless":
		return
	var recorded: bool = _impl.record_boss_kill(SaveManager)
	if recorded:
		print("[MetaManager] first boss kill recorded")
	_impl.increment_endless_boss_kills(SaveManager)
	print("[MetaManager] endless boss kills: {n}".format({"n": _impl.meta_state.endless_boss_kill_count}))


func _on_run_ended(reason: RunManager.EndReason) -> void:
	var cfg: Dictionary = ResourceManager.get_meta_config()
	if RunManager.run_mode == "boss":
		var award: int = cfg.get("boss_run_shard_award", 35)
		var earned: int = _impl.compute_boss_shards(reason == RunManager.EndReason.CASH_OUT, award)
		if earned > 0:
			add_shards(earned)
			print("[MetaManager] boss run cash out — {n} shards awarded".format({"n": earned}))
		else:
			print("[MetaManager] boss run ended — no shards (died)")
		return
	var summary := RunManager.run_summary
	if summary == null:
		return
	var earned: int = _impl.compute_endless_shards(summary.essence_cashed_out, cfg.get("shard_divisor", 3))
	add_shards(earned)
	print("[MetaManager] {shards} shards earned — total={total}".format({
		"shards": earned,
		"total": meta_state.total_shards,
	}))
