extends Node

enum EndReason { DIED, CASH_OUT }

## Emitted at the end of start_run(), after all state is reset.
signal run_started(mode: String)

## Emitted when end_run() is called on an active run.
signal run_ended(reason: EndReason)

## Emitted when a registered room's room_cleared signal fires.
signal room_cleared(room_id: String)

# --- Session State ---

var run_id: String = ""
var is_run_active: bool = false
var run_mode: String = ""
var current_tier: int = 1
var run_start_time: float = 0.0
var run_currency: float = 0.0
var current_room: Node = null
var current_room_depth: int = 0

## Tracks which rooms have been cleared during the current run.
var cleared_rooms: Dictionary = {}
var enemies_slain: int = 0

## Snapshot of current run state. Populated by start_run(); readable at all times.
var run_state: RunState = RunState.new()

## Summary of the last completed run. Null before the first run ends.
var run_summary: RunSummary = null

## Player state snapshot. Updated via health_changed signal; reset in end_run().
var player_state: PlayerState = PlayerState.new()

# --- Services ---

var difficulty_service: DifficultyService
var rewards_service: RewardsService
var room_factory: RoomFactory


func _ready() -> void:
	difficulty_service = DifficultyService.new()
	rewards_service = RewardsService.new()
	room_factory = RoomFactory.new()


# --- Lifecycle ---

## Starts a new run. Safe to call while a run is already active — fully resets state.
func start_run(mode: String) -> void:
	if mode not in ["endless", "boss"]:
		push_warning("RunManager: invalid run_mode '{mode}' — expected 'endless' or 'boss'".format({"mode": mode}))
	run_id = str(Time.get_ticks_msec())
	is_run_active = true
	run_mode = mode
	current_tier = 1
	run_start_time = Time.get_ticks_msec() / 1000.0
	run_currency = 0.0
	current_room = null
	current_room_depth = 0
	enemies_slain = 0
	cleared_rooms = {}
	run_state = RunState.new()
	run_state.run_mode = mode
	run_state.cleared_rooms = cleared_rooms
	print("[RunManager] run started — id={id} mode={mode}".format({"id": run_id, "mode": run_mode}))
	run_started.emit(mode)
	player_state = PlayerState.new()
	run_state.player_state = player_state
	var players: Array = get_tree().get_nodes_in_group("player")
	for player: Node in players:
		var stats: StatsComponent = player.get_node_or_null("StatsComponent")
		if stats != null:
			if not stats.health_changed.is_connected(_on_player_health_changed):
				stats.health_changed.connect(_on_player_health_changed)
			player_state.current_hp = stats.current_health
			stats.reset()


## Ends the active run. No-op if no run is active.
## Session state remains readable until the next start_run() call.
func end_run(reason: EndReason) -> void:
	if not is_run_active:
		print("[RunManager] end_run called — no active run, ignoring")
		return
	is_run_active = false
	var cashed_out: int
	if reason == EndReason.DIED:
		cashed_out = floori(run_currency * 0.85)  # floor ensures result is always a whole number
	else:
		cashed_out = floori(run_currency)
	print("[Essence] {amount} essence cashed out".format({"amount": cashed_out}))
	run_summary = RunSummary.create(cashed_out, enemies_slain, cleared_rooms.size(), reason)
	var players: Array = get_tree().get_nodes_in_group("player")
	for player: Node in players:
		var stats: StatsComponent = player.get_node_or_null("StatsComponent")
		if stats != null:
			player_state = PlayerState.new()
			player_state.current_hp = stats.max_health
			run_state.player_state = player_state
			break
	run_ended.emit(reason)
	print("[RunManager] run ended — id={id} reason={reason} currency={currency}".format({
		"id": run_id,
		"reason": EndReason.keys()[reason],
		"currency": run_currency,
	}))


# --- Room Registration ---

## Spawns a room via RoomFactory, connects its signals, and returns the RoomSpawner.
## room_id MUST be supplied by the caller — RunManager does not generate IDs.
func spawn_room(room_data: RoomData, room_id: String, context: SpawnContext) -> RoomSpawner:
	var spawner: RoomSpawner = room_factory.spawn_room(room_data, room_id, context)
	if spawner == null:
		push_warning("RunManager: spawn_room failed for room_id='{id}' room_type='{type}'".format({"id": room_id, "type": room_data.room_type_id}))
		return null
	spawner.room_entered.connect(_on_room_entered.bind(spawner))
	spawner.room_cleared.connect(_on_room_cleared)
	spawner.enemy_defeated.connect(_on_enemy_defeated)
	current_room = spawner
	return spawner


## Called by RoomSpawner in _ready() when auto_register=true. Connects RunManager to the room's signals.
func register_room(spawner: Node) -> void:
	spawner.room_entered.connect(_on_room_entered.bind(spawner))
	spawner.room_cleared.connect(_on_room_cleared)
	spawner.enemy_defeated.connect(_on_enemy_defeated)
	current_room = spawner
	print("[RunManager] registered room_id='{id}' room_type='{type}'".format({"id": spawner.room_id, "type": spawner.room_type_id}))


func _on_room_entered(room_id: String, spawner: Node) -> void:
	if not is_run_active:
		return
	current_room = spawner
	run_state.current_room_id = room_id
	current_room_depth = (spawner as RoomSpawner).depth
	run_state.max_depth_reached = maxi(run_state.max_depth_reached, current_room_depth)
	print("[RunManager] room entered room_id='{id}'".format({"id": room_id}))


func _on_enemy_defeated(enemy_type_id: String) -> void:
	enemies_slain += 1
	if ResourceManager.get_enemy_rooms_required(enemy_type_id) > 0:
		return
	var base_essence: float = ResourceManager.get_enemy_base_essence(enemy_type_id)
	var essence_depth_scale: float = ResourceManager.get_dungeon_config().get("essence_depth_scale", 0.10)
	var room_essence_mult: float = (current_room as RoomSpawner).essence_mult if current_room != null else 1.0
	var essence: int = floori(base_essence * (1.0 + essence_depth_scale * float(current_room_depth - 1)) * room_essence_mult)
	if essence > 0:
		add_currency(float(essence))


func _on_room_cleared(room_id: String) -> void:
	if not is_run_active:
		return
	mark_room_cleared(room_id)
	room_cleared.emit(room_id)
	print("[RunManager] room cleared room_id='{id}'".format({"id": room_id}))


# --- Currency ---

## Adds gold to the current run. No-op with warning if no run is active.
func add_currency(amount: float) -> void:
	if not is_run_active:
		push_warning("RunManager: add_currency called with no active run")
		return
	run_currency = maxf(run_currency + amount, 0.0)
	run_state.run_currency = run_currency
	print("[RunManager] currency +{amount} — total={total}".format({"amount": amount, "total": run_currency}))


# --- Room State ---

## Marks a room as cleared for the current run.
func mark_room_cleared(room_id: String) -> void:
	cleared_rooms[room_id] = true


## Returns true if the room was already cleared during this run.
func is_room_cleared(room_id: String) -> bool:
	return cleared_rooms.has(room_id)


func _on_player_health_changed(new_health: float, _max_health: float) -> void:
	player_state.current_hp = new_health


## Legacy reset — preserved for backward compatibility.
func start_new_run() -> void:
	cleared_rooms = {}
