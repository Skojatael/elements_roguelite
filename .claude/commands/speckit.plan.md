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
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 2 planning. Report FEATURE_DIR, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Agent context check**:
   - Review `CLAUDE.md` to confirm it reflects any new technology introduced by this feature's plan.
   - If new tools, libraries, or architectural patterns were added, append a brief note under the relevant section of `CLAUDE.md`. Preserve all existing content.

**Output**: data-model.md, /contracts/*, quickstart.md

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
