# Research: Door Lock During Combat

## Decision: How to lock doors

**Decision**: Add `var locked: bool = false` to `Door.gd`. In `_on_body_entered`, add `if locked: return` before emitting `door_activated`. Toggle via a public setter or direct field assignment from `RoomSpawner`.
**Rationale**: `Door` is an `Area2D` trigger — its only effect is emitting `door_activated`. Suppressing that signal is the complete lock. Room walls already provide physical containment; no `StaticBody2D` is needed.
**Alternatives considered**: `monitoring = false` on the Area2D (rejected — suppresses all body_entered callbacks, cleaner to keep monitoring active and guard in the handler); adding a `StaticBody2D` blocker child (rejected — requires `.tscn` edit and is redundant given the room boundary walls).

---

## Decision: Who controls the lock

**Decision**: `RoomSpawner` locks all sibling `Door` nodes immediately before spawning enemies (in `_spawn_wave` for wave rooms, in `_spawn_enemies_legacy` for flat rooms) and unlocks them in `_on_enemy_defeated` when `room_cleared` fires.
**Rationale**: `RoomSpawner` already owns the full spawn/clear lifecycle and is the only system that knows when enemies are active. Connecting door locking to spawner events keeps the logic co-located with spawn state.
**Alternatives considered**: `Door` polling `RunManager.is_room_cleared` each frame (rejected — per-frame cost, couples Door to RunManager); signal from RoomSpawner to Room scene which propagates to doors (rejected — extra indirection for no benefit).

---

## Decision: How RoomSpawner finds Door nodes

**Decision**: `get_parent().get_children()` filtered by `is Door` (using the `Door` class_name). Identical to the pattern already used in `Main._on_boss_teleport_pressed()` for door suppression.
**Rationale**: Consistent with existing project pattern. No new node references or exports needed. Door count per room is always ≤ 4 so the loop is trivially cheap.
**Alternatives considered**: `@export var doors: Array[Door]` on RoomSpawner (rejected — requires Inspector wiring on every room scene, Editor-Centric overhead for a runtime-discoverable relationship).

---

## Decision: When exactly to lock

**Decision**: Lock immediately before the first enemy is added to the scene tree — at the start of `_spawn_wave(0)` for wave rooms and at the start of `_spawn_enemies_legacy()` for flat rooms. Unlock in the `room_cleared` branch of `_on_enemy_defeated`.
**Rationale**: Locking before `add_child` ensures doors are blocked the same frame enemies appear. Unlocking on `room_cleared` (not on "last kill") reuses the already-correct clear detection logic in RoomSpawner.
**Alternatives considered**: Locking in `_on_player_entered` (rejected — player enters before spawn is deferred, causing a one-frame window where doors are locked but no enemies exist yet in rooms with no spawn config).
