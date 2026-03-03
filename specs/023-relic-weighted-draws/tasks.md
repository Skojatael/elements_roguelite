# Tasks: Relic Weighted Draws

**Input**: Design documents from `specs/023-relic-weighted-draws/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: Foundational (Data)

**Purpose**: Data changes that everything else depends on.

- [X] T001 [P] Add `relic_tier_weights: { "common": 0.6, "uncommon": 0.3, "rare": 0.1 }` to `data/meta_config.json`
- [X] T002 [P] Add `"uncommon"` tier section with at least 2 relics to `data/relics.json` (follow existing entry schema: name, tags, effect_stat, effect_mult, description)

---

## Phase 2: User Story 1 — Tier-Weighted Relic Offers (Priority: P1) 🎯 MVP

**Goal**: Each offer card is drawn by weighted tier selection from per-tier reshuffling decks.

**Independent Test**: Start run → press "Get Relic" 20 times → tally tier of each left card → roughly 12 common, 6 uncommon, 2 rare.

- [X] T003 [US1] Rewrite `scripts/managers/RelicManagerImpl.gd` — replace `relic_pool: Array[RelicData]` with `_relics_by_id`, `_all_by_tier`, `_decks`, `_tier_weights` fields; rewrite `reset()`, `build_pool(relics_raw, config_raw)`, `draw_offer()`, `compute_stat_mult()`; add private `_draw_one()` per plan.md pseudocode
- [X] T004 [US1] Update `_on_run_started()` in `autoload/RelicManager.gd` — change `_impl.build_pool(ResourceManager.get_relics())` to `_impl.build_pool(ResourceManager.get_relics(), ResourceManager.get_meta_config())`

**Checkpoint**: Run quickstart scenarios 1–5.

---

## Phase 3: Polish

- [ ] T005 Run all 6 quickstart scenarios from `specs/023-relic-weighted-draws/quickstart.md`

---

## Dependencies & Execution Order

- T001 and T002 are parallel (different files, no code dependencies)
- T003 depends on T001 and T002 being complete (reads both JSON structures)
- T004 depends on T003 (new build_pool signature must exist before call site changes)
- T005 requires T001–T004 complete

---

## Implementation Strategy

1. T001 + T002 in parallel (data files)
2. T003 (full RelicManagerImpl rewrite)
3. T004 (update call site in autoload)
4. T005 validate
