class_name DifficultyService
extends RefCounted

func get_boss_multiplier(rooms_cleared: int) -> float:
	return 1.0 + 0.06 * float(maxi(0, rooms_cleared - 6))

func get_multiplier() -> float:
	return 1.0
