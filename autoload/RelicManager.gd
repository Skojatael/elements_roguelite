extends Node

## Emitted when an offer screen should appear. options is Array[RelicData] with 2 entries.
signal relic_offer_ready(options: Array)

## Emitted immediately after a relic is added to the active collection.
signal relic_applied(relic_id: String)

## Emitted when active relics are cleared (run start or run end).
signal relics_cleared()

## The relic IDs held by the player this run. Read-only for all systems except RelicManager.
var active_relic_ids: Array[String]:
	get: return _impl.active_relic_ids

var _impl: RelicManagerImpl = RelicManagerImpl.new()


func _ready() -> void:
	RunManager.run_started.connect(func(_m: String) -> void: _on_run_started())
	RunManager.run_ended.connect(func(_r: RunManager.EndReason) -> void: _on_run_ended())
	RunManager.room_cleared.connect(_on_room_cleared)


func _on_run_started() -> void:
	_impl.reset()
	_impl.build_pool(ResourceManager.get_relics(), ResourceManager.get_meta_config())
	relics_cleared.emit()


func _on_run_ended() -> void:
	_impl.reset()
	relics_cleared.emit()
	print("[RelicManager] run ended — relics cleared")


func _on_room_cleared(room_id: String) -> void:
	if room_id == "boss_room":
		return
	if not MetaManager.is_relic_offers_active:
		return
	if not RunManager.is_run_active:
		return
	var room_type: String = ""
	if RunManager.current_room != null:
		room_type = (RunManager.current_room as RoomSpawner).room_type_id
	if not _impl.should_offer_for_room(room_type):
		return
	var tier: String = "uncommon" if room_type.contains("Elite") else "common"
	var promotion_chance: float = 0.0
	if MetaManager.is_rarity_luck_owned:
		promotion_chance = ResourceManager.get_meta_config().get("magic_forge", {}).get("upgrades", {}).get("rarity_luck_upgrade", {}).get("promotion_chance", 0.1)
	var options: Array[RelicData] = _impl.draw_offer(tier, promotion_chance)
	if options.is_empty():
		print("[RelicManager] relic pool is empty — no offer")
		return
	print("[RelicManager] offer triggered — room_id='{id}' room_type='{type}' tier='{tier}' promotion={p}".format({
		"id": room_id,
		"type": room_type,
		"tier": tier,
		"p": promotion_chance,
	}))
	relic_offer_ready.emit(options)


## Adds relic_id to the active collection, updates PlayerState, emits relic_applied.
func pick_relic(relic_id: String) -> void:
	_impl.pick_relic(relic_id)
	RunManager.player_state.active_modifiers.append(relic_id)
	print("[RelicManager] relic picked — id={id}".format({"id": relic_id}))
	relic_applied.emit(relic_id)


## Returns the combined multiplier for the given stat across all active relics.
## Returns 1.0 if no relics modify that stat.
func get_stat_mult(stat: String) -> float:
	return _impl.compute_stat_mult(stat)


## Returns the combined additive bonus for the given stat across all active relics.
## Returns 0.0 if no relics modify that stat. Used for crit_chance and crit_multiplier.
func get_stat_addend(stat: String) -> float:
	return _impl.compute_stat_addend(stat)


## Returns the combined damage multiplier from conditional relics at hit time.
## target_is_burning: true if the target enemy currently has an active burn effect.
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float, target_is_burning: bool) -> float:
	return _impl.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio, target_is_burning)


## Returns true if the chaining_stone relic is active this run.
func has_chain_relic() -> bool:
	return _impl.has_chain_relic()


## Returns true if the burn relic is active this run.
func has_burn_relic() -> bool:
	return _impl.has_burn_relic()


## Returns the total additive bonus to chain_damage_mult from held relics.
## Returns 0.0 if no chain-bonus relic is held.
func get_chain_damage_bonus() -> float:
	return _impl.get_chain_damage_bonus()


## Draws 3 rare relics and emits relic_offer_ready. Returns true if offer was triggered.
## Returns false if no rare relics are available (caller should show victory overlay directly).
func trigger_boss_offer() -> bool:
	if not MetaManager.is_relic_offers_active:
		return false
	var options: Array[RelicData] = _impl.draw_boss_offer()
	if options.is_empty():
		print("[RelicManager] trigger_boss_offer — no rare relics available, skipping")
		return false
	print("[RelicManager] boss offer triggered — {count} rare relics".format({"count": options.size()}))
	relic_offer_ready.emit(options)
	return true


## Returns true when the melee_missile_charge relic is held and the 3-hit
## threshold is reached. Counter resets to 0 each cycle. Returns false otherwise.
func on_melee_hit() -> bool:
	return _impl.on_melee_hit()


## Returns true if the root_relic is currently held this run.
func has_root_relic() -> bool:
	return _impl.has_root_relic()


## Rolls root-on-hit for the root_relic. Returns root duration (> 0.0) on success,
## or 0.0 if the relic is not held or the probability check fails.
func get_root_on_hit_duration() -> float:
	return _impl.get_root_on_hit_duration()


## Rolls a poison proc on a melee hit against target.
## Delegates to impl; no-op when relic is absent or roll fails.
func try_apply_poison(target: Enemy) -> void:
	_impl.try_apply_poison(target)


## Draws a common offer and emits relic_offer_ready. No-op if pool is empty.
## Used by DevPanel only.
func trigger_offer() -> void:
	var options: Array[RelicData] = _impl.draw_offer("common")
	if options.is_empty():
		print("[RelicManager] trigger_offer — pool empty, no offer")
		return
	relic_offer_ready.emit(options)
