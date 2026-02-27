class_name RunState
extends RefCounted

## Read-only for all systems except RunManager.

## ID of the room the player is currently in. Empty string when no room is loaded.
var current_room_id: String = ""

## Set of cleared room IDs this run. Same reference as RunManager.cleared_rooms.
var cleared_rooms: Dictionary = {}

## Total currency accumulated this run.
var run_currency: float = 0.0

## Run mode: "endless" or "boss". Set at run start; does not change.
var run_mode: String = ""

## Stub: deepest room reached (in depth steps from start). Always 0 until feature 010 populates it.
var max_depth_reached: int = 0

## Stub: run seed for deterministic dungeon generation. Always 0 until seeded-generation feature.
var seed: int = 0

## Player state snapshot for this run. Same reference as RunManager.player_state.
var player_state: PlayerState = PlayerState.new()
