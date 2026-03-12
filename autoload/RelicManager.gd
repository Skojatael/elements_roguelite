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
	if _impl.should_offer_for_room(room_type):
		var options: Array[RelicData] = _impl.draw_offer()
		if options.is_empty():
			print("[RelicManager] relic pool is empty — no offer")
			return
		print("[RelicManager] offer triggered — room_id='{id}' room_type='{type}'".format({
			"id": room_id,
			"type": room_type,
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


## Returns the combined damage multiplier from conditional relics at hit time.
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float:
	return _impl.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio)


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


## Draws an offer from the pool and emits relic_offer_ready. No-op if pool is empty.
func trigger_offer() -> void:
	var options: Array[RelicData] = _impl.draw_offer()
	if options.is_empty():
		print("[RelicManager] trigger_offer — pool empty, no offer")
		return
	relic_offer_ready.emit(options)
