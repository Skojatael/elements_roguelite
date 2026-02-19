# Contract: JoystickControl Interface

**Branch**: `001-joystick-movement` | **Date**: 2026-02-19

> This is a GDScript component interface contract, not a REST API.
> It defines what each component exposes and what it expects, so that
> implementors and consumers have a clear, testable boundary.

---

## JoystickControl (`Joystick.gd`)

### Exposes

```gdscript
class_name JoystickControl
extends Control

## Maximum drag distance from base centre, in pixels.
@export var max_radius: float = 80.0

## Fraction of max_radius treated as dead zone (no input).
@export var dead_zone_percentage: float = 0.1

## Current normalised movement input. direction × magnitude (0.0–1.0).
## Vector2.ZERO when idle or inside the dead zone.
## READ-ONLY from outside this script.
var input_vector: Vector2 = Vector2.ZERO
```

### Behaviour guarantees

| Condition | Guarantee |
|-----------|-----------|
| No finger on joystick | `input_vector == Vector2.ZERO` |
| Finger inside dead zone | `input_vector == Vector2.ZERO` |
| Finger at max drag distance | `input_vector.length() == 1.0` |
| Finger at 50% drag distance | `input_vector.length() ≈ 0.5` |
| Second simultaneous touch | Ignored; first touch keeps priority |
| Finger lifted | `input_vector` resets to `Vector2.ZERO` within 1 frame |

### Does NOT

- Apply movement to any node.
- Know about the Player or MovementComponent.
- Emit signals (polling interface only for v1).

---

## MovementComponent (`MovementComponent.gd`)

### Exposes

```gdscript
class_name MovementComponent
extends Node

## Maximum movement speed in pixels per second.
@export var move_speed: float = 200.0

## Called by coordinator (Main.gd or game scene) to wire the joystick reference.
func set_joystick(node: Node) -> void
```

### Behaviour guarantees

| Condition | Guarantee |
|-----------|-----------|
| `set_joystick` not called | No movement applied (null-safe guard) |
| `joystick.input_vector == Vector2.ZERO` | Player velocity = zero |
| `joystick.input_vector.length() == 1.0` | Player velocity = `move_speed` px/s |
| Called each `_physics_process` | Movement is frame-rate independent |

### Does NOT

- Own touch input logic.
- Know about the HUD or joystick scene placement.
- Communicate back to the joystick.

---

## Coordinator Contract (Main.gd or active game scene)

### Responsibility

Wire the two components together after both are ready.

```gdscript
func _ready() -> void:
    var joystick: JoystickControl = $ExplorationHUD/Joystick
    var movement: MovementComponent = $Player/MovementComponent
    movement.set_joystick(joystick)
```

### Guarantees

- Called once per scene load, not per frame.
- Does not hold joystick state.
- Does not interpret the input vector.

---

## Interaction Diagram

```
[Touch Input]
      │ InputEventScreenTouch / InputEventScreenDrag
      ▼
[JoystickControl]
  input_vector: Vector2    ◄── polled each _physics_process
      │
      │ (coordinator passes node reference once in _ready)
      ▼
[MovementComponent]
  velocity = input_vector × move_speed
      │
      ▼
[CharacterBody2D / Player]
  move_and_slide()
```
