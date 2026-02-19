# Contract: Player Combat Component Interface

**Feature**: `002-enemy-combat`
**File**: `scenes/player/components/CombatComponent.gd`

---

## Class Declaration

```gdscript
class_name CombatComponent
extends Node
```

---

## Exports & Public Properties

```gdscript
## Damage dealt to one enemy per attack.
@export var attack_damage: float = 1.0

## Seconds between automatic attacks.
@export var attack_interval: float = 0.5
```

---

## Public API

No public methods required for MVP. CombatComponent is self-contained: it detects overlapping enemies via its `Area2D` child and auto-attacks on its internal timer.

---

## Internal Nodes (set up in Editor)

| Node | Type | Purpose |
|---|---|---|
| `AttackArea` | `Area2D` + `CollisionShape2D` | Circle matching player attack reach; detects overlapping `Enemy` bodies |

---

## Behaviour Guarantees

| Condition | Guaranteed Behaviour |
|---|---|
| No enemies in `AttackArea` | No `take_damage()` calls made |
| One or more enemies in `AttackArea` | `take_damage(attack_damage)` called on one enemy every `attack_interval` seconds |
| Enemy is freed while in `AttackArea` | Freed enemy removed from internal list; no crash |
| `attack_damage <= 0` | `_ready()` assertion fails with descriptive error |
| `attack_interval <= 0` | `_ready()` assertion fails with descriptive error |
