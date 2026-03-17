# Research: Magic Missile Cooldown

## Decision 1: Timer mechanism — `_process` accumulator vs. Godot `Timer` node

- **Decision**: `_process(delta)` accumulator (`_cooldown_remaining: float` counted down each frame)
- **Rationale**: Adding a `Timer` node to `SkillComponent` would require editing `Player.tscn` in the Godot Editor (Constitution IV). A `_process` accumulator achieves identical behaviour in pure GDScript with no scene changes, keeps the cooldown state visible as a plain float (easy to signal), and fits within the existing `SkillComponent` single-responsibility boundary (Constitution I).
- **Alternatives considered**: `Timer` node — rejected because it requires an `.tscn` edit just to add a child node; `SceneTree.create_timer()` — rejected because it hides remaining-time state, making it harder to drive HUD feedback.

## Decision 2: HUD feedback mechanism — new node vs. modulate existing skill button

- **Decision**: Modulate the `_skill_button` color in `ExplorationHUD` (dim to half-alpha or grey during cooldown; restore to full on ready). No new UI nodes required.
- **Rationale**: No `.tscn` change needed — just a script-driven `modulate` change on the already-exported `_skill_button`. Satisfies FR-007 (player can see skill availability) without violating Constitution IV or Constitution V (YAGNI — no new nodes for a simple visual state).
- **Alternatives considered**: Progress bar overlay — requires new node in `.tscn`, unjustified complexity (V). Pip color during cooldown — pips already communicate charge count; layering cooldown on top creates ambiguity.

## Decision 3: New signal for cooldown state — yes or no

- **Decision**: Add `signal cooldown_changed(remaining: float, total: float)` on `SkillComponent`. `ExplorationHUD.setup_skill()` connects to it.
- **Rationale**: Decouples HUD from SkillComponent internals (Constitution I). HUD reacts to the signal rather than polling. Consistent with the existing `charges_changed` signal pattern.
- **Alternatives considered**: HUD polls `skill._cooldown_remaining` each frame — rejected (breaks encapsulation; HUD would need direct state access to a component's private var).

## Decision 4: Where cooldown resets on run start

- **Decision**: Reset `_cooldown_remaining = 0.0` inside `_reset_charges()`, which is already called via the `run_started` lambda in `_ready()`. One touch point, no new connection needed.
- **Rationale**: `_reset_charges()` already encapsulates "prepare skill for a new run". Cooldown reset belongs there. Avoids a second lambda connection for the same signal.

## Summary of files touched

| File | Change |
|------|--------|
| `data/skills.json` | Add `"cooldown": 1.0` to `magic_missile` entry |
| `scenes/player/components/SkillComponent.gd` | Load `_cooldown_duration`, accumulator in `_process`, gate in `_on_skill_button_pressed`, reset in `_reset_charges`, emit `cooldown_changed` |
| `scenes/ui/hud/ExplorationHUD.gd` | Connect `cooldown_changed` in `setup_skill`, update `_skill_button.modulate` |
