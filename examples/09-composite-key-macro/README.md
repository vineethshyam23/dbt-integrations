# Composite match-key macro

Null-safe MD5 hex key for a pair of source identifiers. Staging materializes
`composite_key` once; snapshots and QUALIFY windows reuse it instead of
re-expressing `coalesce(cast(...))` in every unique_key list.

## Why it exists

Entity-matching jobs land candidate pairs: CRM account id on one side, ERP
partner id on the other. Downstream SCD snapshots need a stable natural key.
Inlining `concat(id_1, id_2)` breaks when either side is null, when types
differ across runs, or when `"12"||"3"` collides with `"1"||"23"`.

One macro, one separator, one null sentinel — then every model that cares
about pair identity calls the same thing.

## File index

| Path | Role |
|------|------|
| `../../macros/composite_match_key.sql` | Project macro (source of truth) |
| `models/_entity_match__sources.yml` | Placeholder CRM↔ERP match landing |
| `models/stg_entity_match_results.sql` | Staging view + `composite_key` |
| `models/schema.yml` | Column docs + not_null on key/ts |
| `snapshots/entity_match_results_snapshot.sql` | Timestamp SCD using composite_key in unique_key |
| `BUSINESS_CASE.md` | Reliability / ops rationale |
| `ARCHITECTURE.md` | Mermaid component + snapshot keying |
| `DATA_FLOW.md` | Build path, grain, failure modes |

## How to run (conceptually)

1. Drop `composite_match_key.sql` under your project's `macros/`.
2. Point `_entity_match__sources.yml` at the real match-results table.
3. Copy the snapshot into a path listed under `snapshot-paths` (examples
   here are teaching folders — not wired into this portfolio `dbt_project.yml`).
4. `dbt run --select stg_entity_match_results`
5. `dbt snapshot --select entity_match_results_snapshot`
6. `dbt test --select stg_entity_match_results`

## Sanitization notes

- GCP project / datasets → `your-gcp-project`, `raw_match`, `staging`.
- Matching-engine product name → generic `entity_match` / CRM↔ERP labels.
- Company request names, metro IDs, and long fuzzy-score column lists dropped;
  kept `match_quality`, `match_type`, `fm_mean` as representative signals.
- Macro renamed from production `matching_engine_id_composite_key` →
  `composite_match_key`. Logic unchanged: `to_hex(md5(concat(coalesce(...))))`.

## Tradeoffs

**Pros:** one null-safe definition; snapshot unique_key stays readable; pair
identity is joinable as a single string column.

**Cons:** MD5 is fine for warehouse keys, not a security boundary. Changing
the separator or null sentinel invalidates historical snapshot keys — treat
that as a breaking change and backfill, do not "just edit the macro".
