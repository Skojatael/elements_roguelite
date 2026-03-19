class_name RelicManagerImpl
extends RefCounted

const OFFER_INTERVAL: int = 2

var active_relic_ids: Array[String] = []
var standard_rooms_cleared: int = 0
var _relics_by_id: Dictionary = {}
var _all_by_tier: Dictionary = {}
var _decks: Dictionary = {}


## Clears all run state. Called at run start and run end.
func reset() -> void:
	active_relic_ids = []
	standard_rooms_cleared = 0
	_relics_by_id = {}
	_all_by_tier = {}
	_decks = {}


## Parses relics JSON into per-tier decks.
func build_pool(relics_raw: Dictionary, _config_raw: Dictionary) -> void:
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
	_decks = {}
	for tier: Variant in _all_by_tier.keys():
		_decks[str(tier)] = _build_expanded_deck(str(tier))
	print("[RelicManager] pool built — relics={count} tiers={tiers}".format({
		"count": _relics_by_id.size(),
		"tiers": _all_by_tier.keys(),
	}))


## Builds a shuffled deck for the given tier, including each relic deck_count times.
## exclude_id: if non-empty, that relic is excluded (used for second-draw de-dup).
func _build_expanded_deck(tier: String, exclude_id: String = "") -> Array[RelicData]:
	var result: Array[RelicData] = []
	for r: RelicData in (_all_by_tier[tier] as Array[RelicData]):
		if r.id == exclude_id:
			continue
		for _i: int in r.deck_count:
			result.append(r)
	result.shuffle()
	return result


## Draws one relic from the specified tier's deck.
## Reshuffles from _all_by_tier if the deck is empty.
func _draw_one_from_tier(tier: String) -> RelicData:
	if not _decks.has(tier) or not _all_by_tier.has(tier):
		return null
	if (_decks[tier] as Array).is_empty():
		_decks[tier] = _build_expanded_deck(tier)
		print("[RelicManager] deck reshuffled — tier={tier}".format({"tier": tier}))
	return (_decks[tier] as Array[RelicData]).pop_back()


## Returns Array[RelicData] of exactly 2 distinct entries drawn from the given tier.
## Empty if the tier has no relics.
## Refills the deck excluding the first draw before the second draw, guaranteeing distinct relics.
func draw_offer(tier: String) -> Array[RelicData]:
	if not _all_by_tier.has(tier) or (_all_by_tier[tier] as Array).is_empty():
		return []
	var left: RelicData = _draw_one_from_tier(tier)
	if left == null:
		return []
	if (_decks[tier] as Array).is_empty():
		_decks[tier] = _build_expanded_deck(tier, left.id)
	var right: RelicData = _draw_one_from_tier(tier)
	if right == null:
		return [left]
	return [left, right]


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


## Returns the combined additive bonus for all held relics with effect_stat == stat.
## Returns 0.0 if no held relics match the stat.
func compute_stat_addend(stat: String) -> float:
	var total: float = 0.0
	for relic_id: String in active_relic_ids:
		var relic: Variant = _relics_by_id.get(relic_id)
		if not relic is RelicData:
			continue
		if (relic as RelicData).effect_stat != stat:
			continue
		total += (relic as RelicData).effect_mult
	return total


## Returns the combined relic factor for all held relics with effect_stat == stat.
## Relics of the same source (relic) stack additively: factor = 1.0 + sum(effect_mult - 1.0).
## Returns 1.0 (neutral) if no held relics match the stat.
func compute_stat_mult(stat: String) -> float:
	var bonus_sum: float = 0.0
	for relic_id: String in active_relic_ids:
		var relic: Variant = _relics_by_id.get(relic_id)
		if not relic is RelicData:
			continue
		if (relic as RelicData).effect_stat != stat:
			continue
		bonus_sum += (relic as RelicData).effect_mult - 1.0
	return 1.0 + bonus_sum


## Draws up to 3 rare relics not already held by the player.
## Draws from the full rare pool (not the deck) — boss offer is a one-time event.
## Returns empty array if rare tier has no available relics.
func draw_boss_offer() -> Array[RelicData]:
	if not _all_by_tier.has("rare"):
		return []
	var available: Array[RelicData] = []
	for r: RelicData in (_all_by_tier["rare"] as Array):
		if not active_relic_ids.has(r.id):
			available.append(r)
	available.shuffle()
	return available.slice(0, mini(3, available.size()))


## Returns true if the chaining_stone relic is active this run.
## Pure query — no side effects.
func has_chain_relic() -> bool:
	return active_relic_ids.has("chaining_stone")


## Returns true if the burn relic is active this run.
## Pure query — no side effects.
func has_burn_relic() -> bool:
	return active_relic_ids.has("burn")


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
