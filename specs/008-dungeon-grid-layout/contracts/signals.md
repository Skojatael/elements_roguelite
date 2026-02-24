# Signal Contracts: Dungeon Grid Layout (008)

**Date**: 2026-02-24
**Feature**: [spec.md](../spec.md)

---

## Generator Output Interface

After each successful `_generate()` call, `DungeonGenerator` exposes the dungeon layout through three public properties. Any system that needs the layout reads these directly from the `DungeonGenerator` node.

| Property | Type | Description |
|---|---|---|
| `rooms_by_id` | `Dictionary` | `room_id → { room_type_id, grid_pos, world_pos }` for all 8 rooms |
| `neighbours_by_id` | `Dictionary` | `room_id → Array[String]` of adjacent room_ids in this layout |
| `start_room_id` | `String` | Center room ID — always `"room_2_2"` |

All three properties are cleared and repopulated atomically at the start of each `run_started` handler. Consumers MUST NOT read them before `run_started` has fired at least once.

---

## Consumed Signal

### `RunManager.run_started(mode: String)`

| Property | Value |
|---|---|
| Emitter | `autoload/RunManager.gd` |
| Consumer | `scenes/dungeon/DungeonGenerator.gd` |
| Connected in | `DungeonGenerator._ready()` |
| Handler | `DungeonGenerator._on_run_started(mode)` |
| Effect | Clears previous layout data, runs frontier expansion, populates output properties, places player |

**Contract**: `_on_run_started` is idempotent across repeated runs — each call produces exactly `TARGET_ROOM_COUNT` rooms in `rooms_by_id` (assuming valid config), regardless of how many times the signal fires.

---

## No New Signals

This feature introduces no new signals. The layout output is pull-based (property read) rather than push-based. A future feature may add a `dungeon_layout_ready` signal if a listener needs notification; that is out of scope here.

---

## Downstream Signals (scene-loading system — separate concern)

The following signals are produced by `RoomSpawner` nodes that the **scene-loading system** (not `DungeonGenerator`) will create by reading `rooms_by_id`. `DungeonGenerator` does not emit or connect to these.

| Signal | Emitter | Payload | Description |
|---|---|---|---|
| `room_entered(room_id)` | `RoomSpawner` | `String` | Player entered the room's EntryArea |
| `room_cleared(room_id)` | `RoomSpawner` | `String` | All enemies in the room are defeated |

`RunManager` connects to both via `register_room(spawner)` — this path is unchanged and belongs to the scene-loading system.

---

## Config Contract

`DungeonGenerator._generate()` reads `dungeon_config.json` through `ResourceManager.get_dungeon_config()` and expects:

```json
{
  "combat_room_pool": ["CombatRoom01", "CombatRoom02"]
}
```

| Key | Required | Type | Failure mode |
|---|---|---|---|
| `combat_room_pool` | Yes | `Array[String]` | `push_error`, halt; all output properties left empty |

Each entry is a type ID referenced by the scene-loading system when it later instantiates the room. The generator does **not** validate whether a `.tres` asset exists for each entry — that validation is the responsibility of the scene-loading system at load time.
