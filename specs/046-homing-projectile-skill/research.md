# Research: Homing Projectile Skill (046)

## Findings

### 1. Enemy Discovery

**Decision**: Find living enemies by iterating `RunManager.current_room.get_parent().get_children()` and filtering for `is Enemy`.

**Rationale**: Enemies are added as children of the room root node by `RoomSpawner._spawn_enemies()`. `RunManager.current_room` is the `RoomSpawner` node; its parent is the room scene root. There is no registry of living enemies beyond this node hierarchy. Using `get_children()` with an `is Enemy` type check is the simplest, most direct approach that matches existing patterns in the codebase (CombatComponent uses `is Enemy` checks already).

**Alternatives considered**:
- RoomSpawner exposes a `get_living_enemies() -> Array[Enemy]` method — would be cleaner but violates YAGNI; adds API surface to a class that only SkillComponent would use.
- Maintain a static registry — over-engineered; enemies already track their own lifecycle via `defeated` signal.

---

### 2. Signal Route: HUD → SkillComponent

**Decision**: Add `skill_button_pressed` signal to `GlobalSignals`. ExplorationHUD emits it; SkillComponent connects to it.

**Rationale**: ExplorationHUD is a CanvasLayer (not an autoload). SkillComponent is a player component deep in the scene tree. They cannot connect directly without one knowing the other's path. GlobalSignals already serves as the shared signal bus for exactly this kind of cross-scene, cross-hierarchy event. No new autoload is needed.

**Alternatives considered**:
- ExplorationHUD emits its own signal → Main.gd connects and relays to Player → SkillComponent. Requires Main to hold a reference to the player's SkillComponent, coupling Main to player internals.
- SkillComponent polls in `_process` for button input — bypasses the established HUD pattern entirely; input should be driven by the UI button, not a per-frame poll.

---

### 3. Projectile Scene Parenting

**Decision**: Projectile is added as a child of `RunManager.current_room.get_parent()` (the active room node).

**Rationale**: Enemies live in the room node. When `RoomLoader` calls `queue_free()` on the room during transitions or at run end, all room children — including in-flight projectiles — are freed automatically. This satisfies SC-005 (no orphaned projectiles) with zero extra cleanup code.

**Alternatives considered**:
- Projectile added to scene root / Main — requires explicit cleanup on room transition and run end; additional signals or calls needed.
- Projectile added to Player node — visually and logically wrong; projectile is a world-space object, not a player child.

---

### 4. Homing Behavior

**Decision**: Target is selected once at fire time (closest living enemy at that moment). Projectile steers toward the selected target's current `global_position` every `_physics_process` frame. If target dies (`not is_instance_valid(_target)`) projectile calls `queue_free()`.

**Rationale**: FR-004 requires "steer continuously… updating its direction." The target is the one selected at fire time (FR-003). Continuous steering means the direction vector is recalculated each frame against the same target's position (enemies move, so this makes projectile visually curve). If target is freed, `is_instance_valid` returns false and the projectile self-destructs (FR-007).

**Alternatives considered**:
- Lock heading at fire time (straight line) — does not satisfy FR-004's "updating direction" requirement.
- Re-target to next closest enemy on target death — spec explicitly states projectile disappears when target dies; re-targeting is out of scope.

---

### 5. Damage Value

**Decision**: Read `CombatComponent.attack_damage` at fire time. Pass `floori(attack_damage * 0.5)` as the damage to the projectile.

**Rationale**: `CombatComponent.attack_damage` is the computed, fully-multiplied attack damage (includes MetaManager meta-progression and RelicManager relic bonuses). SC-004 requires 50% of player's attack damage. Flooring is consistent with the game's existing rounding convention (`floori`).

**Alternatives considered**:
- Pass `_base_attack_damage` instead — ignores relic/meta multipliers; inconsistent with how the game defines "player's damage."
- Compute independently in SkillComponent — would duplicate MetaManager/RelicManager logic; CombatComponent already owns the computed value.

---

### 6. Balance Data

**Decision**: Add `"homing_projectile"` entry to `data/skills.json`. Fields: `speed: 600.0`, `max_distance: 2200.0`. Read via `ResourceManager` (new `get_skill_data(id)` method or reuse `get_skills()` cache).

**Rationale**: Constitution II prohibits hardcoded numeric constants. `data/skills.json` is the designated home for skill configuration. `ResourceManager` already caches JSON reads; adding one delegating method stays within its existing responsibility.

Values:
- **speed = 600 px/s**: Rooms are ~1920×1080 px of playable area. At 600 px/s a projectile crosses a room in ~1.6 s — well within SC-001's 3-second target.
- **max_distance = 2200 px**: Room diagonal ≈ `sqrt(1920² + 1080²) ≈ 2204`. Ensures a cross-room shot always expires cleanly.

---

### 7. Projectile Visual

**Decision**: `ColorRect` (small square, e.g. 16×16 px, bright yellow) as the initial visual, centered on the `Node2D` root.

**Rationale**: Spec assumption states "simple visual (colored shape) with no art assets required." `ColorRect` requires no texture imports, no atlas, and renders on the Mobile renderer profile without issues.

---

### 8. Hit Detection

**Decision**: `Area2D` on Projectile with `body_entered` signal, checking `if body is Enemy`.

**Rationale**: Existing pattern throughout the codebase. Enemies are `CharacterBody2D` nodes — they register as bodies, not areas. `body_entered` fires when the projectile's `Area2D` overlaps an enemy's `CharacterBody2D`. Guard: `if not body is Enemy: return`. On hit: call `body.take_damage(_damage)`, then `queue_free()`.
