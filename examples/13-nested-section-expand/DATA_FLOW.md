# Data flow — nested section expand

## Happy path

1. Landing receives Pub/Sub rows (`message_id`, `publish_time`, `data`).
2. `stg_marketplace_menus` parses `data` → JSON, keeps `@type = menu`.
3. `int_marketplace_menu_sections` on incremental runs applies a
   publish_time watermark with a one-hour lookback.
4. `menu_section_expansion_ctes('parsed')` builds `_ms_numbered`:
   root sections walked, descendants emitted with parent id and ordinal.
5. `enrich_menu_section_json` copies menu envelope fields onto each
   section JSON (`menuId`, `parentMenuSectionId`, …).
6. `project_nested_json(..., marketplace_menu_section_schema())` produces
   typed columns; `row_id` hashes message + section + parent + ordinal.
7. Merge on `row_id`. Cluster by `menu_id`, `section_id`, `row_id`.

## Failure modes

| Symptom | Likely cause | What to check |
|---------|--------------|---------------|
| Missing deep leaves | Nesting deeper than `max_depth` | Raise depth or fix publisher |
| Root rows appear | Caller selected `_ms_roots` instead of `_ms_numbered` | Use the numbered CTE only |
| `parent_menu_section_id` null on first level | Root missing `@id` / `id` | Quarantine upstream; do not invent |
| Duplicate `row_id` on republish | Ordinal / parent drift between versions | Fixture the tree; keep sort_key stable |
| Unit test row order mismatch | Expect list not ordered by emission | Match `parent_sort_key`, `sibling_offset` |

## Watermark note

Same pragmatic default as pattern 12: one-hour lookback for streaming
redelivery. Tighten if merges are cheap; widen if publishers backfill older
`publish_time` into the subscription.

## Relation to adjacent patterns

| Pattern | Boundary |
|---------|----------|
| 11 Resource router + error sink | Routes / quarantines; does not flatten trees |
| 12 Nested JSON project | Types one resource row per message |
| **13 Nested section expand** | Fan-out nested sections → section grain, then project |
