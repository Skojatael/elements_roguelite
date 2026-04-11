# Implementation Plan: Enemy Attack Standoff Distance

**Branch**: `079-enemy-attack-standoff` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/079-enemy-attack-standoff/spec.md`

## Summary

When a pursuing enemy reaches `attack_range - 10` units from the player it stops moving, instead of stopping at `attack_range`. This is a single arithmetic change to the pursuit stop guard in `Enemy.gd`. No data changes, no new files.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: N/A (single script edit)
**Storage**: N/A
**Testing**: GUT unit tests
**Target Platform**: Android mobile / Windows dev
**Project Type**: Single Godot project
**Performance Goals**: 60 fps mobile — change has zero performance impact (one subtraction per physics frame per enemy)
**Constraints**: None
**Scale/Scope**: One line change in one file

## Constitution Check

- **I. Single Responsibility**: ✅ Change stays entirely within `Enemy.gd`'s existing pursuit movement responsibility. No new scripts, no autoload changes.
- **II. Data-Driven Content**: ✅ `attack_range` is already sourced from `EnemyData` (from `enemies.json`). The standoff offset of 10 is a movement mechanics constant analogous to the existing `heal_radius - 20` healer standoff in the same file. It does not represent game-balance content that would be tuned by designers, so inline is acceptable. If it ever needs per-enemy tuning it can be promoted to `enemies.json` at that time (YAGNI).
- **III. Mobile-First**: ✅ Single arithmetic operation per physics tick per enemy — negligible cost.
- **IV. Editor-Centric**: ✅ No scene changes. No new node references.
- **V. Simplicity & YAGNI**: ✅ Minimal change. No abstraction introduced.
- **VI. Early Return**: ✅ The existing pursuit stop guard is already an early return. The change preserves that pattern.

## Decisions

The standoff offset (10 units) is defined as an inline constant inside `Enemy.gd`, mirroring the existing `heal_radius - 20` pattern on line 250 of the same file. The value is clamped to a minimum of 0 via `maxf` to handle hypothetical enemies whose `attack_range` is smaller than 10.

## Schema Changes

None. `attack_range` already exists in `EnemyData` and `enemies.json`. No new fields required.

## Affected Files

- **`scenes/combat/enemies/Enemy.gd`**: Change the pursuit stop condition from `dist < _data.attack_range` to `dist < maxf(0.0, _data.attack_range - 10.0)`, so the enemy halts 10 units before the outer attack radius edge. One line modified.
