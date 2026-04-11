class_name MetaManagerImpl
extends RefCounted

var meta_state: MetaState = MetaState.new()


func load(save_manager: Node) -> void:
	meta_state = save_manager.load_meta_state()


func _save(save_manager: Node) -> void:
	meta_state.gold_last_saved_timestamp = int(Time.get_unix_time_from_system())
	save_manager.save_meta_state(meta_state)


func add_shards(amount: int, save_manager: Node) -> void:
	if amount <= 0:
		return
	meta_state.total_shards += amount
	_save(save_manager)


func can_spend(cost: int) -> bool:
	return cost >= 0 and meta_state.total_shards >= cost


func spend(cost: int, save_manager: Node) -> bool:
	if cost == 0:
		return true
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	_save(save_manager)
	return true


func get_upgrade_cost(level: int, base_cost: int, scale: float) -> int:
	var cost: int = base_cost
	for i in level:
		cost = floori(float(cost) * scale)
	return cost



func get_damage_multiplier(damage_per_level: float) -> float:
	return pow(1.0 + damage_per_level, float(meta_state.damage_upgrade_level))


## Records first boss kill. Returns true if this call changed the state.
func record_boss_kill(save_manager: Node) -> bool:
	if meta_state.first_boss_killed:
		return false
	meta_state.first_boss_killed = true
	_save(save_manager)
	return true


## Purchases Adventuring Gear if affordable and not already owned. Returns true on success.
func purchase_adventuring_gear(cost: int, save_manager: Node) -> bool:
	if meta_state.adventuring_gear_owned:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.adventuring_gear_owned = true
	_save(save_manager)
	return true


## Increments the endless-mode boss kill counter and saves.
func increment_endless_boss_kills(save_manager: Node) -> void:
	meta_state.endless_boss_kill_count += 1
	_save(save_manager)


## Purchases the Boss Run unlock if affordable and not already unlocked. Returns true on success.
func purchase_boss_run(cost: int, save_manager: Node) -> bool:
	if meta_state.boss_run_unlocked:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.boss_run_unlocked = true
	_save(save_manager)
	return true


## Purchases Magic Forge unlock if affordable and not already unlocked. Returns true on success.
func purchase_magic_forge(cost: int, save_manager: Node) -> bool:
	if meta_state.magic_forge_unlocked:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.magic_forge_unlocked = true
	_save(save_manager)
	return true


## Purchases Mage Tower restoration if affordable and not already unlocked. Returns true on success.
func purchase_mage_tower(cost: int, save_manager: Node) -> bool:
	if meta_state.mage_tower_unlocked:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.mage_tower_unlocked = true
	_save(save_manager)
	return true


## Purchases Relic System unlock via Mage Tower. Returns true on success.
func purchase_mage_tower_relic_system(cost: int, save_manager: Node) -> bool:
	if meta_state.relic_offers_active:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.relic_offers_active = true
	_save(save_manager)
	return true


## Purchases damage upgrade if under max_levels and affordable. Returns true on success.
func purchase_damage_upgrade(cost: int, max_levels: int, save_manager: Node) -> bool:
	if meta_state.damage_upgrade_level >= max_levels:
		return false
	if meta_state.total_shards < cost:
		return false
	meta_state.total_shards -= cost
	meta_state.damage_upgrade_level += 1
	_save(save_manager)
	return true


func get_essence_gain_multiplier(essence_per_level: float) -> float:
	return pow(1.0 + essence_per_level, meta_state.essence_gain_level)


func can_spend_gold(cost: float) -> bool:
	return cost >= 0.0 and meta_state.total_gold >= cost


func spend_gold(cost: float, save_manager: Node) -> bool:
	if cost < 0.0 or meta_state.total_gold < cost:
		return false
	meta_state.total_gold -= cost
	_save(save_manager)
	return true


## Purchases one level of essence gain upgrade if affordable and under max_levels. Returns true on success.
func purchase_essence_gain(base_cost: int, cost_step: int, max_levels: int, save_manager: Node) -> bool:
	if meta_state.essence_gain_level >= max_levels:
		return false
	var cost: float = float(base_cost + meta_state.essence_gain_level * cost_step)
	if not spend_gold(cost, save_manager):
		return false
	meta_state.essence_gain_level += 1
	_save(save_manager)
	return true


## Purchases Alchemy Lab restoration if affordable and not already unlocked. Returns true on success.
func purchase_alchemy_lab(cost: int, save_manager: Node) -> bool:
	if meta_state.alchemy_lab_unlocked:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.alchemy_lab_unlocked = true
	_save(save_manager)
	return true


## Purchases the Transmuter (gold generator) if affordable and not already owned. Returns true on success.
func purchase_gold_generator(cost: int, save_manager: Node) -> bool:
	if meta_state.gold_generator_owned:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.gold_generator_owned = true
	_save(save_manager)
	return true


