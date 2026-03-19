# Research: Relic Deck Count

## Decision 1: How to integrate `deck_count` into the existing deck system

**Decision**: Keep `_all_by_tier` as a **unique** list (one `RelicData` per relic) and add a `_build_expanded_deck(tier, exclude_id)` helper that expands each relic `deck_count` times when constructing or refilling the per-tier draw deck.

**Rationale**:
- `_all_by_tier` is used in two places: deck refilling in `_draw_one_from_tier`, and boss offer construction in `draw_boss_offer`. Boss offers must use the *unique* pool (no duplicates) — so `_all_by_tier` must stay de-duplicated.
- Expanding at deck-build time (not storage time) keeps the source-of-truth clean: one `RelicData` object per relic, and the deck is a view that reflects frequency.
- The helper is called in three sites: initial `build_pool`, deck refill in `_draw_one_from_tier`, and the de-dup refill inside `draw_offer`. Extracting it as a method avoids duplicated expansion logic.

**Alternatives considered**:
- Store expanded entries directly in `_all_by_tier` — rejected because `draw_boss_offer` iterates `_all_by_tier` expecting unique relics; it would produce duplicate boss offers.
- Use a separate `_expanded_by_tier` dictionary alongside `_all_by_tier` — rejected as unnecessary complexity; a helper function achieves the same result with less state.

---

## Decision 2: Default value for `deck_count` in `RelicData`

**Decision**: `deck_count: int = 1`. Any relic missing the field in JSON gets count 1 (appears once in the pool).

**Rationale**: A default of 1 is the most conservative fallback — the relic stays available but is not artificially boosted. This also makes `deck_count` backward-compatible if the field is absent for any reason.

**Alternatives considered**:
- Default 0 (disable relic if field missing) — too aggressive; would silently break relics during development.
- No default (treat missing as error) — rejected in favour of graceful degradation per Constitution V.

---

## Decision 3: Impact on `sharp_edge` → `common_damage` rename

**Decision**: Pure data change. No `.gd` files reference `sharp_edge` at runtime (confirmed by codebase search — only appears in `data/relics.json` and historical spec documents). Update `relics.json` key only; no code changes required for the rename.

**Rationale**: Grep confirmed zero runtime script references to `sharp_edge`. The rename is therefore zero-risk.

---

## Decision 4: `deck_count` applicability to boss offers

**Decision**: `deck_count` does **not** influence boss relic offers. `draw_boss_offer` draws from the unique `_all_by_tier["rare"]` list and returns up to 3 non-held relics. No expansion is applied.

**Rationale**: Boss offers are curated one-off events, not weighted draws. Applying `deck_count` there would bias which rare relics show up in a context where the player should see the breadth of options.
