# Data Model: Magic Missile Charges (048)

## JSON Schema — `data/skills.json`

Rename the existing `homing_projectile` entry to `magic_missile` and add `max_charges`.

```json
{
  "skills": [
    {
      "id": "magic_missile",
      "speed": 600.0,
      "max_distance": 2200.0,
      "max_charges": 3
    }
  ]
}
```

| Field | Type | Description |
|---|---|---|
| `id` | String | Skill identifier (renamed from `homing_projectile`) |
| `speed` | float | Projectile travel speed (unchanged) |
| `max_distance` | float | Max travel distance before despawn (unchanged) |
| `max_charges` | int | Base maximum charge pool; data-driven for future upgrade path |

---

## In-Memory State — `SkillComponent`

Charge state lives entirely inside `SkillComponent` for the duration of a run.

| Field | Type | Initial value | Description |
|---|---|---|---|
| `_max_charges` | `int` | Loaded from `skills.json` | Maximum charge pool (base 3) |
| `_current_charges` | `int` | `_max_charges` | Charges currently available |

**Invariants**:
- `0 <= _current_charges <= _max_charges` always
- `_max_charges > 0` (asserted in `_load_skill_data`)
- Reset to `_max_charges` on every `RunManager.run_started`

---

## Signal Contracts

### `SkillComponent.charges_changed(current: int, maximum: int)`

Emitted whenever `_current_charges` changes (spend or restore). Always emitted with both current and max so consumers can render a fill ratio without storing max separately.

Consumers:
- `ExplorationHUD` — updates charge display

### `CombatComponent.melee_hit_landed` (new, no arguments)

Emitted immediately after `target.take_damage(dmg)` in `_physics_process`, once per attack cycle where at least one valid enemy is in the attack area.

Consumers:
- `SkillComponent` — restores 1 charge (capped at `_max_charges`)

---

## State Transitions

```
Run starts
  └─→ _current_charges = _max_charges
        └─→ charges_changed(max, max)

Skill button pressed
  ├─ [_current_charges == 0] → blocked, no emission
  └─ [_current_charges > 0]  → _current_charges -= 1
                                └─→ charges_changed(current, max)

Melee hit lands (CombatComponent.melee_hit_landed)
  ├─ [_current_charges == _max_charges] → no-op, no emission
  └─ [_current_charges < _max_charges]  → _current_charges += 1
                                          └─→ charges_changed(current, max)
```

---

## HUD Display Contract

`ExplorationHUD.setup_skill(skill: SkillComponent)` — called once by `Main.gd` after player is initialised (matching `setup_hp_bar` pattern). Connects `skill.charges_changed` to the internal update handler. Disconnects automatically when the node is freed.

Display: a `Label` showing `"{current}/{max}"` format, adjacent to the skill button. Updated synchronously on every `charges_changed` emission. Exported as `@export var _charge_label: Label` (Inspector-assigned).
