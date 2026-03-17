# Quickstart: Magic Missile Cooldown

## What this feature adds

A 1-second cooldown on the magic missile skill. After firing, the skill is locked regardless of charge count until the timer expires. Duration is read from `skills.json` — change `"cooldown"` and relaunch to tune it.

## Files to change (no new files, no scene edits)

1. `data/skills.json` — add `"cooldown": 1.0` to `magic_missile`
2. `scenes/player/components/SkillComponent.gd` — cooldown state + `_process` countdown
3. `scenes/ui/hud/ExplorationHUD.gd` — `_skill_button.modulate` dims during cooldown

## How to test

1. Launch game → start run → enter combat room.
2. Press skill button → missile fires.
3. Immediately press again → **nothing fires** (cooldown active).
4. Wait ~1 second → press again → **missile fires**.
5. Edit `skills.json`, set `"cooldown": 5.0`, relaunch → wait confirms 5-second gap.
6. Start a new run → skill button is immediately usable (cooldown reset).
