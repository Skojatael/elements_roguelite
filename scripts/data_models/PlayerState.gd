class_name PlayerState
extends RefCounted

## Read-only for all systems except RunManager.

## Player's current health. Synced from StatsComponent.health_changed.
var current_hp: float = 0.0

## Stub: items acquired this run. Always empty until item system is implemented.
var items: Array = []

## Stub: active stat modifiers. Always empty until modifier system is implemented.
var modifiers: Array = []

## Stub: run-specific skill modifications. Always empty until skill-change system is implemented.
var skill_changes: Array = []

## Stub: per-skill cooldown state (skill_id → remaining_cooldown). Always empty until cooldown tracking is implemented.
var skill_cooldowns: Dictionary = {}
