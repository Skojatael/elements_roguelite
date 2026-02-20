extends Node

## Tracks which rooms have been cleared during the current run.
## Reset to {} when a new run begins.
var cleared_rooms: Dictionary = {}


func _ready() -> void:
	pass


## Marks a room as cleared for the current run.
func mark_room_cleared(room_id: String) -> void:
	cleared_rooms[room_id] = true


## Returns true if the room was already cleared during this run.
func is_room_cleared(room_id: String) -> bool:
	return cleared_rooms.has(room_id)


## Call this when starting a new run to reset all cleared state.
func start_new_run() -> void:
	cleared_rooms = {}
