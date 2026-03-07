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


## Activates relic offers if the Adventurer Bag is unlocked and offers are not yet active.
## Returns true if this call changed the state (first activation), false otherwise.
func try_activate_relic_offers(save_manager: Node) -> bool:
	if not meta_state.adventurer_bag_unlocked:
		return false
	if meta_state.relic_offers_active:
		return false
	meta_state.relic_offers_active = true
	save_manager.save_meta_state(meta_state)
	return true


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


## Sets adventurer_bag_unlocked if not already set. Returns true if this call
## changed the state (first unlock), false if already unlocked.
func unlock_adventurer_bag(save_manager: Node) -> bool:
	if meta_state.adventurer_bag_unlocked:
		return false
	meta_state.adventurer_bag_unlocked = true
	save_manager.save_meta_state(meta_state)
	return true
