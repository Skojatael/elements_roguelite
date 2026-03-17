# Implementation Plan: Magic Missile Cooldown

**Branch**: `050-magic-missile-cooldown` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/050-magic-missile-cooldown/spec.md`

## Summary

Add a 1-second per-use cooldown to the magic missile skill. After firing, the skill is blocked for the configured duration regardless of available charges. The cooldown duration is read from `data/skills.json` (`"cooldown": 1.0`). The HUD dims the skill button during cooldown. No new scenes, nodes, or autoloads are required — three files change: the JSON config, `SkillComponent.gd`, and `ExplorationHUD.gd`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Existing `SkillComponent`, `ExplorationHUD`, `skills.json`, `GlobalSignals`
**Storage**: `data/skills.json` (add one field)
**Testing**: Manual in-editor play; GUT unit tests (optional)
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Performance Goals**: 60 fps mobile; `_process` accumulator is O(1) — no impact
**Constraints**: No new `.tscn` edits; no new autoloads; no hardcoded balance values
**Scale/Scope**: 3 file changes; self-contained within `SkillComponent` + `ExplorationHUD`

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Single Responsibility** | ✅ PASS | Cooldown state owned exclusively by `SkillComponent`. HUD is notified via signal — no cross-scene polling. |
| **II. Data-Driven Content** | ✅ PASS | `"cooldown": 1.0` in `skills.json`; no balance constant in GDScript. Default fallback `1.0` is a code-safety default, not a balance value. |
| **III. Mobile-First** | ✅ PASS | `_process` accumulator is O(1); `modulate` assignment is trivial. No new draw calls. |
| **IV. Editor-Centric** | ✅ PASS | No `.tscn` edits. No new nodes. `_skill_button` already exported and Inspector-assigned. |
| **V. Simplicity & YAGNI** | ✅ PASS | `_process` accumulator instead of Timer node. Button modulate instead of progress bar node. No speculative cooldown-reduction hooks. |
| **VI. Early Return** | ✅ PASS | New guard in `_on_skill_button_pressed`: `if _cooldown_remaining > 0.0: return`. Max nesting depth stays at 2. |

No violations. No complexity tracking required.

## Project Structure

### Documentation (this feature)

```text
specs/050-magic-missile-cooldown/
├── plan.md          ← this file
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── tasks.md         ← created by /speckit.tasks
```

### Source Code (files changed)

```text
data/
└── skills.json                                  ← add "cooldown": 1.0

scenes/player/components/
└── SkillComponent.gd                            ← cooldown fields + _process + signal

scenes/ui/hud/
└── ExplorationHUD.gd                            ← connect cooldown_changed, modulate button
```

**Structure Decision**: Single-project Godot layout. All changes are within existing files and directories. No new scripts, scenes, or folders.

## Design Detail

### `data/skills.json` change

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

### `SkillComponent.gd` additions

**New signal**:
```gdscript
signal cooldown_changed(remaining: float, total: float)
```

**New vars** (after existing vars):
```gdscript
var _cooldown_duration: float = 1.0
var _cooldown_remaining: float = 0.0
```

**`_load_skill_data()` addition** (after loading `_max_charges`):
```gdscript
_cooldown_duration = float((entry as Dictionary).get("cooldown", 1.0))
```

**New `_process(delta)`**:
```gdscript
func _process(delta: float) -> void:
    if _cooldown_remaining <= 0.0:
        return
    _cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
    cooldown_changed.emit(_cooldown_remaining, _cooldown_duration)
```

**`_on_skill_button_pressed()` — new guard** (insert as first guard after existing ones, or before the target find):
```gdscript
if _cooldown_remaining > 0.0:
    return
```

**After projectile spawned + charge decremented** — start cooldown:
```gdscript
_cooldown_remaining = _cooldown_duration
cooldown_changed.emit(_cooldown_remaining, _cooldown_duration)
```

**`_reset_charges()` addition**:
```gdscript
_cooldown_remaining = 0.0
cooldown_changed.emit(0.0, _cooldown_duration)
```

### `ExplorationHUD.gd` additions

Constants:
```gdscript
const SKILL_READY_MODULATE: Color = Color(1, 1, 1, 1)
const SKILL_COOLDOWN_MODULATE: Color = Color(0.5, 0.5, 0.5, 1)
```

In `setup_skill()`:
```gdscript
skill.cooldown_changed.connect(_on_cooldown_changed)
```

New handler:
```gdscript
func _on_cooldown_changed(remaining: float, _total: float) -> void:
    _skill_button.modulate = SKILL_COOLDOWN_MODULATE if remaining > 0.0 else SKILL_READY_MODULATE
```
