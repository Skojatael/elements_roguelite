extends Node

## Emitted when end_run() is called on an active run.
signal run_ended

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
var current_room_index: int = 0

## Tracks which rooms have been cleared during the current run.
var cleared_rooms: Dictionary = {}

# --- Services ---

var difficulty_service: DifficultyService
var rewards_service: RewardsService


func _ready() -> void:
	difficulty_service = DifficultyService.new()
	rewards_service = RewardsService.new()


# --- Lifecycle ---

## Starts a new run. Safe to call while a run is already active — fully resets state.
func start_run(mode: String) -> void:
	if mode not in ["endless", "boss"]:
		push_warning("RunManager: invalid run_mode '%s' — expected 'endless' or 'boss'" % mode)
	run_id = str(Time.get_ticks_msec())
	is_run_active = true
	run_mode = mode
	current_tier = 1
	run_start_time = Time.get_ticks_msec() / 1000.0
	run_currency = 0.0
	current_room = null
	current_room_index = 0
	cleared_rooms = {}
	print("[RunManager] run started — id=%s mode=%s" % [run_id, run_mode])


## Ends the active run. No-op if no run is active.
## Session state remains readable until the next start_run() call.
func end_run(reason: String) -> void:
	if not is_run_active:
		print("[RunManager] end_run called — no active run, ignoring")
		return
	is_run_active = false
	run_ended.emit()
	print("[RunManager] run ended — id=%s rooms=%d currency=%s" % [run_id, current_room_index, run_currency])


# --- Room Registration ---

## Called by RoomSpawner in _ready(). Connects RunManager to the room's signals.
func register_room(spawner: Node) -> void:
	spawner.room_entered.connect(_on_room_entered.bind(spawner))
	spawner.room_cleared.connect(_on_room_cleared)
	print("[RunManager] registered room '%s'" % spawner.room_id)


func _on_room_entered(room_id: String, spawner: Node) -> void:
	if not is_run_active:
		return
	current_room = spawner
	current_room_index += 1
	print("[RunManager] room entered '%s' — index=%d" % [room_id, current_room_index])


func _on_room_cleared(room_id: String) -> void:
	if not is_run_active:
		return
	mark_room_cleared(room_id)
	room_cleared.emit(room_id)
	print("[RunManager] room cleared '%s'" % room_id)


# --- Currency ---

## Adds gold to the current run. No-op with warning if no run is active.
func add_currency(amount: float) -> void:
	if not is_run_active:
		push_warning("RunManager: add_currency called with no active run")
		return
	run_currency = maxf(run_currency + amount, 0.0)
	print("[RunManager] currency +%s — total=%s" % [amount, run_currency])


# --- Room State (preserved from 003-enemy-spawning) ---

## Marks a room as cleared for the current run.
func mark_room_cleared(room_id: String) -> void:
	cleared_rooms[room_id] = true


## Returns true if the room was already cleared during this run.
func is_room_cleared(room_id: String) -> bool:
	return cleared_rooms.has(room_id)


## Legacy reset — preserved for backward compatibility.
func start_new_run() -> void:
	cleared_rooms = {}
