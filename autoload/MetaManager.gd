extends Node

signal shards_changed(new_total: int)

var meta_state: MetaState:
	get: return _impl.meta_state

var is_adventurer_bag_unlocked: bool:
	get: return _impl.meta_state.adventurer_bag_unlocked

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

var endless_boss_kill_count: int:
	get: return _impl.meta_state.endless_boss_kill_count

var _impl: MetaManagerImpl = MetaManagerImpl.new()


func _ready() -> void:
	_impl.load(SaveManager)
	RunManager.run_ended.connect(func(r: RunManager.EndReason) -> void: _on_run_ended(r))
	RunManager.room_cleared.connect(_on_room_cleared)
	GlobalSignals.hub_entered.connect(_on_hub_entered)


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


func _on_hub_entered() -> void:
	var activated: bool = _impl.try_activate_relic_offers(SaveManager)
	if activated:
		print("[MetaManager] relic offers activated — first hub return after Adventurer Bag unlock")


func purchase_boss_run() -> bool:
	var cost: int = ResourceManager.get_meta_config().get("boss_run_cost", 300)
	var success: bool = _impl.purchase_boss_run(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func purchase_magic_forge() -> bool:
	var cost: int = ResourceManager.get_meta_config().get("magic_forge_cost", 120)
	var success: bool = _impl.purchase_magic_forge(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func purchase_adventuring_gear() -> bool:
	var cost: int = ResourceManager.get_meta_config().get("adventuring_gear_cost", 300)
	var success: bool = _impl.purchase_adventuring_gear(cost, SaveManager)
	if success:
		shards_changed.emit(meta_state.total_shards)
	return success


func _on_room_cleared(room_id: String) -> void:
	if room_id == "boss_room":
		if RunManager.run_mode != "endless":
			return
		var recorded: bool = _impl.record_boss_kill(SaveManager)
		if recorded:
			print("[MetaManager] first boss kill recorded")
		_impl.increment_endless_boss_kills(SaveManager)
		print("[MetaManager] endless boss kills: {n}".format({"n": _impl.meta_state.endless_boss_kill_count}))
		return
	if RunManager.current_room == null:
		return
	var room_type: String = (RunManager.current_room as RoomSpawner).room_type_id
	if not room_type.contains("Elite"):
		return
	var unlocked: bool = _impl.unlock_adventurer_bag(SaveManager)
	if unlocked:
		print("[MetaManager] Adventurer Bag unlocked — room_id={id}".format({"id": room_id}))


func _on_run_ended(reason: RunManager.EndReason) -> void:
	if RunManager.run_mode == "boss":
		if reason == RunManager.EndReason.CASH_OUT:
			var award: int = ResourceManager.get_meta_config().get("boss_run_shard_award", 35)
			add_shards(award)
			print("[MetaManager] boss run cash out — {n} shards awarded".format({"n": award}))
		else:
			print("[MetaManager] boss run ended — no shards (died)")
		return
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
