# Tasks: Player Crit Chance

**Input**: Design documents from `/specs/051-player-crit-chance/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: No mandatory GUT tests (`CombatComponent` and `SkillComponent` are Nodes with autoload dependencies; no `*Impl.gd` files created or modified; no `static func` added). Manual validation per quickstart.md covers all success criteria.

**Organization**: Tasks grouped by user story for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (US1, US2, US3)

---

## Phase 1: Setup

No project initialization required — all changes land in existing files and directories.

---

## Phase 2: Foundational (Blocking Prerequisite)

**Purpose**: Add `"crit"` section to `data/player.json`. All component tasks depend on this data existing.

**⚠️ CRITICAL**: Complete before any user story work begins.

- [x] T001 Add `"crit": {"crit_chance": 0.0, "crit_multiplier": 0.5}` section to `data/player.json` alongside the existing `"combat"`, `"stats"`, and `"movement"` sections

**Checkpoint**: `data/player.json` contains `"crit"` with both fields — ready for component consumption.

---

## Phase 3: User Story 1 — Crit Chance Triggers Bonus Damage on Melee (Priority: P1) 🎯 MVP

**Goal**: Every melee hit rolls crit chance; crits apply `floorf(damage × (1 + crit_multiplier))`.

**Independent Test**: Set `"crit_chance": 1.0` in `player.json`, relaunch → every melee hit deals `floorf(20.0 × 1.5)` = 30 damage. Set back to `0.0` → melee hits deal 20 damage.

### Implementation for User Story 1

- [x] T00X [US1] Add vars `_crit_chance: float = 0.0` and `_crit_multiplier: float = 0.5` to `scenes/player/components/CombatComponent.gd` after the existing `_base_attack_interval` var (depends on T001)
- [x] T00X [US1] In `_ready()` in `scenes/player/components/CombatComponent.gd`, after the existing `_base_attack_interval` load, add: `var crit: Dictionary = ResourceManager.get_player_config().get("crit", {})`; `_crit_chance = minf(1.0, float(crit.get("crit_chance", 0.0)))`; `_crit_multiplier = float(crit.get("crit_multiplier", 0.5))` (depends on T002)
- [x] T00X [US1] Add private helper `func _apply_crit(damage: float) -> float` to `scenes/player/components/CombatComponent.gd`: `if randf() >= _crit_chance: return damage`; `return floorf(damage * (1.0 + _crit_multiplier))` (depends on T002)
- [x] T00X [US1] In `_physics_process()` in `scenes/player/components/CombatComponent.gd`, wrap the damage calculation with `_apply_crit()`: replace `target.take_damage(dmg)` line so that `dmg` is computed as `_apply_crit(attack_damage * RelicManager.get_hit_damage_mult(target.get_hp_ratio(), attacker_ratio))` before being passed to `take_damage` (depends on T003, T004)

**Checkpoint**: US1 functional. Set `crit_chance=1.0`, melee hits deal `floorf(20 × 1.5)` = 30. Set `crit_chance=0.0`, melee hits deal 20.

---

## Phase 4: User Story 2 — Values Are Data-Driven (Priority: P2)

**Goal**: Changing `crit_chance` or `crit_multiplier` in `player.json` changes in-game behaviour with no code change.

**Independent Test**: Change `"crit_multiplier"` to `1.0` in `player.json`, relaunch → melee crits deal `floorf(20 × 2.0)` = 40. Change `"crit_chance"` to `0.25` → roughly 1 in 4 melee hits crits.

> **Note**: US2 implementation is fully delivered by T001 (JSON field) + T003 (load with `.get("crit_chance", 0.0)` fallback). No additional code tasks required.

**Checkpoint**: Edit `data/player.json` crit values → behaviour matches on relaunch. Missing fields → defaults (0.0 / 0.5) apply without crash.

---

## Phase 5: User Story 3 — Crit Applies to Magic Missile (Priority: P3)

**Goal**: Magic missile hits also roll crit chance using the same values.

**Independent Test**: Set `"crit_chance": 1.0`, fire magic missile → hit deals `floorf(15.0 × 1.5)` = 22 damage (floor of 22.5). Set `crit_chance=0.0` → missile deals 15.

### Implementation for User Story 3

- [x] T00X [P] [US3] Add vars `_crit_chance: float = 0.0` and `_crit_multiplier: float = 0.5` to `scenes/player/components/SkillComponent.gd` after the existing `_cooldown_remaining` var (depends on T001)
- [x] T00X [US3] In `_load_skill_data()` in `scenes/player/components/SkillComponent.gd`, before the `break` statement, add: `var crit: Dictionary = ResourceManager.get_player_config().get("crit", {})`; `_crit_chance = minf(1.0, float(crit.get("crit_chance", 0.0)))`; `_crit_multiplier = float(crit.get("crit_multiplier", 0.5))` (depends on T006)
- [x] T00X [US3] Add private helper `func _apply_crit(damage: float) -> float` to `scenes/player/components/SkillComponent.gd`: `if randf() >= _crit_chance: return damage`; `return floorf(damage * (1.0 + _crit_multiplier))` (depends on T006)
- [x] T00X [US3] In `_on_skill_button_pressed()` in `scenes/player/components/SkillComponent.gd`, wrap the damage line: replace `var damage: float = floorf(_combat_component.attack_damage * 0.75)` with `var damage: float = _apply_crit(floorf(_combat_component.attack_damage * 0.75))` (depends on T007, T008)

**Checkpoint**: All three user stories functional. Both melee and missile crits work. Enemy damage to player is unaffected.

---

## Phase 6: Polish & Validation

- [ ] T010 Run all 5 manual test scenarios in `specs/051-player-crit-chance/quickstart.md` and confirm SC-001 through SC-005 pass  ← **manual play-test**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately
- **US1 (Phase 3)**: Depends on T001 — **BLOCKS nothing after** (US2 and US3 can start once T001 + T002 done)
- **US2 (Phase 4)**: No code tasks — delivered by T001 + T003
- **US3 (Phase 5)**: Depends on T001 only; T006 can run in parallel with T002 (different files)
- **Polish (Phase 6)**: All phases complete

### Task Dependencies Within US1

```
T001 → T002 → T003 → T005
             T002 → T004 → T005
