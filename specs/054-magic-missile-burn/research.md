# Research: 054-magic-missile-burn

## Burn Processing Location

**Decision**: Burn is processed inside `Enemy._physics_process(delta)`. Enemy owns a `var _burn: BurnEffect = null` field; each frame, if `_burn != null and _burn.is_active()`, it calls `_burn.process(delta)` and forwards any returned damage to `_stats.take_damage()`.

**Rationale**: Enemy already has `_physics_process` for contact-damage timing. Adding burn there is additive with no new Node, no new signal — same per-frame tick pattern already present. Enemy owning its own burn state is the minimal-coupling design.

**Alternative rejected**: A separate `BurnProcessor` child node on each Enemy. Rejected — adds scene complexity for a single use case (YAGNI, Principle V).

---

## Kill Credit from Burn Ticks

**Decision**: No special handling needed. Burn ticks call `enemy.take_damage(amount)` which delegates to `StatsComponent.take_damage()`. When HP reaches 0, `StatsComponent.died` fires, which triggers `Enemy._on_died()`, which emits `Enemy.defeated`, which flows through `RoomSpawner._on_enemy_defeated()` to `RunManager._on_enemy_defeated()` — incrementing `enemies_slain` and awarding essence exactly as a direct hit.

**Rationale**: The entire kill-credit chain is signal-driven from `StatsComponent.died`. The damage source (projectile vs. burn tick) is irrelevant — any `take_damage()` call that reaches 0 HP produces the same kill credit. No additional wiring needed.

---

## BurnEffect — Pure RefCounted

**Decision**: `BurnEffect` lives at `scripts/data_models/BurnEffect.gd` as a `class_name BurnEffect extends RefCounted`. No autoload calls, no Node dependencies, no signal emissions. All logic is pure input/output through `process(delta) -> float`.

**Rationale**: Constitution II requires data-driven balance; putting the timing math in a pure script keeps it independently testable (FR-010). `scripts/data_models/` is the correct home for typed state containers — `RunState`, `PlayerState`, `RelicData` all live there.

**Interface:**
```
apply(tick_damage: float, duration: float) → void
extend(seconds: float) → void
process(delta: float) → float   # returns tick_damage if a tick fired, else 0.0
is_active() → bool
```

---

## Enemy API for Burn Application

**Decision**: Single public method `on_burn_hit(tick_damage: float, base_duration: float, extend_seconds: float) -> void` on Enemy. Internally: if `_burn != null and _burn.is_active()` → call `_burn.extend(extend_seconds)`; else → create fresh `BurnEffect.new()` and call `apply(tick_damage, base_duration)`.

**Rationale**: The "apply or extend" decision belongs to Enemy, not to the caller. Projectile just passes parameters; Enemy decides the right state transition. This keeps FR-007 (extend vs. reset) as a single authoritative path.

---

## Burn on Chain Target (Feature 053 Interaction)

**Decision**: `Projectile._on_body_entered()` calls `on_burn_hit()` on the **primary target** only. The chain target (`_try_chain()`) also receives `on_burn_hit()` using the **primary** `_damage` value (not the reduced chain damage) so both targets get the same burn intensity.

**Rationale**: The spec assumption states this interaction emerges naturally. Using primary `_damage` for the chain burn is simpler and consistent — burn intensity reflects the player's attack power, not the chain reduction. The chain target's burn is identical to the primary's burn.

**Alternative rejected**: Using `_damage * _chain_damage_mult` for chain burn. Rejected for simplicity; the distinction is not specified and adds complexity for negligible gameplay impact.

---

## Projectile Setup Signature Extension

**Decision**: `Projectile.setup()` gains three new parameters: `burn_damage_per_tick: float`, `burn_duration: float`, `burn_extend_seconds: float`. All defaulted in the signature to `0.0` is NOT done — callers always provide them. `SkillComponent` reads these values from `data/skills.json` in `_load_skill_data()`.

**Rationale**: Matches the existing pattern for `chain_damage_mult` (feature 053). Pre-computed at fire time, passed to projectile, applied at hit time.

---

## Burn Relic Query Pattern

**Decision**: `RelicManagerImpl.has_burn_relic() -> bool` using `active_relic_ids.has("burn")`. Exposed via `RelicManager.has_burn_relic()` thin wrapper.

**Rationale**: Identical to `has_chain_relic()` from feature 053. Consistent with the conditional-relic pattern for `effect_stat: ""` relics.

---

## Resolved Unknowns

| Unknown | Resolution |
|---------|-----------|
| Where does burn tick? | `Enemy._physics_process(delta)` |
| Does burn tick kill credit work automatically? | Yes — `take_damage()` triggers the full death signal chain |
| Where does BurnEffect live? | `scripts/data_models/BurnEffect.gd` (pure RefCounted) |
| Does chain target also get burn? | Yes — `_try_chain()` also calls `on_burn_hit()` on chain target using primary damage |
| First tick fires at? | t=1s after application (first second fully elapsed, not on impact) |
