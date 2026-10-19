# Nested JSON project / schema-spec macro

Typed intermediates over nested marketplace JSON without hand-writing eighty
`json_value` / `json_query` calls. A schema-spec list drives
`project_nested_json`; one intermediate per resource stays a short SELECT.

## Why it exists

Pattern 10 parses a thin envelope. Pattern 11 routes mixed `@type` values and
quarantines bad messages. After that you still need **typed columns** —
nested address structs, cuisine arrays, alias keys like `@id` vs `id` —
without copying BigQuery JSON path SQL into every model.

Production maintains a schema-spec (often generated from a legacy table
export) and a recursive projector. When publishers add a field, you update
the spec once; every resource model that shares the macro picks it up.

## File index

| Path | Role |
|------|------|
| `../../macros/project_nested_json.sql` | Recursive JSON → typed column projector |
| `../../macros/marketplace_venue_schema.sql` | Teaching venue schema-spec |
| `../../macros/parse_flexible_timestamp.sql` | TIMESTAMP scalar cast (pattern 11) |
| `models/_marketplace_events__sources.yml` | Placeholder landing source |
| `models/stg_marketplace_venues.sql` | Venue filter + parse |
| `models/int_marketplace_venues.sql` | Incremental typed projection |
| `models/schema.yml` | Column tests + unit test fixture |
| `BUSINESS_CASE.md` | Cost / maintainability rationale |
| `ARCHITECTURE.md` | Mermaid projector + schema diagrams |
| `DATA_FLOW.md` | Build path, aliases, incremental note |

## How to run (conceptually)

1. Copy `project_nested_json.sql` and a resource schema macro into your
   project's `macros/`. Ensure `parse_flexible_timestamp` is available for
   TIMESTAMP fields.
2. Point `_marketplace_events__sources.yml` at the real landing table (or
   `ref` the shared router staging from pattern 11 and drop the thin filter).
3. Add one schema-spec macro per resource (`order`, `menu`, …) — keep PII
   out of teaching / portfolio copies.
4. `dbt run --select stg_marketplace_venues int_marketplace_venues`
5. `dbt test --select stg_marketplace_venues int_marketplace_venues`
6. Optionally: `dbt test --select "test_type:unit"`

## Sanitization notes

- GCP project / datasets → `your-gcp-project`, `raw_marketplace`, `staging`,
  `intermediate`.
- Product / stream names → generic `marketplace_events` / `venue`.
- Macros renamed to generic `project_nested_json` + `marketplace_venue_schema`.
- Production schema dump truncated to a teaching subset. Email, phone, and
  street-level contact fields removed.
- Dataset-router macros from production config stripped; examples use plain
  `schema=` configs.
- Unit fixture uses synthetic `venue_demo_001` / `msg-venue-001` only.

## Tradeoffs

**Pros:** one place to evolve nested shapes; aliases handle publisher drift
(`@id` / `id`); STRUCT / ARRAY types stay consistent for BI and contracts;
unit tests can assert projection without warehouse cost.

**Cons:** schema-specs can grow large — generate them, do not hand-edit a
100KB blob in a PR. Recursive macros raise compile time; keep unused resource
specs out of the hot path. `on_schema_change='append_new_columns'` avoids
breaking merges when you add fields, but dropped columns still need a
planned migration.
