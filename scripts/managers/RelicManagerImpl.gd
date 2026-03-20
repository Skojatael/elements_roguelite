class_name RelicManagerImpl
extends RefCounted

const OFFER_INTERVAL: int = 1
const MELEE_CHARGE_RELIC_ID: String = "melee_missile_charge"

var active_relic_ids: Array[String] = []
var standard_rooms_cleared: int = 0
var _melee_hit_count: int = 0
var _activated_mechanics: Array[String] = []
var _mechanic_tag_names: Array[String] = []
var _relics_by_id: Dictionary = {}
var _all_by_tier: Dictionary = {}
var _decks: Dictionary = {}


## Clears all run state. Called at run start and run end.
func reset() -> void:
	active_relic_ids = []
	standard_rooms_cleared = 0
	_melee_hit_count = 0
	_activated_mechanics = []
	_mechanic_tag_names = []
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
	_compute_mechanic_tags()
	print("[RelicManager] pool built — relics={count} tiers={tiers} mechanic_tags={tags}".format({
		"count": _relics_by_id.size(),
		"tiers": _all_by_tier.keys(),
		"tags": _mechanic_tag_names,
	}))


## Scans the loaded pool for tags of the form "<mechanic>_unlocked" and records
## the mechanic prefix in _mechanic_tag_names. Called once at the end of build_pool().
func _compute_mechanic_tags() -> void:
	_mechanic_tag_names = []
	for r: RelicData in _relics_by_id.values():
		for tag: String in r.tags:
			if not tag.ends_with("_unlocked"):
				continue
			var mechanic: String = tag.left(tag.length() - "_unlocked".length())
			if _mechanic_tag_names.has(mechanic):
				continue
			_mechanic_tag_names.append(mechanic)


## Returns true if relic r may appear in an offer given the current mechanic state.
## An _unlocked relic is ineligible until its prerequisite mechanic is activated.
## A mechanic relic is ineligible once that mechanic has been activated this run.
func _is_relic_eligible(r: RelicData) -> bool:
	for tag: String in r.tags:
		if tag.ends_with("_unlocked"):
			var mechanic: String = tag.left(tag.length() - "_unlocked".length())
			if not _activated_mechanics.has(mechanic):
				return false
		elif _mechanic_tag_names.has(tag) and _activated_mechanics.has(tag):
			return false
	return true


## Builds a shuffled deck for the given tier, including each relic deck_count times.
## exclude_id: if non-empty, that relic is excluded (used for second-draw de-dup).
func _build_expanded_deck(tier: String, exclude_id: String = "") -> Array[RelicData]:
	var result: Array[RelicData] = []
	for r: RelicData in (_all_by_tier[tier] as Array[RelicData]):
		if r.id == exclude_id:
			continue
		if not _is_relic_eligible(r):
			continue
		for _i: int in r.deck_count:
			result.append(r)
	result.shuffle()
	return result


## Returns the next rarity tier above tier, or "" if tier is already the highest.
func _next_tier(tier: String) -> String:
	match tier:
		"common": return "uncommon"
		"uncommon": return "rare"
	return ""


## Draws one relic with optional per-draw rarity promotion.
## Attempts to draw from the next tier if promotion_chance > 0 and the roll succeeds.
## Falls back to base_tier if next tier is absent, empty, or the roll misses.
func _draw_one_with_promotion(base_tier: String, promotion_chance: float) -> RelicData:
	if promotion_chance > 0.0:
		var next: String = _next_tier(base_tier)
		if not next.is_empty() and _all_by_tier.has(next) and not (_all_by_tier[next] as Array).is_empty():
			if randf() < promotion_chance:
				var promoted: RelicData = _draw_one_from_tier(next)
				if promoted != null:
					return promoted
	return _draw_one_from_tier(base_tier)


## Draws one relic from the specified tier's deck.
## Reshuffles from _all_by_tier if the deck is empty.
func _draw_one_from_tier(tier: String) -> RelicData:
	if not _decks.has(tier) or not _all_by_tier.has(tier):
		return null
	if (_decks[tier] as Array).is_empty():
		_decks[tier] = _build_expanded_deck(tier)
		print("[RelicManager] deck reshuffled — tier={tier}".format({"tier": tier}))
	return (_decks[tier] as Array[RelicData]).pop_back()


