class_name RelicManagerImpl
extends RefCounted

const OFFER_INTERVAL: int = 2

var active_relic_ids: Array[String] = []
var standard_rooms_cleared: int = 0
var _relics_by_id: Dictionary = {}
var _all_by_tier: Dictionary = {}
var _decks: Dictionary = {}
var _tier_weights: Dictionary = {}


## Clears all run state. Called at run start and run end.
func reset() -> void:
	active_relic_ids = []
	standard_rooms_cleared = 0
	_relics_by_id = {}
	_all_by_tier = {}
	_decks = {}
	_tier_weights = {}


## Parses relics JSON and config into per-tier decks and weight table.
func build_pool(relics_raw: Dictionary, config_raw: Dictionary) -> void:
	_relics_by_id = {}
	_all_by_tier = {}
	for tier: Variant in relics_raw.get("relics", {}).keys():
		var tier_str: String = str(tier)
		_all_by_tier[tier_str] = []
		for relic_id: Variant in relics_raw["relics"][tier].keys():
			var entry: Dictionary = relics_raw["relics"][tier][relic_id].duplicate()
			entry["id"] = str(relic_id)
			entry["tier"] = tier_str
			var r: RelicData = RelicData.from_dict(entry)
			_relics_by_id[r.id] = r
			(_all_by_tier[tier_str] as Array).append(r)
	# build weights — only tiers with relics, normalised
	var raw_weights: Dictionary = config_raw.get("relic_tier_weights", {})
	var weight_sum: float = 0.0
	for tier: Variant in _all_by_tier.keys():
		if raw_weights.has(tier):
			weight_sum += float(raw_weights[tier])
	for tier: Variant in _all_by_tier.keys():
		var w: float = float(raw_weights.get(tier, 0.0))
		_tier_weights[str(tier)] = w / weight_sum if weight_sum > 0.0 else 1.0 / _all_by_tier.size()
	# initialise decks
	_decks = {}
	for tier: Variant in _all_by_tier.keys():
		var deck: Array[RelicData] = []
		deck.assign(_all_by_tier[str(tier)])
		deck.shuffle()
		_decks[str(tier)] = deck
	print("[RelicManager] pool built — relics={count} tiers={tiers}".format({
		"count": _relics_by_id.size(),
		"tiers": _all_by_tier.keys(),
	}))


## Selects a tier by weight, draws from that tier's deck.
## Reshuffles the tier's deck from _all_by_tier if it is empty.
func _draw_one() -> RelicData:
	var roll: float = randf()
	var cumulative: float = 0.0
	var selected_tier: String = ""
	for tier: Variant in _tier_weights.keys():
		cumulative += float(_tier_weights[tier])
		if roll < cumulative:
			selected_tier = str(tier)
			break
	if selected_tier.is_empty():
		selected_tier = str((_tier_weights.keys() as Array).back())
	if (_decks[selected_tier] as Array).is_empty():
		var refill: Array[RelicData] = []
		refill.assign(_all_by_tier[selected_tier])
		refill.shuffle()
		_decks[selected_tier] = refill
		print("[RelicManager] deck reshuffled — tier={tier}".format({"tier": selected_tier}))
	return (_decks[selected_tier] as Array[RelicData]).pop_back()


## Returns Array[RelicData] of exactly 2 entries.
## Empty if no relics defined. Both same if only 1 relic exists.
## Otherwise draws two cards independently via _draw_one().
func draw_offer() -> Array[RelicData]:
	if _relics_by_id.is_empty():
		return []
	if _relics_by_id.size() == 1:
		var single: RelicData = (_relics_by_id.values() as Array)[0]
		return [single, single]
	return [_draw_one(), _draw_one()]


## Appends relic_id to active_relic_ids.
func pick_relic(relic_id: String) -> void:
	active_relic_ids.append(relic_id)


## Returns the combined damage multiplier from conditional relics at hit time.
## target_hp_ratio:   target's current_hp / max_hp  (0.0–1.0)
## attacker_hp_ratio: attacker's current_hp / max_hp (0.0–1.0)
## Returns 1.0 if no conditional relics are active or no conditions are met.
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float:
	var mult: float = 1.0
	if active_relic_ids.has("executioners_mark") and target_hp_ratio < 0.30:
		mult *= 1.35
	if active_relic_ids.has("berserker_stone") and attacker_hp_ratio < 0.50:
		mult *= 1.30
	return mult


## Returns the combined multiplicative effect_mult for all held relics with effect_stat == stat.
## Returns 1.0 if no held relics match the stat.
func compute_stat_mult(stat: String) -> float:
	var mult: float = 1.0
	for relic_id: String in active_relic_ids:
		var relic: Variant = _relics_by_id.get(relic_id)
		if relic is RelicData and (relic as RelicData).effect_stat == stat:
			mult *= (relic as RelicData).effect_mult
	return mult


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