## Credits gold earned while the game was closed, capped by cap_seconds.
## On first boot (timestamp==0) initialises the timestamp without crediting gold.
## Does not update timestamp on clock rollback (elapsed <= 0).
func apply_offline_gold(now_unix: int, rate_per_hour: float, cap_seconds: int, save_manager: Node) -> void:
	if not meta_state.gold_generator_owned:
		return
	if meta_state.gold_last_saved_timestamp == 0:
		_save(save_manager)
		return
	var elapsed: int = now_unix - meta_state.gold_last_saved_timestamp
	if elapsed <= 0:
		return
	var capped_elapsed: int = mini(elapsed, cap_seconds)
	meta_state.total_gold += float(capped_elapsed) * rate_per_hour / 3600.0
	_save(save_manager)


## Returns the current storage cap in seconds based on upgrade level.
func get_gold_storage_cap_seconds(base_hours: int, hours_per_level: int) -> int:
	return (base_hours + hours_per_level * meta_state.gold_storage_cap_level) * 3600


## Purchases a storage cap upgrade level if affordable and not yet at max. Returns true on success.
func purchase_gold_storage_cap(cost: int, max_levels: int, save_manager: Node) -> bool:
	if meta_state.gold_storage_cap_level >= max_levels:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.gold_storage_cap_level += 1
	_save(save_manager)
	return true


## Accumulates fractional gold for one frame. Returns the current integer floor.
func tick_gold(delta: float, rate_per_hour: float) -> int:
	if not meta_state.gold_generator_owned:
		return floori(meta_state.total_gold)
	meta_state.total_gold += delta * rate_per_hour / 3600.0
	return floori(meta_state.total_gold)


## Returns the shard generation rate per hour for the current level. Returns 0.0 at level 0.
func get_shard_rate_per_hour(rates: Array) -> float:
	if meta_state.shard_generator_level <= 0:
		return 0.0
	return float(rates[meta_state.shard_generator_level - 1])


## Accumulates fractional shards for one frame. Returns whole shards earned this tick.
func tick_shard_generator(delta: float, rates: Array) -> int:
	if meta_state.shard_generator_level <= 0:
		return 0
	meta_state.shard_accumulator += delta * get_shard_rate_per_hour(rates) / 3600.0
	var earned: int = floori(meta_state.shard_accumulator)
	meta_state.shard_accumulator -= float(earned)
	return earned


## Credits shards earned while offline, capped by cap_seconds. Returns shards earned.
## Must be called BEFORE apply_offline_gold to share the same gold_last_saved_timestamp.
func apply_offline_shards(now_unix: int, rates: Array, cap_seconds: int, save_manager: Node) -> int:
	if meta_state.shard_generator_level <= 0:
		return 0
	if meta_state.gold_last_saved_timestamp == 0:
		return 0
	var elapsed: int = now_unix - meta_state.gold_last_saved_timestamp
	if elapsed <= 0:
		return 0
	var capped: int = mini(elapsed, cap_seconds)
	var earned: int = floori(float(capped) * get_shard_rate_per_hour(rates) / 3600.0)
	if earned > 0:
		add_shards(earned, save_manager)
	return earned


## Purchases one level of shard generator if affordable and under max_levels. Returns true on success.
func purchase_shard_generator(cost: int, max_levels: int, save_manager: Node) -> bool:
	if meta_state.shard_generator_level >= max_levels:
		return false
	if not spend_gold(float(cost), save_manager):
		return false
	meta_state.shard_generator_level += 1
	_save(save_manager)
	return true


## Purchases the Rarity Luck upgrade if not already owned and affordable. Returns true on success.
func purchase_rarity_luck(cost: int, save_manager: Node) -> bool:
	if meta_state.rarity_luck_owned:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.rarity_luck_owned = true
	_save(save_manager)
	return true


## Purchases the Arcane Reservoir (missile extra charge) if not already owned and affordable. Returns true on success.
func purchase_missile_extra_charge(cost: int, save_manager: Node) -> bool:
	if meta_state.missile_extra_charge_owned:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.missile_extra_charge_owned = true
	_save(save_manager)
	return true


## Sets book_of_skill_gate_reached if not already set and saves. Returns true if state changed.
func record_book_of_skill_gate(save_manager: Node) -> bool:
	if meta_state.book_of_skill_gate_reached:
		return false
	meta_state.book_of_skill_gate_reached = true
	_save(save_manager)
	return true


## Purchases the Book of Skill if not already owned and affordable. Returns true on success.
func purchase_book_of_skill(cost: int, save_manager: Node) -> bool:
	if meta_state.book_of_skill_owned:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.book_of_skill_owned = true
	_save(save_manager)
	return true


## Purchases the Forest Domain upgrade if not already owned and affordable. Returns true on success.
func purchase_forest_domain(cost: int, save_manager: Node) -> bool:
	if meta_state.forest_domain_unlocked:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.forest_domain_unlocked = true
	_save(save_manager)
	return true


## Purchases the Depth Scaling upgrade if not already owned and affordable. Returns true on success.
func purchase_depth_scaling(cost: int, save_manager: Node) -> bool:
	if meta_state.depth_scaling_unlocked:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.depth_scaling_unlocked = true
	_save(save_manager)
	return true


## Computes shards earned at end of an endless run.
static func compute_endless_shards(essence: int, divisor: int) -> int:
	return essence / divisor


## Computes shards earned at end of a boss run.
static func compute_boss_shards(reason_is_cash_out: bool, award: int) -> int:
	return award if reason_is_cash_out else 0
