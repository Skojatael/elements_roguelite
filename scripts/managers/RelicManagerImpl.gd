class_name RelicManagerImpl
extends RefCounted

const OFFER_INTERVAL: int = 2

var active_relic_ids: Array[String] = []
var standard_rooms_cleared: int = 0
var relic_pool: Array[RelicData] = []


## Clears all run state. Called at run start and run end.
func reset() -> void:
	active_relic_ids = []
	standard_rooms_cleared = 0
	relic_pool = []


## Builds the relic pool from the raw JSON dictionary loaded by ResourceManager.
func build_pool(raw: Dictionary) -> void:
	relic_pool = []
	for entry: Variant in raw.get("relics", []):
		if entry is Dictionary:
			relic_pool.append(RelicData.from_dict(entry as Dictionary))
	print("[RelicManager] pool built — size={size}".format({"size": relic_pool.size()}))


## Returns true if a relic offer should trigger for the given room type.
## Elite rooms (room_type_id contains "Elite"): always true, counter unchanged.
## Standard rooms: increments counter; returns true and resets counter when OFFER_INTERVAL is reached.
func should_offer_for_room(room_type_id: String) -> bool:
	if room_type_id.contains("Elite"):
		return true
	standard_rooms_cleared += 1
	if standard_rooms_cleared >= OFFER_INTERVAL:
		standard_rooms_cleared = 0
		return true
	return false


## Returns Array[RelicData] of exactly 2 entries drawn from relic_pool.
## If pool has 1 entry: returns that entry twice.
## If pool is empty: returns [].
## Otherwise: shuffles and returns first 2 (always distinct).
func draw_offer() -> Array[RelicData]:
	if relic_pool.is_empty():
		return []
	if relic_pool.size() == 1:
		return [relic_pool[0], relic_pool[0]]
	var shuffled: Array[RelicData] = relic_pool.duplicate()
	shuffled.shuffle()
	return [shuffled[0], shuffled[1]]


## Appends relic_id to active_relic_ids.
func pick_relic(relic_id: String) -> void:
	active_relic_ids.append(relic_id)


## Returns the combined multiplicative effect_mult for all held relics with effect_stat == stat.
## Returns 1.0 if no held relics match the stat.
func compute_stat_mult(stat: String) -> float:
	var mult: float = 1.0
	var data_by_id: Dictionary = {}
	for r: RelicData in relic_pool:
		data_by_id[r.id] = r
	for relic_id: String in active_relic_ids:
		var relic: Variant = data_by_id.get(relic_id)
		if relic is RelicData and (relic as RelicData).effect_stat == stat:
			mult *= (relic as RelicData).effect_mult
	return mult
