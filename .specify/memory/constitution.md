<!--
SYNC IMPACT REPORT
==================
Version change: 1.1.1 → 1.2.0
Bump type: MINOR — New bullet added to Principle IV (Editor-Centric Workflow)
governing node-reference style in GDScript. No principle removed or redefined;
existing guidance preserved in full.

Modified principles:
  IV. Editor-Centric Workflow — added "Node references" bullet prohibiting
      hardcoded $NodeName paths for configurable children.

Added sections: NONE

Removed sections: NONE

Templates reviewed:
  ✅ .specify/templates/plan-template.md
       — No node-reference guidance; no changes required.
  ✅ .specify/templates/spec-template.md
       — No node-reference guidance; no changes required.
  ✅ .specify/templates/tasks-template.md
       — No node-reference guidance; no changes required.

Deferred items: NONE
Follow-up TODOs: NONE
-->

# Roguelite Game Constitution

## Core Principles

### I. Single Responsibility (NON-NEGOTIABLE)

Every script, scene, component, and autoload MUST have exactly one reason to
change — a single, well-defined responsibility.

- **Scripts**: A script MUST handle one concern. Mixing data-parsing, game
  logic, and UI presentation in a single script is prohibited. Scripts MUST be
  co-located with their scene when they serve only that scene; scripts placed
  in `res://scripts/` MUST be shared by at least two distinct scenes or serve
  as a manager/autoload.
- **Player components**: Player behavior MUST be composed from the discrete
  child components in `scenes/player/components/` (MovementComponent,
  DodgeComponent, CombatComponent, SkillComponent, StatsComponent). Monolithic
  player scripts are prohibited. New player capabilities MUST each become a
  separate component rather than extending an existing one.
- **Scenes**: Every scene MUST be independently preloadable and self-contained.
  Cross-scene `get_node()` paths reaching outside a scene's own subtree are
  prohibited — communicate via autoloads or signals instead.
- **Autoloads**: Each autoload MUST own exactly one domain (e.g.,
  `ResourceManager` handles only resource loading; it MUST NOT absorb save or
  meta logic). New autoloads MUST NOT duplicate responsibility with an existing
  autoload, and MUST be explicitly justified in the feature plan.

**Rationale**: A single reason to change makes every unit independently
testable, replaceable, and understandable. In a Godot roguelite that grows a
large feature surface quickly, SRP at every layer is the primary defence
against tangled code.

### II. Data-Driven Content

All game-balance and content configuration MUST live in JSON files under `res://data/`.
Hard-coded numeric constants for enemy stats, skill values, dungeon parameters, or
upgrade costs inside `.gd` scripts are prohibited.

- GDScript data models in `res://scripts/data_models/` MUST provide typed wrappers
  (e.g., `EnemyData`, `SkillData`, `UpgradeData`) over the raw JSON; scripts MUST
  consume data models, never raw dictionaries from parsed JSON.
- When a new content category is added, the JSON schema MUST be defined before
  any GDScript implementation begins.
- The data layer MUST remain engine-agnostic enough that values can be tuned
  without reopening the Godot editor.

**Rationale**: Separating content from code accelerates iteration and enables
non-programmer contributors to tune balance without touching GDScript.

### III. Mobile-First Performance

Every feature MUST be evaluated against mobile hardware constraints before
implementation is considered complete.

- The game MUST sustain 60 fps on a mid-range Android device (target baseline:
  Snapdragon 665-class or equivalent).
- All shaders and materials MUST be authored for the Mobile renderer profile
  (D3D12 on Windows dev machines; Vulkan on Android target). Effects requiring
  the Forward+ renderer are prohibited.
- Physics MUST use the Jolt physics engine. Godot's built-in physics bodies or
  shapes MUST NOT be introduced unless confirmed compatible with the Jolt backend.
- Draw calls, overdraw, and texture memory MUST be considered for every visual
  feature; sprite atlases are preferred over individual textures.

**Rationale**: The game targets mobile; retrofitting performance after the fact
is expensive. Catching constraint violations per-feature prevents compounding debt.

### IV. Editor-Centric Workflow

The Godot 4.6 Editor is the single source of truth for scene and node hierarchy.

- Scene files (`.tscn`) MUST NOT be edited as raw text. All structural changes
  to scenes MUST be made through the Godot Editor.
- Git operations MUST use the godot-git-plugin (in-editor) or the standard Git
  CLI. Force-pushing to `main` is prohibited.
- Export builds MUST be produced exclusively via the Editor's Export menu.
  No external build scripts that modify project files are permitted.
