---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs: 
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: speckit.checklist
    prompt: Create a checklist for the following domain...
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Find feature directory**:
   - If `$ARGUMENTS` contains a directory name (e.g. `002-enemy-combat`), use `specs/<that-name>/` as FEATURE_DIR.
   - Otherwise scan `specs/` for all directories matching `[0-9]+-*`:
     - If exactly one found → use it.
     - If multiple found → pick the one whose `spec.md` was most recently modified.
   - Set paths:
     - `FEATURE_DIR = specs/<matched-directory>/`
     - `FEATURE_SPEC = FEATURE_DIR/spec.md`
     - `IMPL_PLAN = FEATURE_DIR/plan.md`
   - ERROR if `FEATURE_SPEC` does not exist.
   - Read `.specify/templates/plan-template.md` to understand the required plan structure.

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`.

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Resolve all NEEDS CLARIFICATION items
   - Phase 1: Document schema changes and affected files
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 1. Report FEATURE_DIR, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Decisions & Research

1. **Check for NEEDS CLARIFICATION items** in Technical Context:
   - If none exist → skip to Phase 1 immediately.
   - If any exist → resolve each one now (read codebase, apply knowledge) and record decisions.

2. **Record decisions** — choose the leanest format:
   - **Simple feature (no real unknowns, ≤3 decisions)**: Add a `## Decisions` section directly in `plan.md`. Do NOT create a separate `research.md`.
   - **Complex feature (≥4 non-trivial decisions, e.g. new framework, auth design)**: Write `research.md` with Decision / Rationale / Alternatives format.

**Output**: All NEEDS CLARIFICATION resolved. Decisions recorded either inline in plan.md or in research.md.

### Phase 1: Schema Changes & Affected Files

1. **Identify schema/data changes** — choose the leanest format:
   - **Small change (≤3 fields/entities, no new relationships)**: Add a `## Schema Changes` section directly in `plan.md`. Do NOT create a separate `data-model.md`.
   - **Complex data model (new entities with relationships, state machines, validation rules)**: Write `data-model.md`.

2. **List every file that will be created or modified** in a `## Affected Files` section in `plan.md`. For each file, describe the change in one or two prose sentences. **Do NOT include code blocks or code snippets** — code is written once, during `/speckit.implement`.

3. **Skip contracts/ and quickstart.md** for game features — these apply to REST API projects only.

4. **Agent context check**:
   - Review `CLAUDE.md` to confirm it reflects any new architectural patterns introduced by this feature.
   - If new patterns were added, append a brief note to the relevant section of `CLAUDE.md`.

5. **Read repo_map.md** using Grep for the specific symbols/files you need — do not read the full file. Example: `Grep(pattern="RelicManagerImpl|MetaManager", path="repo_map.md")`.

**Output**: plan.md with Decisions (or research.md), Schema Changes (or data-model.md), and Affected Files sections complete.

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
- **No code snippets in plan.md** — prose descriptions only. Code is written once during `/speckit.implement`.
- **Prefer inline sections over separate files** for simple features (saves file-creation cost and re-read cost in implement).
