# Research: Essence Currency

**Feature**: 014-essence-currency
**Date**: 2026-02-28

---

## Decision 1: Where to calculate and award essence per kill

**Decision**: RoomSpawner calculates and awards essence in `_on_enemy_defeated()`.

**Rationale**: RoomSpawner is already the kill-tracking hub — it connects to every
enemy's `defeated` signal and decrements `_living_count`. It also has a natural
home for `depth` (mirrors `difficulty_mult` which RoomLoader already sets on it).
Moving the calculation elsewhere would fragment the kill-response logic.

**Alternatives considered**:
- Enemy.gd: Enemy would need to know its own depth and call RunManager directly —
  couples a content node to run-session logic.
- RunManager: Would need a new signal or callback chain through multiple layers —
  over-engineering for what is a simple per-kill calculation.

---

## Decision 2: How to pass enemy identity (base_essence) to the defeated callback

**Decision**: Bind `enemy.get_base_essence()` as a parameter at connection time using
Godot's callable bind pattern:
`enemy.defeated.connect(_on_enemy_defeated.bind(enemy.get_base_essence()))`

**Rationale**: The enemy's `_data` is fully populated after `add_child()` returns
(it's initialised in `_ready()`). Binding the value once at spawn time avoids a
second JSON lookup and keeps `_on_enemy_defeated` signature clean:
`_on_enemy_defeated(base_essence: float)`.

**Alternatives considered**:
- Bind enemy_id and look up in ResourceManager on each kill — an extra map lookup
  per kill; unnecessary when the value is already loaded.
- `defeated(enemy_id: String)` signal change — would require modifying Enemy's
  signal signature and all existing connections (RoomSpawner is the only listener,
  but the bind pattern is simpler and keeps Enemy's signal generic).

---

## Decision 3: How RoomSpawner receives the room's depth

**Decision**: Add `@export var depth: int = 0` to RoomSpawner; RoomLoader sets it
immediately after `spawn_room()` returns, alongside the existing `difficulty_mult`
assignment.

**Rationale**: RoomLoader already has the depth value (`rooms_by_id[room_id]["depth"]`)
and already sets `spawner.difficulty_mult` the same way. This is a one-liner addition
that follows the exact same pattern with zero new infrastructure.

**Alternatives considered**:
- RoomSpawner reads depth from DungeonGenerator directly — would require a reference
  to DungeonGenerator inside RoomSpawner (cross-scene coupling).
- Pass depth through SpawnContext — SpawnContext is a data bundle for position/parent;
  depth is a spawner property not a spawn-time argument.

---

## Decision 4: When to floor the essence value

**Decision**: Floor per kill using `floori()`. Cash-out for DIED is then
`floori(run_currency * 0.85)`. Cash-out for CASH_OUT is `floori(run_currency)` (already
whole numbers, but floori is defensive).

**Rationale**: The spec defines the formula as `floor(base_essence × depth_multiplier)`
per kill. Flooring per kill means `run_currency` accumulates whole numbers, making the
CASH_OUT path trivially correct. The DIED path requires one additional floor on the
discounted total.

**Alternatives considered**:
- Accumulate raw floats and floor only at cash-out — the spec explicitly floors per
  kill, so this would diverge from specified behaviour.

---

## Decision 5: EnemyData.from_dict() — graceful handling of missing base_essence

**Decision**: Use `.get("base_essence", 0.0)` instead of `assert(data.has(...))`.
Missing `base_essence` awards 0 essence for that kill — no crash (FR-008).

**Rationale**: All existing fields use hard asserts because they are structurally
required for combat. `base_essence` is new and optional in this iteration; a missing
value silently awards nothing rather than crashing the game.

**Alternatives considered**:
- Hard assert — would break on any enemy config that hasn't been updated yet;
  too brittle for an optional field.
