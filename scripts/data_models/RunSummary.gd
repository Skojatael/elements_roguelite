class_name RunSummary
extends RefCounted

var essence_cashed_out: int
var enemies_slain: int
var rooms_cleared: int
var end_reason: RunManager.EndReason


static func create(essence: int, enemies: int, rooms: int, reason: RunManager.EndReason) -> RunSummary:
	var s := RunSummary.new()
	s.essence_cashed_out = essence
	s.enemies_slain = enemies
	s.rooms_cleared = rooms
	s.end_reason = reason
	return s
