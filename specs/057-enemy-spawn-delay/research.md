# Research: Enemy Spawn Delay

## Decision: Delta countdown in `_physics_process` vs. Timer node

**Decision**: Delta countdown (inline float field)
**Rationale**: `_physics_process` already runs every frame for movement and contact damage. A `_spawn_delay: float` field decremented by `delta` adds no new lifecycle hooks and requires no scene changes. A `Timer` node would require adding a child node to every Enemy instance (editor work) and a signal connection — disproportionate for a one-shot delay.
**Alternatives considered**: `Timer` node child (rejected — requires scene edit and signal wiring for no benefit); `await get_tree().create_timer(t).timeout` (rejected — coroutine-based, harder to cancel if enemy dies during delay).

---

## Decision: Where to store delay value

**Decision**: `spawn_delay: 1.0` in `data/dungeon_config.json` under a top-level `"enemy_spawn"` block. Read in `Enemy._ready()` via `ResourceManager.get_dungeon_config()`.
**Rationale**: Constitution II prohibits numeric game parameters in `.gd` files. `dungeon_config.json` already owns enemy spawning parameters (wave config, spawn points) — this fits naturally. A single constant is simpler than a min/max range.
**Alternatives considered**: Named constant in `Enemy.gd` (rejected — Constitution II violation); per-type values in `enemies.json` (rejected — all enemy types share the same delay, unnecessary overhead).

---

## Decision: Guard placement in `_physics_process`

**Decision**: Single guard at the very top of `_physics_process` — decrement delay, return early if still positive
**Rationale**: Blocks both movement and contact damage ticks in one place. Burn damage is intentionally left unblocked (enemy can still burn during delay — burn is player-initiated, not enemy-initiated; no spec requirement to block it).
**Alternatives considered**: Separate guards per block (rejected — duplicates the countdown, violates Constitution VI nesting limit).
