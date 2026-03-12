class_name RewardsService
extends RefCounted

func get_boss_reward(base_essence: float, rooms_cleared: int) -> int:
	return floori(base_essence * (1.0 + 0.06 * float(maxi(0, rooms_cleared - 6))))

func get_room_reward(_room_id: String) -> Dictionary:
	return {}
