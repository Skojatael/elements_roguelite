# Research: Player Crit Chance

## Decision 1: Where to store crit config — new file vs. extend player.json

- **Decision**: Add a `"crit"` section to the existing `data/player.json`
- **Rationale**: `data/player.json` already exists and already has `"combat"`, `"stats"`, and `"movement"` sections. `CombatComponent` already reads from it via `ResourceManager.get_player_config()`. Adding `"crit"` follows the exact same pattern with no new file, no new ResourceManager method, and no new cache entry. `player.json` is the correct home for all player-tuning values.
- **Alternatives considered**: `data/player_stats.json` (spec assumption) — rejected; would require a new ResourceManager method and cache slot, adding unnecessary complexity for data that already belongs in player.json. Adding to `data/skills.json` — rejected; skills config is skill-scoped, not player-global.

## Decision 2: Where the crit roll executes — CombatComponent vs. shared utility

- **Decision**: Inline crit roll in both `CombatComponent` and `SkillComponent` as private helpers. No shared utility.
- **Rationale**: The crit formula is 2-3 lines (`randf() < _crit_chance → floorf(dmg * (1 + _crit_multiplier))`). A shared utility is justified by Constitution V only when two concrete call sites share non-trivial logic. Here the logic is trivially simple, and each component already reads its own stats subset from `player.json`. Inlining keeps each component self-contained (Constitution I).
- **Alternatives considered**: `static func` in `Utilities.gd` — unjustified abstraction for 2 lines; adds a cross-file dependency for no benefit. New `CritComponent` on the player — overkill; crit is a damage-calculation concern, not a standalone behavior.

## Decision 3: Where crit roll applies to magic missile — SkillComponent vs. Projectile

- **Decision**: Crit roll in `SkillComponent._on_skill_button_pressed()` before calling `projectile.setup()`. The crit-adjusted damage is passed into `setup()`.
- **Rationale**: `Projectile` is a delivery mechanism — it should be unaware of player stats. Crit is a player-stat concern. Placing the roll in `SkillComponent` keeps `Projectile` unchanged and focused on movement/collision (Constitution I — single responsibility).
- **Alternatives considered**: Crit in `Projectile.setup()` — rejected; projectile would need crit_chance/mult params, bloating its interface and coupling it to player stats.

## Decision 4: Crit vars in recompute_stats() or load-once

- **Decision**: Load crit vars once in `_ready()` / `_load_skill_data()`. They are NOT included in `_recompute_stats()`.
- **Rationale**: In this feature, crit stats are fixed config values — not affected by relics or meta upgrades. `_recompute_stats()` is triggered by relic events; including crit there would be speculative (Constitution V — YAGNI). When relics or meta can modify crit, a future feature will add them to `_recompute_stats()`.
- **Alternatives considered**: Include in `_recompute_stats()` — rejected; no relic or meta system touches crit in this feature, so it would be a speculative hook.

## Summary of files touched

| File | Change |
|------|--------|
| `data/player.json` | Add `"crit": {"crit_chance": 0.0, "crit_multiplier": 0.5}` |
| `scenes/player/components/CombatComponent.gd` | Load crit vars, apply crit roll to melee damage |
| `scenes/player/components/SkillComponent.gd` | Load crit vars, apply crit roll to missile damage |
