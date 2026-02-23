# Quickstart: Dev Panel

**Feature**: 005-dev-panel
**Date**: 2026-02-21
**Purpose**: Manual validation scenarios for all three user stories.

---

## Prerequisites

- Godot 4.6 editor open with `project.godot`
- `004-run-manager` complete — `RunManager.start_run()` and `end_run()` functional
- `Main.tscn` is the active main scene

---

## Scenario 1 — Panel visible with DEV_MODE = true (US1, P1)

**Steps**:
1. Ensure `DEV_MODE = true` in `Main.gd`.
2. Run the game.

**Expected**:
- Dev panel appears in the top-left corner immediately on start.
- All four buttons are visible: **Start Run**, **End Run**, **Cash Out**, **Start Boss**.
- No errors in Output.

**Pass criterion**: All four buttons visible within first frame.

---

## Scenario 2 — No panel with DEV_MODE = false (US1, P1)

**Steps**:
1. Set `DEV_MODE = false` in `Main.gd`.
2. Run the game.

**Expected**:
- No panel or buttons visible anywhere on screen.
- No errors or warnings related to DevPanel in Output.
- Game runs normally.

**Pass criterion**: Zero dev panel nodes exist. Restore `DEV_MODE = true` after test.

---

## Scenario 3 — Start Run button (US2, P2)

**Steps**:
1. `DEV_MODE = true`. Run the game.
2. Check Output — a run may already be active (Main.gd auto-starts).
3. Click **Start Run**.

**Expected**:
- Output: `[RunManager] run started — id=... mode=endless`
- If a run was already active, it resets to a fresh run (new run_id).

**Pass criterion**: Run starts immediately on click with correct mode.

---

## Scenario 4 — End Run button (US2, P2)

**Steps**:
1. With an active run, click **End Run**.

**Expected**:
- Output: `[RunManager] run ended — id=... rooms=... currency=...`
- `RunManager.is_run_active` is false.

**Steps (no-op check)**:
2. Click **End Run** again with no active run.

**Expected**:
- Output: `[RunManager] end_run called — no active run, ignoring`
- No error or crash.

**Pass criterion**: Ends active run; no-op when inactive.

---

## Scenario 5 — Cash Out stub (US3, P3)

**Steps**:
1. Click **Cash Out**.

**Expected**:
- Output: `[DevPanel] cash_out pressed — stub`
- No change to `RunManager.run_currency` or any other game state.

**Pass criterion**: Log appears, no state change.

---

## Scenario 6 — Start Boss stub (US3, P3)

**Steps**:
1. Click **Start Boss**.

**Expected**:
- Output: `[DevPanel] start_boss pressed — stub`
- No change to any game state.

**Pass criterion**: Log appears, no state change.
