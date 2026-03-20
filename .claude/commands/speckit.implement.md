---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
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
     - If multiple found → prefer the one that contains `tasks.md`; if still ambiguous, pick the most recently modified.
   - ERROR if `FEATURE_DIR/tasks.md` does not exist — suggest running `/speckit.tasks` first.
   - Build AVAILABLE_DOCS by checking which of these exist in FEATURE_DIR: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`, `tasks.md`.

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md — this is the primary source of truth for what to implement.
   - **REQUIRED**: Read plan.md — for tech stack, affected files, and schema changes.
   - **Skip all other artifacts** (research.md, data-model.md, contracts/, quickstart.md) unless a specific task references them. They were already consumed when writing the plan; re-reading them wastes tokens.

4. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

6. Execute implementation following the task plan:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together  
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **Validation checkpoints**: Verify each phase completion before proceeding

7. Implementation execution rules:
   - **Setup first**: Initialize project structure, dependencies, configuration
   - **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
   - **Core development**: Implement models, services, CLI commands, endpoints
   - **Integration work**: Database connections, middleware, logging, external services
   - **Polish and validation**: Unit tests, performance optimization, documentation

8. Progress tracking and error handling:
   - Report progress after each completed task
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P], continue with successful tasks, report failed ones
   - Provide clear error messages with context for debugging
   - Suggest next steps if implementation cannot proceed
   - **IMPORTANT** For completed tasks, use a targeted `Edit` to flip `- [ ]` → `- [x]` for each completed task. **Never rewrite the entire tasks.md** — use one Edit call per phase (batching all checkboxes in that phase into a single old_string/new_string replacement) rather than a full-file write.

9. Completion validation:
   - Verify all required tasks are completed
   - Check that implemented features match the original specification
   - Validate that tests pass and coverage meets requirements
   - Confirm the implementation follows the technical plan
   - Report final status with summary of completed work

10. **Unit Test Sync** (always runs after step 9, even if some tasks were skipped):

    Automatically create or update GUT unit test files for every `.gd` file created or modified during this run that contains testable pure logic.

    **Which files to test** — check each modified/created file for:
    - Filename matches `*Impl.gd` in `scripts/managers/` or `scripts/services/`
    - File contains `static func` declarations
    - File contains public methods with no autoload calls and no Node/scene dependencies (pure computation)

    **For each qualifying file**:
    - Derive the test file path: `tests/unit/test_<snake_case_stem>.gd`
      (e.g., `scripts/managers/MetaManager.gd` → `tests/unit/test_meta_manager.gd`,
       `scenes/ui/hud/ExplorationHUD.gd` with static funcs → `tests/unit/test_exploration_hud.gd`)
    - If the test file **already exists**: read it, then add `test_` functions for any new public methods or behaviors not yet covered. Never remove existing test functions.
    - If the test file **does not exist**: create it following the project test pattern:
      ```gdscript
      extends GutTest

      const Subject = preload("res://path/to/Subject.gd")

      func before_each() -> void:
          # instantiate Subject if stateful

      func test_<behavior>() -> void:
          # assert one behavior per function
      ```
    - Use inline stub dicts for any data dependencies — never call autoloads from test code.
    - One `test_` function per distinct behavior (not one per method). Cover: happy path, boundary/edge values, and any documented invariants.
    - If a `class_name` is required for static method calls (see `ExplorationHUD` lesson), verify it is declared in the source file before writing the test.

    **Skip a file** if all its public methods require autoloads, emit signals as their only output, or are Node lifecycle hooks (`_ready`, `_process`, etc.) with no extractable pure logic.

11. **Update repo_map.md** (always runs after step 10, even if some tasks were skipped):
    - Identify every `.gd` file that was **created or modified** during this implementation run.
    - Also identify any `.gd` files that were **deleted** during this run.
    - **Use Grep to find only the relevant entries** in repo_map.md — do not read the full file. Example: `Grep(pattern="ClassName1|ClassName2|filename", path="repo_map.md", output_mode="content")`. Read only the lines returned.
    - For each created/modified file, read it and extract:
      - `class_name` (if declared)
      - `extends` base type
      - `signal` declarations (name + parameter list)
      - `@export var` declarations (name + type)
      - `const` declarations that are architectural (not magic numbers) — include name and value
      - Public `var` properties with getters (computed properties)
      - Public `func` signatures (name + parameters + return type); skip `_` prefixed private functions **unless** they are signal handlers that other systems connect to
    - Update `repo_map.md`:
      - **New file**: insert a new entry in the correct section (Autoloads, Scripts — Managers, Scripts — Data Models, Scenes — Hub, etc.) following the existing format conventions.
      - **Modified file**: update the existing entry in-place — replace signals, properties, and methods lists entirely rather than appending.
      - **Deleted file**: remove the entry entirely.
      - Preserve all entries for files not touched by this feature.
    - Do **not** regenerate the entire repo_map from scratch — surgical edits only.
    - After editing, do a quick sanity check: confirm the number of `###` headings in the hub/scenes section matches the actual `.gd` files in that directory.

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit.tasks` first to regenerate the task list.
