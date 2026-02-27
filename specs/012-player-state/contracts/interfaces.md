# Interface Contracts: Player State Snapshot

**Feature**: 012-player-state
**Date**: 2026-02-27

---

## 1. RunState.player_state Property

**Owner**: `RunState` (declares field); `RunManager` (sets reference)
**Consumed by**: Any system reading the run snapshot
**Type**: `PlayerState`

### Contract

```gdscript
var player_state: PlayerState
```

- MUST be non-null at all times (initialized to `PlayerState.new()` at RunState declaration).
- MUST reflect the same instance as `RunManager.player_state` during an active run.
- Read-only for all systems other than RunManager.

### Access Pattern (consumers)

```gdscript
# Correct — read only via RunState:
var hp: float = RunManager.run_state.player_state.current_hp
var inv: Array = RunManager.run_state.player_state.items

# WRONG — never write from consumer:
RunManager.run_state.player_state.current_hp = 5.0  # prohibited
```

---

## 2. PlayerState Field Invariants

### current_hp: float

| State | Value |
|---|---|
| Before any run (declaration) | `0.0` |
| After `start_run()` | Player's `max_health` (after `stats.reset()` fires) |
| After `take_damage()` | Reduced by damage amount (floor 0.0) |
| After `heal()` | Increased by heal amount (ceiling `max_health`) |
| After `end_run()` | Player's `max_health` (reset) |

### items: Array

- Always `[]` in this feature. MUST NOT contain entries. MUST NOT cause error on read.

### modifiers: Array

- Always `[]` in this feature. MUST NOT contain entries. MUST NOT cause error on read.

### skill_changes: Array

- Always `[]` in this feature. MUST NOT contain entries. MUST NOT cause error on read.

### skill_cooldowns: Dictionary

- Always `{}` in this feature. MUST NOT contain entries. MUST NOT cause error on read.
- When populated by future feature: keyed by skill ID string, value is remaining cooldown float.

---

## 3. RunManager Write Points

Only these locations in RunManager may write to PlayerState:

| Method | Action |
|---|---|
| Declaration (init) | `player_state = PlayerState.new()` |
| `start_run()` | New instance; `run_state.player_state = player_state`; connect signal; set initial `current_hp` |
| `_on_player_health_changed()` | `player_state.current_hp = new_health` |
| `end_run()` | New reset instance; `player_state.current_hp = max_health`; `run_state.player_state = player_state` |

---

## 4. StatsComponent.health_changed — Consumed Signal

**Source**: `scenes/player/components/StatsComponent.gd`
**Signal**: `health_changed(new_health: float, max_health: float)`
**Consumer**: `RunManager._on_player_health_changed()`

### Connection Contract

- Connected in `start_run()` with `is_connected()` guard — prevents duplicate connections across repeated runs.
- Never disconnected — the player node is permanent; the signal is always relevant when a run is active.
- `_on_player_health_changed()` writes `player_state.current_hp = new_health` only. Does not read `max_health` argument.
