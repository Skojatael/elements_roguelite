class_name MetaManagerImpl
extends RefCounted

var meta_state: MetaState = MetaState.new()


func load(save_manager: Node) -> void:
	meta_state = save_manager.load_meta_state()


func add_shards(amount: int, save_manager: Node) -> void:
	if amount <= 0:
		return
	meta_state.total_shards += amount
	save_manager.save_meta_state(meta_state)


func can_spend(cost: int) -> bool:
	return cost >= 0 and meta_state.total_shards >= cost


func spend(cost: int, save_manager: Node) -> bool:
	if cost == 0:
		return true
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	save_manager.save_meta_state(meta_state)
	return true


func get_upgrade_cost(level: int, base_cost: int, scale: float) -> int:
	var cost: int = base_cost
	for i in level:
		cost = floori(float(cost) * scale)
	return cost


func purchase_damage_upgrade(cost: int, save_manager: Node) -> bool:
	if meta_state.total_shards < cost:
		return false
	meta_state.total_shards -= cost
	meta_state.damage_upgrade_level += 1
	save_manager.save_meta_state(meta_state)
	return true


func get_damage_multiplier(damage_per_level: float) -> float:
	return pow(1.0 + damage_per_level, float(meta_state.damage_upgrade_level))


## Records first boss kill. Returns true if this call changed the state.
func record_boss_kill(save_manager: Node) -> bool:
	if meta_state.first_boss_killed:
		return false
	meta_state.first_boss_killed = true
	save_manager.save_meta_state(meta_state)
	return true


## Purchases Adventuring Gear if affordable. Returns true on success.
func purchase_adventuring_gear(cost: int, save_manager: Node) -> bool:
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.adventuring_gear_owned = true
	save_manager.save_meta_state(meta_state)
	return true


## Increments the endless-mode boss kill counter and saves.
func increment_endless_boss_kills(save_manager: Node) -> void:
	meta_state.endless_boss_kill_count += 1
	save_manager.save_meta_state(meta_state)


## Purchases the Boss Run unlock if affordable and not already unlocked. Returns true on success.
func purchase_boss_run(cost: int, save_manager: Node) -> bool:
	if meta_state.boss_run_unlocked:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.boss_run_unlocked = true
	save_manager.save_meta_state(meta_state)
	return true


## Purchases Magic Forge unlock if affordable and not already unlocked. Returns true on success.
func purchase_magic_forge(cost: int, save_manager: Node) -> bool:
	if meta_state.magic_forge_unlocked:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.magic_forge_unlocked = true
	save_manager.save_meta_state(meta_state)
	return true


## Purchases Mage Tower restoration if affordable and not already unlocked. Returns true on success.
func purchase_mage_tower(cost: int, save_manager: Node) -> bool:
	if meta_state.mage_tower_unlocked:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.mage_tower_unlocked = true
	save_manager.save_meta_state(meta_state)
	return true


## Purchases Relic System unlock via Mage Tower. Returns true on success.
func purchase_mage_tower_relic_system(cost: int, save_manager: Node) -> bool:
	if meta_state.relic_offers_active:
		return false
	if not can_spend(cost):
		return false
	meta_state.total_shards -= cost
	meta_state.relic_offers_active = true
	save_manager.save_meta_state(meta_state)
	return true
