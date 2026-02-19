# Research: Enemy Combat System

**Feature**: `002-enemy-combat`
**Date**: 2026-02-19

---

## Decision 1: Enemy Scene Architecture

**Decision**: Single `Enemy.gd` script co-located with `Enemy.tscn`. No enemy-specific component hierarchy.

**Rationale**: The constitution's component mandate (Principle I) is explicit to the Player: "Player behavior MUST be composed from the discrete child components." For enemies, Principle V (YAGNI) applies: "An abstraction MUST NOT be introduced until at least two concrete call sites require it." A single script handling health, pursuit state, movement, and contact damage does not violate SRP because all these concerns belong to one game-logic category (enemy entity behaviour) — the prohibited mix is data-parsing + game-logic + UI-presentation in the same script, not multiple game-logic responsibilities for a single entity. When a second enemy type needs genuinely different logic (e.g., a boss with phase transitions), a component split or subclass is justified.

**Alternatives considered**:
- Enemy component hierarchy mirroring the player (EnemyHealthComponent, EnemyMovementComponent, EnemyCombatComponent) — rejected; no second concrete call site exists yet; would be a YAGNI violation and add unnecessary complexity at this stage.
- Shared HealthComponent used by both player and enemies — rejected; player already has `StatsComponent` for health; introducing a shared component before both call sites are implemented is premature abstraction.

---

## Decision 2: Player Attack Mechanism

**Decision**: `CombatComponent.gd` (player child node) implements a simple auto-attack: using an `Area2D` detection zone, it deals a fixed `attack_damage` to one overlapping enemy at a fixed `attack_interval` in `_physics_process`. The player does not need to perform any explicit attack action in this feature.

**Rationale**: The spec defines the player's ability to damage enemies as a requirement but does not specify the interaction model (tap, collision, auto-attack). Auto-attack is the simplest possible implementation that satisfies all four user stories. It keeps CombatComponent self-contained (no cross-scene calls) and can be replaced by a skill-based attack system in a future feature without changing the enemy-side API. The `take_damage(amount)` contract on Enemy is the only coupling point.

**Alternatives considered**:
- Tap-to-attack — requires UI gesture recognition and hit-testing against world-space enemy positions; out of scope for this feature.
- Contact damage (player body → enemy body, symmetric to enemy→player contact damage) — makes it hard to control damage rate without a cooldown on both sides; less intuitive than a dedicated attack interval.

---

## Decision 3: Contact Damage Detection

**Decision**: Two `Area2D` nodes per enemy, both as children of `Enemy.tscn`:
1. **DetectionArea** (large radius, e.g., `detection_range` from data) — `body_entered`/`body_exited` signals toggle pursuit state.
2. **ContactArea** (small radius, matches enemy body size) — `body_entered`/`body_exited` signals start/stop contact damage timer.

Damage is applied on a timer driven by `damage_cooldown`, not every frame.

**Rationale**: Area2D signals are event-driven — no per-frame O(n) distance calculation for each enemy. With 10+ enemies each polling distance every frame, this becomes O(n×frames) work; signals fire only on state change. This is the idiomatic Godot pattern for trigger zones and is well-supported under Jolt physics. Two separate Areas let detection range and contact zone be tuned independently.

**Alternatives considered**:
- `_physics_process` distance polling — rejected; O(n) per frame per enemy; worse mobile performance; scales poorly.
- Single Area2D for both detection and contact — rejected; detection range and contact zone are different radii and independent states; merging them requires distance sub-checks inside the callback, losing the clarity benefit.

---

## Decision 4: Run-End State Signalling

**Decision**: `StatsComponent` emits a local `died` signal when `current_health` reaches zero. `Main.gd` connects this signal and calls `GlobalSignals.gameplay_ended.emit()`. `GlobalSignals` gains no new signal for this feature.

**Rationale**: `StatsComponent` owns the player health domain — it is the correct origin of a health-depletion event. `GlobalSignals.gameplay_ended` already exists and is the canonical "gameplay is over" signal consumed by ExplorationHUD. Routing through `Main.gd` (already the coordinator) keeps cross-scene coupling minimal: StatsComponent knows nothing about game state; Main.gd wires the translation. Adding a `player_died` signal to GlobalSignals would be premature — `gameplay_ended` already semantically covers the run-end case for all current consumers.

**Alternatives considered**:
- `StatsComponent` directly emits `GlobalSignals.gameplay_ended` — rejected; violates SRP (StatsComponent would need awareness of game-state management); couples a health component to top-level orchestration.
- New `GlobalSignals.player_died` signal — rejected; no existing consumer needs to distinguish player-death from other gameplay-end causes at this stage; YAGNI.

---

## Decision 5: JSON Data Schema

**Decision**: `data/enemies.json` stores an array of enemy type objects. `EnemyData.gd` provides a typed GDScript wrapper loaded at runtime. The JSON field set matches the entity fields required by FR-009.

**Schema**:
```json
{
  "enemies": [
    {
      "id": "slime",
      "display_name": "Slime",
      "max_health": 3.0,
      "damage": 1.0,
      "move_speed": 60.0,
      "detection_range": 200.0,
      "damage_cooldown": 0.5
    }
  ]
}
```

**Rationale**: Flat object per enemy type, keyed under `"enemies"` array. Each field maps 1:1 to `EnemyData` properties; no nested structures are needed. The `id` field is a machine-readable key for scene/resource lookups; `display_name` is human-readable for future UI. All numeric stats are `float` to avoid int/float conversion issues in GDScript.

**Alternatives considered**:
- Dictionary keyed by id (e.g., `{"slime": {...}}`) — rejected; arrays are more natural to iterate and GDScript's `JSON.parse_string` returns them directly; id duplication in the object is minimal overhead.
- Separate JSON file per enemy type — rejected; unnecessary filesystem overhead for a small number of types; all enemies load at the same time anyway.

---

## Codebase State Summary

All relevant files are empty stubs — fully greenfield:
- `scripts/data_models/EnemyData.gd` — stub (`extends Node`, empty)
- `data/enemies.json` — `{}`
- `scenes/player/components/StatsComponent.gd` — stub
- `scenes/player/components/CombatComponent.gd` — stub
- `scenes/combat/` — empty (placeholder `.gitkeep` files only)

Enemy scenes will be created under `scenes/combat/enemies/`.
