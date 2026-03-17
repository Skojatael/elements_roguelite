# Quickstart: Player Crit Chance

## What this feature adds

Per-hit random critical strike chance for all player damage (melee + magic missile). Crit chance defaults to 0% (no crits). A crit applies `damage × (1 + crit_multiplier)`; crit multiplier defaults to 0.5 (50% bonus). Both values live in `data/player.json`.

## Files changed

1. `data/player.json` — add `"crit"` section
2. `scenes/player/components/CombatComponent.gd` — crit load + roll on melee
3. `scenes/player/components/SkillComponent.gd` — crit load + roll on missile

## How to test

### Test 1 — Default config (no crits)

1. Leave `player.json` crit_chance at `0.0`
2. Start run, melee/missile enemies many times
3. All damage should be the base value (20 melee, 15 missile at default 75% scaling)

### Test 2 — 100% crit chance

1. Set `"crit_chance": 1.0` in `player.json`, relaunch
2. Melee hit: expect `floorf(20.0 × 1.5)` = 30 damage every hit
3. Missile hit: expect `floorf(15.0 × 1.5)` = 22 damage every hit (floorf of 22.5)

### Test 3 — Custom multiplier

1. Set `"crit_chance": 1.0`, `"crit_multiplier": 1.0` in `player.json`, relaunch
2. Melee hit: expect `floorf(20.0 × 2.0)` = 40 damage
3. Missile hit: expect `floorf(15.0 × 2.0)` = 30 damage

### Test 4 — Enemy damage unaffected

1. Set `"crit_chance": 1.0`, let enemy hit player
2. Player takes normal enemy damage (slime=1, skeleton=2) — no crit bonus

### Test 5 — crit_chance clamping

1. Set `"crit_chance": 5.0` in `player.json`, relaunch
2. Behaviour should match `crit_chance = 1.0` (all hits crit)
