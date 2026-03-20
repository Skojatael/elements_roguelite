# Requirements Checklist — 065-burn-relic-scaling

Evaluated against `spec.md`. Each item is assessed for completeness and clarity as written in the spec.

---

## Functional Requirements

| ID | Requirement Summary | Result | Notes |
|----|---|---|---|
| FR-001 | Burn tick damage multiplied by combined burn_damage relic bonus | PASS | Clearly stated; additive stacking explicit |
| FR-002 | Multiplier applies regardless of burn source (projectile or skill) | PASS | Both sources explicitly called out |
| FR-003 | System can determine whether an enemy is currently burning at any moment | PASS | Prerequisite for Searing Seal; stated as own requirement |
| FR-004 | Searing Seal applies ×1.50 to direct hits on burning enemies | PASS | Multiplier value matches feature description |
| FR-005 | Searing Seal bonus only active while target is burning at moment of hit | PASS | Pre- and post-burn cases explicitly excluded |
| FR-006 | Searing Seal stacks correctly with other conditional hit bonuses | PASS | Scenario 4 in Story 2 and FR-006 both cover this |
| FR-007 | Searing Seal exists in relic data as uncommon with blank stat effect | PASS | Matches the data fix described in feature input |
| FR-008 | Bottled Oil burn bonus is additive with other burn_damage relics | PASS | Explicitly ties to existing additive formula |
| FR-009 | burn_damage relics do NOT affect direct hit damage | PASS | Isolation boundary clearly drawn |
| FR-010 | Searing Seal does NOT affect burn tick damage | PASS | Isolation boundary clearly drawn (mirror of FR-009) |

All 10 functional requirements: **PASS**

---

## User Stories

| Story | Title | Result | Notes |
|---|---|---|---|
| US-1 | Bottled Oil increases burn tick damage | PASS | 5 acceptance scenarios; covers projectile and skill paths |
| US-2 | Searing Seal rewards hitting burning targets | PASS | 5 acceptance scenarios; covers non-burning baseline, stacking, expiry |

---

## Success Criteria

| ID | Criterion Summary | Result | Notes |
|----|---|---|---|
| SC-001 | Bottled Oil produces measurable 20% tick damage increase | PASS | Verifiable via per-tick health observation |
| SC-002 | Searing Seal produces measurable 50% hit bonus vs burning; zero vs non-burning | PASS | Both positive and negative cases stated |
| SC-003 | Burn ticks and direct hits remain independent of each other's relics | PASS | Directly enforces FR-009 and FR-010 at the outcome level |
| SC-004 | Both effects combine correctly with all other active relics | PASS | Covers interaction correctness broadly |
| SC-005 | Searing Seal appears in relic offer pool and is collectible without errors | PASS | Runtime availability criterion |

All 5 success criteria: **PASS**

---

## Edge Cases Coverage

| Edge Case | Covered in Spec | Notes |
|---|---|---|
| Burn expires in same frame as hit — Searing Seal timing | Partially | Raised as edge case; not resolved to a definitive rule in requirements |
| Multiple simultaneous burn sources with Bottled Oil | Raised | Not resolved — acceptable as implementation detail |
| Bottled Oil picked up mid-run; effect on already-active burns | Raised | Not resolved — flagged for implementer decision |
| Burn from non-player source and Searing Seal | Raised | Not resolved — noted for implementer |

Edge case coverage is appropriate for a spec at this stage. All four ambiguities are surfaced and left for implementer or follow-up design decision rather than being silently ignored.

---

## Overall Assessment

**PASS** — The spec is internally consistent, technology-agnostic, and covers all three feature components (Bottled Oil burn scaling, Searing Seal conditional hit bonus, data fix). All functional requirements are independently testable and traceable to at least one acceptance scenario. Isolation boundaries between the two relic effects are clearly defined. Four edge cases are surfaced but unresolved, which is appropriate at spec stage.
