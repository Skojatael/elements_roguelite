---
description: Check constitution compliance and run unit tests. Outputs only errors or success. Stops and waits for user approval before suggesting fixes.
---

## Outline

Run a two-stage verification pipeline silently. Output only errors or success messages. Never print verbose intermediate output.

---

### Stage 1: Constitution Compliance Check

Read `.specify/memory/constitution.md` to load all principles (I–VI).

Then scan every `.gd` file that was **created or modified in the most recent feature** (identify by reading the most recently modified `specs/*/tasks.md` and extracting file paths from completed `[x]` tasks). For each file, check compliance against every principle:

**I. Single Responsibility**
- Script mixes concerns (data parsing + game logic + UI in one file) → VIOLATION
- Autoload contains algorithmic logic (not just delegation + signals + state fields) → VIOLATION
- Script in `res://scenes/` not co-located with a scene → VIOLATION
- Script in `res://scripts/` not shared by 2+ scenes or not a manager/autoload → VIOLATION

**II. Data-Driven Content**
- Numeric balance constant hardcoded in `.gd` (magic number literal for enemy stat, upgrade cost, dungeon param, skill value, rate) → VIOLATION
- Raw JSON dictionary accessed without a typed data model wrapper → VIOLATION

**III. Mobile-First Performance**
- `_process()` doing O(n) work per frame where n is unbounded → VIOLATION
- Forward+ renderer shader or effect → VIOLATION
- Non-Jolt physics body introduced → VIOLATION

**IV. Editor-Centric Workflow**
- Raw `.tscn` file edited as text → VIOLATION
- Hardcoded `$NodeName` path for a child node that should be an `@export var` → VIOLATION

**V. Simplicity & YAGNI**
- Abstraction (base class, utility, shared resource) with fewer than 2 concrete call sites → VIOLATION
- Placeholder/stub node or script acting as a future hook → VIOLATION

**VI. Early Return**
- Function body wrapped entirely in a positive `if` when an early `return` would suffice → VIOLATION
- Nesting depth exceeds 2 levels → VIOLATION
- Loop body uses `if condition: [entire body]` instead of `if not condition: continue` → VIOLATION

**Output rules for Stage 1:**
- If NO violations found: print exactly `Constitution check passed.` and proceed to Stage 2.
- If violations found: print each as:
  ```
  VIOLATION [Principle N]: <file path>:<line> — <description>
  ```
  Then print a blank line followed by a proposed fix for each violation. **STOP and wait for user to approve fixes before proceeding.** Do not run Stage 2.

---

### Stage 2: Unit Tests

Run the following command and capture output:

```
"C:\Users\small\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Parse the output:
- If `All tests passed` is present in output: print exactly `Tests passed.` — done.
- If any test failures are present: extract only the failing test names and assertion errors from the output; print them. Then propose a fix for each failure. **STOP and wait for user approval before applying any fix.**

---

### Output format (strict)

Only ever print one of these outcomes per stage — nothing else:

**Success:**
```
Constitution check passed.
Tests passed.
```

**Failure (constitution):**
```
VIOLATION [Principle N]: path/to/file.gd:42 — description
...

Proposed fix: ...
[waiting for approval]
```

**Failure (tests):**
```
FAILED: test_name — assertion message
...

Proposed fix: ...
[waiting for approval]
```
