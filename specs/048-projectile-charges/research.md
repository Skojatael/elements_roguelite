# Research: Magic Missile Charges (048)

## Q1 — Where should charge state live?

**Decision**: `SkillComponent.gd`

**Rationale**: `SkillComponent` already owns the entire skill activation flow (fire guard, projectile spawn). Adding charge count and max-charge fields here keeps skill logic cohesive. No new component is warranted (Constitution V — YAGNI); two integer fields and one reset call do not justify a new node or script.

**Alternatives considered**:
- New `ChargeComponent` — rejected: a single-skill resource counter does not constitute a new responsibility domain.
- `PlayerState` in RunManager — rejected: `PlayerState` is a read-only snapshot; mutable gameplay state belongs in components.

---

## Q2 — How does SkillComponent learn that a melee hit landed?

**Decision**: Add `signal melee_hit_landed` to `CombatComponent`; emit it in `_physics_process` immediately after `target.take_damage(dmg)`. `SkillComponent` connects to `_combat_component.melee_hit_landed` in `_ready()` (it already holds the `_combat_component` export reference).

**Rationale**: A direct component-to-component signal through the already-wired `_combat_component` export is the minimal wiring path. No autoload or global signal is needed. CombatComponent gains one new signal — a single, well-scoped reason to change (it now communicates successful hits to interested listeners), fully consistent with Constitution I.

**Alternatives considered**:
- Global signal via `GlobalSignals.melee_hit_landed` — rejected: this would couple unrelated systems to a combat event; reserve GlobalSignals for cross-domain events.
- `SkillComponent` reads `CombatComponent._attack_timer` directly — rejected: reads internal timer state across components; breaks encapsulation.

---

## Q3 — How does ExplorationHUD receive charge updates?

**Decision**: `SkillComponent` emits `signal charges_changed(current: int, maximum: int)`. `Main.gd` calls `_exploration_hud.setup_skill(skill: SkillComponent)` after the player is initialised (matching the existing `setup_hp_bar(stats: StatsComponent)` pattern). `ExplorationHUD.setup_skill` connects to `skill.charges_changed`.

**Rationale**: Mirrors the established HPBar/StatsComponent wiring pattern exactly. Main.gd is the appropriate orchestrator for cross-scene wiring (CanvasLayer HUD ↔ Player component). ExplorationHUD stays a passive display; it owns no charge logic.

**Alternatives considered**:
- ExplorationHUD reads `SkillComponent` via a `NodePath` export — rejected: introduces a cross-scene `get_node` dependency, violating Constitution IV.
- SkillComponent emits through `GlobalSignals` — rejected: charge state is not a domain event that warrants a global broadcast; the HPBar pattern is cleaner and already proven.

---

## Q4 — Where is max_charges stored?

**Decision**: Add `"max_charges": 3` to the `"magic_missile"` entry in `data/skills.json`. `SkillComponent._load_skill_data()` reads and caches it as `_max_charges: int`.

**Rationale**: Constitution II mandates all balance values live in JSON. The `skills.json` file is the natural home; `_load_skill_data()` already parses skill entries.

---

## Q5 — How is the skill renamed from `homing_projectile` to `magic_missile`?

**Decision**: In `data/skills.json`, rename the `"id"` field from `"homing_projectile"` to `"magic_missile"`. In `SkillComponent.gd`, update `SKILL_ID = "magic_missile"`. No other files reference `SKILL_ID` directly; `GlobalSignals.skill_button_pressed` is still used to trigger the skill.

**Rationale**: The rename is purely a data + constant change. `ResourceManager.get_skills()` returns the array; SkillComponent does a linear search by `id` — changing the constant is sufficient.

**Alternatives considered**:
- Keep `homing_projectile` internally and use `magic_missile` only as display name — rejected: the spec names the skill `magic_missile` in data and code; using two names would cause confusion.

---

## Q6 — How are charges reset on run start?

**Decision**: `SkillComponent` connects to `RunManager.run_started` in `_ready()` and sets `_current_charges = _max_charges` in the handler.

**Rationale**: Matches the existing pattern in `CombatComponent` (`RunManager.run_started.connect(func(_m: String) -> void: _recompute_stats())`). No new mechanism required.