- Binary assets (`.import` sidecar files) MUST be committed alongside their
  source assets; `.import` files MUST NOT be in `.gitignore`.
- **Node references**: GDScript MUST use `@export var name: Type` (assigned via
  the Godot Inspector) for any child-node reference that is part of a
  configurable scene. Hardcoded `$NodeName` path literals that impose a naming
  constraint on Editor builders are prohibited. `$NodeName` paths are permitted
  only when the node name is architecturally fixed within the script's own
  scene subtree and documented as such (e.g., `$MovementComponent` inside
  `Player.tscn` where the component name is defined by convention).

**Rationale**: Raw `.tscn` edits produce fragile diffs and break editor
integrity. Centralising all scene work in the editor keeps the repository
consistent and reviewable. Hardcoded node-name paths couple scripts to a
specific scene layout, preventing Editor builders from naming nodes freely and
making refactors unnecessarily brittle.

### V. Simplicity & YAGNI

Complexity MUST be justified by a concrete, present requirement — not a
speculative future one.

- An abstraction (base class, utility, shared resource) MUST NOT be introduced
  until at least two concrete call sites require it.
- Features outside the current run's scope MUST be deferred; placeholder nodes
  or stub scripts acting as "future hooks" are prohibited.

**Rationale**: Roguelite games grow feature-rich quickly. Premature abstraction
and speculative infrastructure are the primary sources of technical debt here.

## Technology Stack

- **Engine**: Godot 4.6 (GDScript; no C# unless explicitly decided)
- **Renderer**: Mobile (D3D12 on Windows, Vulkan on Android)
- **Physics**: Jolt (via Godot-Jolt addon)
- **Target Platform**: Android mobile (portrait 1080×1920); Windows used for
  development only
- **Scripting**: GDScript exclusively; static typing (`var x: int`) MUST be used
  for all script variables, parameters, and return types; string interpolation
  MUST use `String.format()` with named keys (e.g.,
  `"id={id} mode={mode}".format({"id": run_id, "mode": run_mode})`) — `%`
  specifiers are prohibited
- **Version Control**: Git via godot-git-plugin + CLI; branch per feature

## Development Workflow

1. **Feature scoping** — Use the speckit workflow (`/speckit.specify` →
   `/speckit.plan` → `/speckit.tasks`) to produce a spec, plan, and task list
   before any code is written.
2. **Constitution gate** — Every plan MUST pass the Constitution Check (verify
   Principles I–V) before Phase 0 research begins.
3. **Scene-first** — Create the scene hierarchy in the Godot Editor first;
   attach single-responsibility component scripts second; wire signals third.
4. **Data-first for content** — Define or extend the relevant JSON schema in
   `res://data/` before writing any GDScript that consumes it.
5. **Incremental commits** — Commit after each logical unit (scene created,
   component wired, data model implemented). Use the godot-git-plugin or CLI;
   never amend published commits on `main`.
6. **Review gate** — All PRs MUST confirm: SRP is respected at every layer
   (scripts, scenes, autoloads), no hard-coded balance values, shader is
   Mobile-compatible, and all child-node references use `@export var` rather
   than hardcoded `$NodeName` paths (Principle IV).

## Governance

This constitution supersedes all informal conventions and ad-hoc decisions.
Conflicts between this document and any other guideline are resolved in favour
of the constitution.

**Amendment procedure**:
1. Author proposes change in a dedicated branch with a revised constitution draft.
2. Rationale and migration plan MUST be documented in the PR description.
3. `LAST_AMENDED_DATE` and `CONSTITUTION_VERSION` MUST be updated per the
   semantic versioning policy below.
4. All dependent templates (`.specify/templates/`) MUST be reviewed for impact
   and updated in the same PR.

**Versioning policy**:
- MAJOR: Removal or incompatible redefinition of an existing principle.
- MINOR: New principle or section added; materially expanded guidance.
- PATCH: Clarifications, wording refinements, typo fixes.

**Compliance**: Every feature plan's "Constitution Check" section MUST explicitly
affirm compliance with each of the five principles (or document a justified
exception). Non-compliant plans MUST NOT proceed to implementation.

**Runtime guidance**: Refer to `CLAUDE.md` for day-to-day development context
(folder conventions, scene structure, autoload registry). `CLAUDE.md` MUST stay
consistent with this constitution; if they conflict, this constitution governs.

---

**Version**: 1.2.0 | **Ratified**: 2026-02-19 | **Last Amended**: 2026-02-27
