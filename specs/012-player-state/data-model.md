# Data Model: Player State Snapshot

**Feature**: 012-player-state
**Date**: 2026-02-27

---

## PlayerState Class

**File**: `scripts/data_models/PlayerState.gd`
**Base class**: `RefCounted`
**Owner**: `RunManager` (sole writer)
**Consumers**: Any system reading the run snapshot (HUD, future save system)

### Fields

| Field | Type | Default | Live/Stub | Description |
|---|---|---|---|---|
| `current_hp` | `float` | `0.0` | **Live** | Player's current health. Synced via `StatsComponent.health_changed`. |
| `items` | `Array` | `[]` | Stub | Items acquired this run. Always empty in this feature. |
| `modifiers` | `Array` | `[]` | Stub | Active stat modifiers. Always empty in this feature. |
| `skill_changes` | `Array` | `[]` | Stub | Run-specific skill modifications. Always empty in this feature. |
| `skill_cooldowns` | `Dictionary` | `{}` | Stub | Per-skill cooldown state (`skill_id → float`). Always empty. |

### Class Definition

```gdscript
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
```

---

## RunState Extension

Add to `scripts/data_models/RunState.gd`:

```gdscript
## Player state snapshot for this run. Same reference as RunManager.player_state.
var player_state: PlayerState = PlayerState.new()
```

Initialized at declaration → safe defaults (current_hp = 0.0, stubs empty) before any run.

---

## RunManager Changes

### New Field

```gdscript
## Player state snapshot. Updated via health_changed signal; reset in end_run().
var player_state: PlayerState = PlayerState.new()
```

### start_run() — Setup

After existing reset code, add:

```gdscript
player_state = PlayerState.new()
run_state.player_state = player_state

var players: Array = get_tree().get_nodes_in_group("player")
for player: Node in players:
    var stats: StatsComponent = player.get_node_or_null("StatsComponent")
    if stats != null:
        if not stats.health_changed.is_connected(_on_player_health_changed):
            stats.health_changed.connect(_on_player_health_changed)
        player_state.current_hp = stats.current_health
```

Note: existing `stats.reset()` call (added in fix before this feature) fires `health_changed` → `_on_player_health_changed()` runs → `player_state.current_hp` is set to max_health automatically. The explicit `player_state.current_hp = stats.current_health` line before reset handles the window before reset fires.

### end_run() — Reset PlayerState

After existing `is_run_active = false`:

```gdscript
var players: Array = get_tree().get_nodes_in_group("player")
for player: Node in players:
    var stats: StatsComponent = player.get_node_or_null("StatsComponent")
    if stats != null:
        player_state = PlayerState.new()
        player_state.current_hp = stats.max_health
        run_state.player_state = player_state
        break
```

### New Method — _on_player_health_changed()

```gdscript
func _on_player_health_changed(new_health: float, _max_health: float) -> void:
    player_state.current_hp = new_health
```

---

## State Lifecycle

```
Before any run:
  player_state = PlayerState.new()          ← declared at RunManager init
  player_state.current_hp = 0.0            ← default (no player stats read yet)
  run_state.player_state = PlayerState.new() ← declared at RunState init

start_run(mode):
  player_state = PlayerState.new()
  run_state.player_state = player_state     ← shared reference
  Connect StatsComponent.health_changed → _on_player_health_changed (if not connected)
  player_state.current_hp = stats.current_health
  stats.reset() → health_changed fires → player_state.current_hp = stats.max_health

During run:
  StatsComponent.take_damage() → health_changed → player_state.current_hp updates
  StatsComponent.heal()        → health_changed → player_state.current_hp updates

end_run():
  player_state = PlayerState.new()           ← fresh instance (stubs empty)
  player_state.current_hp = stats.max_health ← full HP at reset
  run_state.player_state = player_state      ← RunState updated to new instance
  is_run_active = false

After run ends (before next start_run):
  run_state.player_state.current_hp == max_health  ← reset state readable
  run_state.player_state.items == []                ← empty stubs readable
```

---

## Stub Field Contract

All four stub fields (`items`, `modifiers`, `skill_changes`, `skill_cooldowns`) MUST:
- Be declared with the correct type and an empty default
- Never cause an error when read
- Reset to empty on each run end (guaranteed by `PlayerState.new()`)
- Not be populated or modified by anything in this feature
