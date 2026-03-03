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
