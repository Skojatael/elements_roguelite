# Data Model: Magic Missile Cooldown

## JSON Schema Change — `data/skills.json`

Add a `"cooldown"` field to the existing `magic_missile` entry:

```json
{
  "skills": [
    {
      "id": "magic_missile",
      "speed": 600.0,
      "max_distance": 2200.0,
      "max_charges": 3,
      "cooldown": 1.0
    }
  ]
}
```

- **Field**: `cooldown` (float, seconds)
- **Default if absent**: `1.0`
- **Valid range**: any positive float; the game does not validate this beyond `> 0`

## Runtime State — `SkillComponent`

New fields added to `SkillComponent.gd` (no new script or scene):

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `_cooldown_duration` | `float` | `1.0` | Loaded from `skills.json`; immutable after `_ready()` |
| `_cooldown_remaining` | `float` | `0.0` | Seconds until next fire is allowed; counted down in `_process` |

New signal:

| Signal | Args | When emitted |
|--------|------|-------------|
| `cooldown_changed` | `remaining: float, total: float` | After `_cooldown_remaining` changes — on fire (start) and each frame while active, and once on expiry |

> **Note**: emitting every frame is acceptable for a UI-driving signal in a mobile 60 fps context; the HUD handler is a simple `modulate` assignment (O(1)).

## State Transitions

```
READY (cooldown_remaining == 0)
  │  player fires missile
  ▼
COOLING (cooldown_remaining > 0)
  │  _process subtracts delta each frame
  │  emits cooldown_changed each frame
  ▼  cooldown_remaining reaches 0
READY
```

Reset path: `run_started` → `_reset_charges()` → `_cooldown_remaining = 0.0` → emits `cooldown_changed(0, total)`
