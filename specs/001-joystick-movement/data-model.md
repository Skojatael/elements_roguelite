# Data Model: Player Movement Joystick Controls

**Branch**: `001-joystick-movement` | **Date**: 2026-02-19

---

## Entities

### JoystickControl

**Scene**: `scenes/ui/hud/Joystick.tscn`
**Script**: `scenes/ui/hud/Joystick.gd`
**Extends**: `Control`

Translates touch drag input into a normalised movement vector. Has exactly one
responsibility: input → vector. It does not move the player.

#### Public interface

| Name | Type | Description |
|------|------|-------------|
| `input_vector` | `Vector2` | Normalised direction × magnitude (0.0 – 1.0). `Vector2.ZERO` when idle or inside dead zone. Read-only from outside. |
| `max_radius` | `float` (@export) | Maximum knob drag distance in pixels. Default: `80.0`. |
| `dead_zone_percentage` | `float` (@export) | Fraction of `max_radius` below which input is zero. Range 0.0 – 1.0. Default: `0.1`. |

#### Internal state

| Name | Type | Description |
|------|------|-------------|
| `_touch_index` | `int` | Touch point index tracking this joystick (-1 = idle). |
| `_knob_offset` | `Vector2` | Current pixel offset of the knob from base centre. |

#### Node children (built in Editor)

| Node | Type | Purpose |
|------|------|---------|
| `Base` | `TextureRect` | Visual background circle (placeholder). |
| `Knob` | `TextureRect` | Draggable thumb indicator (placeholder). |

#### State transitions

```
IDLE  ──── ScreenTouch (finger down in rect) ────► ACTIVE
ACTIVE ──── ScreenDrag ────────────────────────► ACTIVE (updates _knob_offset)
ACTIVE ──── ScreenTouch (finger up) ───────────► IDLE (reset _knob_offset, input_vector)
IDLE   ──── ScreenDrag (different touch) ───────► IDLE (ignored)
```

---

### MovementComponent (updated)

**Script**: `scenes/player/components/MovementComponent.gd`
**Extends**: `Node`

Applies velocity to the player each physics frame based on joystick input.
Has exactly one responsibility: input vector → player motion.

#### Public interface

| Name | Type | Description |
|------|------|-------------|
| `move_speed` | `float` (@export) | Maximum movement speed in pixels/second. Default: `200.0`. |
| `set_joystick(node: Node)` | `void` | Receives the JoystickControl reference from the coordinator. |

#### Internal state

| Name | Type | Description |
|------|------|-------------|
| `_joystick` | `Node` | Reference to the JoystickControl node. Null-safe. |

---

### Coordinator (Main.gd / game scene script)

Not a standalone entity — a wiring script on `Main.tscn` (or the active room
scene). Responsible for connecting the Joystick node reference to
MovementComponent after both subtrees are ready.

#### Responsibility

Calls `movement_component.set_joystick(joystick_node)` in `_ready()`. No other
logic; does not own joystick state or movement state.

---

## Validation Rules

| Rule | Where enforced |
|------|---------------|
| `max_radius` > 0 | `_ready()` assertion in Joystick.gd |
| `dead_zone_percentage` in [0.0, 0.5] | `_ready()` assertion in Joystick.gd |
| `_touch_index` == -1 on second touch (joystick already active) | `_gui_input` guard |
| `move_speed` > 0 | `_ready()` assertion in MovementComponent.gd |
| Joystick reference set before first `_physics_process` | null check in MovementComponent |

---

## Data Flow

```
Touch drag (InputEventScreenDrag)
        │
        ▼
Joystick._gui_input()
  ├─ Compute knob_offset = clamp(drag_position - base_centre, max_radius)
  ├─ Apply radial dead zone
  └─ Set input_vector = knob_offset.normalized() * (length / max_radius)
        │
        ▼ (polled each physics frame)
MovementComponent._physics_process()
  └─ velocity = joystick.input_vector * move_speed
        │
        ▼
CharacterBody2D.move_and_slide()   (or equivalent in Player.tscn)
```