```

T002–T005 are all in the same file (`CombatComponent.gd`) — implement sequentially.

### Task Dependencies Within US3

```
T001 → T006 → T007 → T009
             T006 → T008 → T009
```

T006–T009 are all in the same file (`SkillComponent.gd`) — implement sequentially.

### Parallel Opportunities

- T006 (add vars to SkillComponent) can start in parallel with T002 (add vars to CombatComponent) — different files, both only require T001.

---

## Parallel Example: US1 + US3 overlap

```
After T001 is complete:
  Thread A: T002 → T003 → T004 → T005  (CombatComponent — melee crit)
  Thread B: T006 → T007 → T008 → T009  (SkillComponent — missile crit)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete T001 (Foundational)
2. Complete T002 → T005 (US1 — melee crit)
3. **STOP and VALIDATE**: Set `crit_chance=1.0`, confirm melee crits
4. Ship US1 — core crit mechanic is live on melee

### Incremental Delivery

1. T001 → T002–T005 → validate US1 ✅
2. Verify data-driven contract (change JSON, relaunch) → validate US2 ✅
3. T006–T009 → validate US3 ✅ (missile crits)
4. T010 → full quickstart validation ✅

---

## Notes

- All changes are pure GDScript — no `.tscn` edits required
- Crit vars are NOT added to `_recompute_stats()` — crit is config-fixed in this feature (no relic/meta influence in scope)
- `_apply_crit()` is duplicated in both components — justified (2-line formula; YAGNI per Constitution V)
- `crit_chance = 0.0` → `randf()` result is always `>= 0.0` → early return always fires → zero overhead in default config
- Enemy `take_damage()` is called with the final crit-adjusted float; no changes to Enemy or StatsComponent
