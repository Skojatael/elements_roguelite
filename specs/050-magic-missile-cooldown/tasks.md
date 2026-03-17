# Tasks: Magic Missile Cooldown

**Input**: Design documents from `/specs/050-magic-missile-cooldown/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: No mandatory GUT tests (no `*Impl.gd` files created or modified; `SkillComponent` is a Node with autoload dependencies). Manual validation in quickstart.md covers all success criteria.

**Organization**: Tasks grouped by user story for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (US1, US2, US3)

---

## Phase 1: Setup

No project initialization required — changes land in existing files and directories.

---

## Phase 2: Foundational (Blocking Prerequisite)

**Purpose**: Add the `"cooldown"` field to `skills.json`. All SkillComponent and HUD tasks depend on this data existing.

**⚠️ CRITICAL**: Complete before any user story work begins.

- [x] T001 Add `"cooldown": 1.0` field to the `magic_missile` entry in `data/skills.json`

**Checkpoint**: `skills.json` contains `"cooldown": 1.0` — ready for SkillComponent consumption.

---

## Phase 3: User Story 1 — Cooldown Prevents Rapid Re-fire (Priority: P1) 🎯 MVP

**Goal**: After firing, the skill is locked for 1 second regardless of available charges.

**Independent Test**: Fire missile → press skill button again immediately → no projectile spawns. Wait ~1 second → press again → projectile spawns.

### Implementation for User Story 1

- [x] T002 [US1] Add `signal cooldown_changed(remaining: float, total: float)` and vars `_cooldown_duration: float = 1.0` and `_cooldown_remaining: float = 0.0` to `scenes/player/components/SkillComponent.gd`
- [x] T003 [US1] In `_load_skill_data()` in `scenes/player/components/SkillComponent.gd`, read `_cooldown_duration = float(entry.get("cooldown", 1.0))` after the existing field reads (depends on T001, T002)
- [x] T004 [US1] Add `func _process(delta: float) -> void` to `scenes/player/components/SkillComponent.gd`: guard `if _cooldown_remaining <= 0.0: return`; decrement `_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)`; emit `cooldown_changed.emit(_cooldown_remaining, _cooldown_duration)` (depends on T002)
- [x] T005 [US1] Add cooldown gate `if _cooldown_remaining > 0.0: return` as the first guard in `_on_skill_button_pressed()` in `scenes/player/components/SkillComponent.gd`; after projectile is spawned and charge decremented, add `_cooldown_remaining = _cooldown_duration` and `cooldown_changed.emit(_cooldown_remaining, _cooldown_duration)` (depends on T002, T004)
- [x] T006 [US1] In `_reset_charges()` in `scenes/player/components/SkillComponent.gd`, add `_cooldown_remaining = 0.0` and `cooldown_changed.emit(0.0, _cooldown_duration)` after the existing charge reset lines (depends on T002)

**Checkpoint**: US1 fully functional. Fire missile → blocked for 1 s → fires again. Run-start always clears cooldown.

---

## Phase 4: User Story 2 — Cooldown Duration from Config (Priority: P2)

**Goal**: `"cooldown"` in `skills.json` drives in-game duration with no code change.

**Independent Test**: Change `"cooldown"` to `5.0` in `data/skills.json`, relaunch → skill is blocked for 5 seconds after firing. Restore to `1.0` → 1-second cooldown returns.

> **Note**: US2 implementation is fully delivered by T001 (JSON field) + T003 (load with `.get("cooldown", 1.0)` fallback). No additional code tasks required. The checkpoint below confirms the data-driven contract.

**Checkpoint**: Edit `data/skills.json` cooldown value → behavior matches new value on relaunch. Missing field → defaults to 1.0 without crash.

---

## Phase 5: User Story 3 — HUD Reflects Cooldown State (Priority: P3)

**Goal**: Skill button is visually dimmed during cooldown and restored when ready.

**Independent Test**: Fire missile → skill button goes grey. Wait 1 second → skill button returns to full color.

### Implementation for User Story 3

- [x] T007 [P] [US3] Add constants `SKILL_READY_MODULATE: Color = Color(1, 1, 1, 1)` and `SKILL_COOLDOWN_MODULATE: Color = Color(0.5, 0.5, 0.5, 1)` near the top of `scenes/ui/hud/ExplorationHUD.gd` (alongside existing `CHARGE_ACTIVE_COLOR` / `CHARGE_SPENT_COLOR`)
- [x] T008 [US3] In `setup_skill()` in `scenes/ui/hud/ExplorationHUD.gd`, add `skill.cooldown_changed.connect(_on_cooldown_changed)` after the existing `charges_changed` connection (depends on T007)
- [x] T009 [US3] Add `func _on_cooldown_changed(remaining: float, _total: float) -> void` to `scenes/ui/hud/ExplorationHUD.gd`: single line `_skill_button.modulate = SKILL_COOLDOWN_MODULATE if remaining > 0.0 else SKILL_READY_MODULATE` (depends on T007, T008)

**Checkpoint**: All three user stories functional. Skill fires, cooldown locks it, button dims, 1 s passes, button brightens, skill fires again.

---

## Phase 6: Polish & Validation

- [ ] T010 Run all manual test steps in `specs/050-magic-missile-cooldown/quickstart.md` and confirm SC-001 through SC-005 pass  ← **manual play-test**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately
- **US1 (Phase 3)**: Depends on T001 (JSON field must exist) — **BLOCKS US2 and US3**
- **US2 (Phase 4)**: No code tasks; delivers after T001 + T003 are complete
- **US3 (Phase 5)**: Depends on T002 (`cooldown_changed` signal must exist on SkillComponent)
- **Polish (Phase 6)**: All phases complete

### Task Dependencies Within US1

```
T001 → T002 → T003
             T002 → T004 → T005
             T002 → T006
```

T002, T004, T005, T006 are all in the same file (`SkillComponent.gd`) — implement sequentially.

### Task Dependencies Within US3

T007 → T008 → T009 (same file `ExplorationHUD.gd` — implement sequentially)

### Parallel Opportunities

- T007 (add constants to ExplorationHUD) can start as soon as T002 is complete, in parallel with T003/T004/T005/T006 — they are in different files.

---

## Parallel Example: US1 + US3 overlap

```
After T002 is complete:
  Thread A: T003 → T004 → T005 → T006  (SkillComponent logic)
  Thread B: T007 → T008 → T009          (ExplorationHUD wiring — different file)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete T001 (Foundational)
2. Complete T002 → T006 (US1)
3. **STOP and VALIDATE**: Fire missile, confirm 1-second lock, confirm run-start reset
4. Ship US1 as MVP — core cooldown mechanic is live

### Incremental Delivery

1. T001 → T002–T006 → validate US1 ✅
2. Verify data-driven contract (change JSON, relaunch) → validate US2 ✅
3. T007–T009 → validate US3 ✅ (button dims/brightens)
4. T010 → full quickstart validation ✅

---

## Notes

- All changes are pure GDScript — no `.tscn` edits required
- `_skill_button` is already `@export var` on ExplorationHUD — no Inspector reassignment needed
- `modulate` on `_skill_button` does not affect `_charge_pips_container` — charges still show correctly during cooldown
- Cooldown and charge gate are independent: both must be satisfied to fire