## Returns Array[RelicData] of exactly 2 distinct entries drawn from tier (or promoted tier).
## promotion_chance: independent per-draw chance (0.0–1.0) to draw from the next higher tier.
## Falls back to base tier if promoted tier is empty. Default 0.0 = no promotion.
## Empty if the base tier has no relics.
func draw_offer(tier: String, promotion_chance: float = 0.0) -> Array[RelicData]:
	if not _all_by_tier.has(tier) or (_all_by_tier[tier] as Array).is_empty():
		return []
	var left: RelicData = _draw_one_with_promotion(tier, promotion_chance)
	if left == null:
		return []
	# Strip copies of left from the deck it was actually drawn from (may differ from base tier).
	var deck: Array = (_decks[left.tier] as Array).filter(
		func(r: RelicData) -> bool: return r.id != left.id
	)
	if deck.is_empty():
		deck = _build_expanded_deck(left.tier, left.id)
	_decks[left.tier] = deck
	if (_decks[tier] as Array).is_empty():
		return [left]
	var right: RelicData = _draw_one_with_promotion(tier, promotion_chance)
	if right == null:
		return [left]
	return [left, right]


## Appends relic_id to active_relic_ids and activates any mechanic tags it carries.
func pick_relic(relic_id: String) -> void:
	active_relic_ids.append(relic_id)
	var relic: Variant = _relics_by_id.get(relic_id)
	if not relic is RelicData:
		return
	for tag: String in (relic as RelicData).tags:
		if not _mechanic_tag_names.has(tag):
			continue
		if _activated_mechanics.has(tag):
			continue
		_activated_mechanics.append(tag)
		print("[RelicManager] mechanic activated — tag={tag}".format({"tag": tag}))


## Evaluates the condition for a single conditional relic at hit time.
## Returns true if the condition is met and the relic's mult should apply.
func _condition_met(r: RelicData, target_hp_ratio: float, attacker_hp_ratio: float, target_is_burning: bool) -> bool:
	match r.condition_type:
		"target_hp_below":
			return target_hp_ratio < r.condition_threshold
		"attacker_hp_below":
			return attacker_hp_ratio < r.condition_threshold
		"target_is_burning":
			return target_is_burning
	return false


## Returns the combined damage multiplier from conditional relics at hit time.
## target_hp_ratio:   target's current_hp / max_hp  (0.0–1.0)
## attacker_hp_ratio: attacker's current_hp / max_hp (0.0–1.0)
## target_is_burning: true if the target enemy currently has an active burn effect
## Returns 1.0 if no conditional relics are active or no conditions are met.
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float, target_is_burning: bool) -> float:
	var mult: float = 1.0
	for relic_id: String in active_relic_ids:
		var relic: Variant = _relics_by_id.get(relic_id)
		if not relic is RelicData:
			continue
		var r: RelicData = relic as RelicData
		if r.condition_type.is_empty():
			continue
		if not _condition_met(r, target_hp_ratio, attacker_hp_ratio, target_is_burning):
			continue
		mult *= r.condition_mult
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
## Note: bypasses draw_offer() entirely; rarity_luck promotion does NOT apply here.
## Returns empty array if rare tier has no available relics.
func draw_boss_offer() -> Array[RelicData]:
	if not _all_by_tier.has("rare"):
		return []
	var available: Array[RelicData] = []
	for r: RelicData in (_all_by_tier["rare"] as Array):
		if not _is_relic_eligible(r):
			continue
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


## Returns the total additive bonus to apply on top of chain_damage_mult for chain hits.
## Sums condition_mult for all held relics with condition_type == "chain_damage_bonus".
## Returns 0.0 if no such relic is held.
func get_chain_damage_bonus() -> float:
	var total: float = 0.0
	for relic_id: String in active_relic_ids:
		var relic: Variant = _relics_by_id.get(relic_id)
		if not relic is RelicData:
			continue
		if (relic as RelicData).condition_type != "chain_damage_bonus":
			continue
		total += (relic as RelicData).condition_mult
	return total


## Returns true when the melee_missile_charge relic is held and the hit counter
## reaches the configured threshold (condition_threshold in relics.json).
## Counter resets to 0 on each threshold hit. Returns false when relic absent.
func on_melee_hit() -> bool:
	if not active_relic_ids.has(MELEE_CHARGE_RELIC_ID):
		return false
	var relic: Variant = _relics_by_id.get(MELEE_CHARGE_RELIC_ID)
	if not relic is RelicData:
		return false
	var threshold: int = roundi((relic as RelicData).condition_threshold)
	_melee_hit_count += 1
	if _melee_hit_count < threshold:
		return false
	_melee_hit_count = 0
	return true


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
