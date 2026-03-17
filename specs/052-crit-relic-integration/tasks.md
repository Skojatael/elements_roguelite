# Tasks: Crit Relic Integration

**Input**: Design documents from `/specs/052-crit-relic-integration/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Organization**: Tasks are grouped by phase. US1 (crit_chance) and US2 (crit_multiplier) share the same implementation files and are delivered together in Phase 3.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no incomplete dependencies)
- **[Story]**: Which user story this task belongs to

---

## Phase 1: Setup

*No project setup required — this feature modifies four existing files only.*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the additive stat accumulator to `RelicManagerImpl` and expose it via `RelicManager`. Both US1 and US2 depend on this before any reactive wiring can work.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Add `compute_stat_addend(stat: String) -> float` to `scripts/managers/RelicManagerImpl.gd` — iterates `active_relic_ids`, sums `effect_mult` for each relic whose `effect_stat == stat`, returns `0.0` when none match (early-return/continue pattern, max nesting depth 2)
- [x] T002 [P] Add `get_stat_addend(stat: String) -> float` thin wrapper to `autoload/RelicManager.gd` — single line `return _impl.compute_stat_addend(stat)` with a doc comment

**Checkpoint**: `RelicManager.get_stat_addend("crit_chance")` and `get_stat_addend("crit_multiplier")` callable. Returns `0.0` with no relics active.

---

## Phase 3: User Stories 1 & 2 — Crit Chance and Crit Multiplier Reactive Wiring (Priority: P1) 🎯 MVP

**Goal**: Picking a relic with `effect_stat = "crit_chance"` or `"crit_multiplier"` immediately updates the effective stat used for all player damage (melee and magic missile). Run end reverts both stats to base config values.

**Independent Test**: Use DevPanel to grant a relic with `effect_stat = "crit_chance"` and `effect_mult = 1.0` (forcing 100% crits). Every melee hit and every magic missile should deal `base_damage × (1 + crit_multiplier)`. After run end, crit behaviour should revert to base config values (0% crit by default).

### Tests for User Stories 1 & 2 (mandatory — modified `*Impl.gd`)

> **Write these first; they MUST FAIL before T004 is implemented.**

- [x] T003 [P] Add `compute_stat_addend` test suite to `tests/unit/test_relic_deck.gd`:
  - Add stub entries with `effect_stat: "crit_chance"` / `"crit_multiplier"` to `STUB_RELICS` (or create a local stub inside the test methods).
  - Test: no held relics → returns `0.0` for `"crit_chance"`.
  - Test: one crit_chance relic with `effect_mult = 0.15` held → returns `0.15`.
  - Test: two crit_chance relics (`0.10` + `0.15`) held → returns `0.25` (US3 stacking).
  - Test: crit_multiplier relic held → `compute_stat_addend("crit_chance")` still returns `0.0` (no cross-contamination).
  - Test: `compute_stat_addend("crit_multiplier")` with one relic (`0.25`) held → returns `0.25`.

### Implementation for User Stories 1 & 2

- [x] T004 [US1] [US2] Update `scenes/player/components/CombatComponent.gd`:
  - Add `var _base_crit_chance: float = 0.0` and `var _base_crit_multiplier: float = 0.5`.
  - In `_ready()`: assign config values to `_base_crit_chance` and `_base_crit_multiplier` (currently assigned directly to `_crit_chance`/`_crit_multiplier` — move to base fields instead).
  - In `_recompute_stats()`: append two lines:
    ```
    _crit_chance     = minf(1.0, _base_crit_chance    + RelicManager.get_stat_addend("crit_chance"))
    _crit_multiplier = _base_crit_multiplier + RelicManager.get_stat_addend("crit_multiplier")
    ```
  - Verify the existing `run_started`, `relic_applied`, `relics_cleared` connections already call `_recompute_stats()` — no new connections needed.

- [x] T005 [P] [US1] [US2] Update `scenes/player/components/SkillComponent.gd`:
  - Add `var _base_crit_chance: float = 0.0` and `var _base_crit_multiplier: float = 0.5`.
  - In `_load_skill_data()`: assign config crit values to `_base_crit_chance` / `_base_crit_multiplier` (currently assigned to `_crit_chance` / `_crit_multiplier` — move to base fields).
  - Add new method `_recompute_crit_stats() -> void`:
    ```
    _crit_chance     = minf(1.0, _base_crit_chance    + RelicManager.get_stat_addend("crit_chance"))
    _crit_multiplier = _base_crit_multiplier + RelicManager.get_stat_addend("crit_multiplier")
    ```
  - In `_ready()` (after `_load_skill_data()` and existing signal connections), add:
    ```
    RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_crit_stats())
    RelicManager.relics_cleared.connect(func() -> void: _recompute_crit_stats())
    RunManager.run_started.connect(func(_m: String) -> void: _recompute_crit_stats())
    ```
  - Note: `RunManager.run_started` is already connected for `_reset_charges()` — the new connection is a second lambda on the same signal, which is valid.

**Checkpoint**: US1 and US2 complete. Picking a crit_chance or crit_multiplier relic updates both melee and missile crit behaviour immediately.

---

## Phase 4: User Story 3 — Multiple Crit Relics Stack Correctly (Priority: P2)

**Goal**: Two crit_chance relics each granting +10% result in +20% total effective crit_chance.

**Independent Test**: T003 already covers stacking via the two-relic `compute_stat_addend` test. Manual verification: grant two crit_chance relics in the same run via DevPanel and confirm effective crit rate is cumulative.

*No additional implementation tasks — stacking is inherent to the additive accumulator added in Phase 2.*

**Checkpoint**: US3 validated through T003 test passing and manual DevPanel verification.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [ ] T006 Validate feature end-to-end per `specs/052-crit-relic-integration/quickstart.md` (manual in-editor validation): grant a crit_chance relic via DevPanel, confirm crits fire at the expected rate, end the run, confirm crit rate reverts to base.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately.
- **User Stories (Phase 3)**: T004 and T005 depend on T001 (T002 can be done in parallel with T001 but T002 has no effect until T001 exists).
- **US3 (Phase 4)**: Validated by T003 — no additional implementation.
- **Polish (Phase 5)**: Depends on Phase 3 complete.

### User Story Dependencies

- **US1 + US2 (P1)**: Start after T001 complete. T004 and T005 are independent (different files).
- **US3 (P2)**: Covered by T003 accumulator tests — no blocking dependency.

### Within Phase 3

- T003 (test): write and confirm FAIL before T004.
- T004 and T005: independent files — can be worked in parallel after T001 is done.

### Parallel Opportunities

- T002 and T003 can begin as soon as T001 is done.
- T004 and T005 can run in parallel (different files, same prerequisite T001).

---

## Parallel Example: Phase 3

```
After T001 completes:
  Thread A → T002 (RelicManager wrapper)
  Thread B → T003 (unit tests — write failing tests first)

