# Data Model: Homing Projectile Skill (046)

## Entities

### Projectile (runtime, scene-based)

**Scene**: `scenes/combat/projectiles/Projectile.tscn`
**Script**: `scenes/combat/projectiles/Projectile.gd` (`class_name Projectile extends Node2D`)

| Field | Type | Set by | Description |
|-------|------|--------|-------------|
| `_target` | `Enemy` | `setup()` | The enemy this projectile homes toward. |
| `_damage` | `float` | `setup()` | Damage to deal on impact. |
| `_speed` | `float` | `setup()` | Movement speed in pixels/second. |
| `_max_distance` | `float` | `setup()` | Maximum travel distance before self-destruction. |
| `_distance_traveled` | `float` | Internal | Accumulated distance since spawn. |

**Setup method**: `func setup(target: Enemy, damage: float, speed: float, max_distance: float) -> void`

**State transitions**:
- Spawned → Homing (moves each `_physics_process` frame)
- Homing → Destroyed: target dies (`not is_instance_valid(_target)`) OR max distance exceeded OR hit registered

**Child nodes**:
- `Area2D` (`_hit_area`) — collision detection
  - `CollisionShape2D` — small circle or rect shape
- `ColorRect` — visual (16×16 px, bright yellow)

---

### SkillComponent (player component, runtime)

**Script**: `scenes/player/components/SkillComponent.gd` (`class_name SkillComponent extends Node`)

| Field | Type | Set by | Description |
|-------|------|--------|-------------|
| `_combat_component` | `CombatComponent` | `@export` (Inspector) | Source of `attack_damage`. |
| `_skill_speed` | `float` | `_ready()` from JSON | Projectile speed; loaded once from `skills.json`. |
| `_skill_max_distance` | `float` | `_ready()` from JSON | Max travel distance; loaded once from `skills.json`. |

**Methods**:
- `_on_skill_button_pressed() -> void` — finds closest enemy, spawns Projectile
- `_find_closest_enemy() -> Enemy` — iterates room children, returns closest or null

---

### ExplorationHUD (modified)

**New field**: `@export var _skill_button: Button`
**New behavior**: On `_skill_button.pressed` → emit `GlobalSignals.skill_button_pressed`

---

### GlobalSignals (modified)

**New signal**: `signal skill_button_pressed`

---

## JSON Schema Addition

**File**: `data/skills.json`

New entry added under the existing skills array (or a `"homing_projectile"` key):

```json
{
  "id": "homing_projectile",
  "speed": 600.0,
  "max_distance": 2200.0
}
```

`ResourceManager` exposes `get_skills() -> Array` (already cached). SkillComponent reads this array at `_ready()` to find the entry with `id == "homing_projectile"`.

---

## Data Flow

```
[skills.json]
    ↓ (ResourceManager.get_skills())
SkillComponent._ready()
    → _skill_speed, _skill_max_distance

[Button pressed]
GlobalSignals.skill_button_pressed
    ↓
SkillComponent._on_skill_button_pressed()
    → _find_closest_enemy()
        → RunManager.current_room.get_parent().get_children()
        → filter is Enemy + is_instance_valid
        → sort by distance_to(global_position)
    → CombatComponent.attack_damage * 0.5 → damage
    → Projectile.setup(target, damage, speed, max_distance)
    → room_node.add_child(projectile)

[Each _physics_process frame]
Projectile
    → is_instance_valid(_target)? No → queue_free()
    → distance_traveled > max_distance? → queue_free()
    → move toward _target.global_position
    → Area2D body_entered → take_damage + queue_free()
```
