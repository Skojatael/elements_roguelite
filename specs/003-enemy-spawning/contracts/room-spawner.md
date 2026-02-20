# Contract: RoomSpawner

**File**: `scenes/dungeon/RoomSpawner.gd`
**Attached to**: Child node named `RoomSpawner` inside each room scene
**Extends**: `Node`

---

## Exports (configured in editor per room)

```gdscript
@export var room_id: String = ""
```

- Must be set in the Godot Editor for each room instance.
- Value must match a key in `dungeon_config.json → spawn_configs` (or empty = no config, zero spawns).

---

## Signals

```gdscript
signal room_cleared
```

- Emitted once, the same frame the last living enemy is defeated.
- Consumers: HUD (door unlock visual, future), RunManager (already called internally before emit).

---

## Public API

```gdscript
# No public methods — all behaviour is driven by child Area2D signals.
# External code should connect to room_cleared signal only.
```

---

## Dependencies (inbound)

| Dependency | How resolved |
|------------|-------------|
| `dungeon_config.json` | Loaded via `ResourceManager` (autoload) |
| `Enemy.tscn` | Preloaded as constant at script top |
| `RunManager` (autoload) | Accessed via `RunManager.is_room_cleared()` / `mark_room_cleared()` |

---

## Internal signal wiring (wired in `_ready`)

| Signal source | Signal | Handler |
|--------------|--------|---------|
| `$EntryArea` (Area2D child) | `body_entered(body)` | `_on_player_entered(body)` |
| Each spawned `Enemy` instance | `defeated` | `_on_enemy_defeated()` |

---

## Behaviour contract

1. On `_ready()`: load spawn config for `room_id` from `dungeon_config.json`. Validate enemy count ≤ 10 and all `enemy_id` values exist in `enemies.json`. Push error and skip spawn if invalid.
2. On `EntryArea.body_entered`: if body is player AND room not cleared (checked via `RunManager`) → spawn all enemies from config simultaneously.
3. Each enemy is instantiated from `Enemy.tscn`, `enemy_type_id` set before `add_child`, added as child of the room's parent node (not `RoomSpawner`).
4. Each enemy's `defeated` signal is connected to `_on_enemy_defeated()`.
5. On `_on_enemy_defeated()`: decrement `_living_count`. If `_living_count == 0` → call `RunManager.mark_room_cleared(room_id)` → emit `room_cleared`.
6. If room already cleared on entry: no enemies spawned, no signals emitted.