After T001 + T003:
  Thread A → T004 (CombatComponent)
  Thread B → T005 (SkillComponent)
```

---

## Implementation Strategy

### MVP (All stories — this feature is small enough to do end-to-end)

1. T001 — `compute_stat_addend` in RelicManagerImpl
2. T002 — `get_stat_addend` wrapper in RelicManager
3. T003 — unit tests (write failing first)
4. T004 — CombatComponent wiring
5. T005 — SkillComponent wiring
6. T006 — end-to-end validation

**Total tasks**: 6
**Mandatory test tasks**: 1 (T003 — covers US1, US2, and US3 stacking)
**Parallel opportunities**: T002+T003 after T001; T004+T005 after T001
**MVP scope**: All phases (feature is too small to meaningfully partial-deliver)

---

## Notes

- [P] tasks target different files and have no incomplete dependencies.
- No new JSON entries in `relics.json` are created here — plumbing only. Future crit relics are added directly to JSON.
- `_crit_chance` and `_crit_multiplier` in both components become *effective* (recomputed) values after this feature; `_base_*` fields hold the immutable config values.
- The existing `compute_stat_mult` in `RelicManagerImpl` is unchanged — multiplicative semantics remain correct for `attack_damage`, `attack_speed`, `max_health`, `move_speed`.
