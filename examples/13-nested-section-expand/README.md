# Nested section expand / unnest macro

Turn a nested `hasMenuSection` tree inside one menu message into a flat
section grain: parent pointer, envelope fields, deterministic emission
order — then project typed columns with `project_nested_json`.

## Why it exists

Pattern 12 types a venue (or other resource) as one row per message.
Menus are different: publishers nest sections several levels deep. Leaving
that as a REPEATED STRUCT forces every consumer to reinvent UNNEST and
parent logic. Streaming pipelines already emit a descendant-only section
fan-out; the warehouse model should match that grain so joins and SCD
keys stay stable.

`menu_section_expansion_ctes` walks roots, emits **descendants only**,
numbers rows for a merge key, and `enrich_menu_section_json` stamps
`menuId` / `parentMenuSectionId` onto the section JSON before projection.

## File index

| Path | Role |
|------|------|
| `../../macros/expand_nested_sections.sql` | JSON helpers + expansion CTEs + enrich |
| `../../macros/marketplace_menu_section_schema.sql` | Teaching section schema-spec |
| `../../macros/project_nested_json.sql` | Typed projector (pattern 12) |
| `../../macros/parse_flexible_timestamp.sql` | TIMESTAMP cast for `timestamp` |
| `models/_marketplace_events__sources.yml` | Placeholder landing source |
| `models/stg_marketplace_menus.sql` | Menu filter + raw JSON passthrough |
| `models/int_marketplace_menu_sections.sql` | Expand → enrich → project |
| `models/schema.yml` | Tests + unit fixtures |
| `BUSINESS_CASE.md` | Why flatten at the warehouse |
| `ARCHITECTURE.md` | Mermaid expand + grain diagrams |
| `DATA_FLOW.md` | Build path, root omission, watermark |

## How to run (conceptually)

1. Copy `expand_nested_sections.sql` and `marketplace_menu_section_schema.sql`
   into your project's `macros/` (projector macros from pattern 12 required).
2. Point `_marketplace_events__sources.yml` at the real landing table, or
   `ref` a shared menu staging model from pattern 11.
3. `dbt run --select stg_marketplace_menus int_marketplace_menu_sections`
4. `dbt test --select stg_marketplace_menus int_marketplace_menu_sections`
5. Optionally: `dbt test --select "test_type:unit"`

## Sanitization notes

- GCP project / datasets → `your-gcp-project`, `raw_marketplace`, `staging`,
  `intermediate`.
- Product / stream names → generic `marketplace_events` / `menu`.
- Macros renamed from production expand helpers → `json_node_id`,
  `json_children`, `menu_section_expansion_ctes`, `enrich_menu_section_json`.
- Production add-on section fan-out omitted here (same primitives; ship as
  a follow-on pattern if useful).
- Schema-spec is a teaching subset — no full item / allergen trees, no PII.
- Unit fixture uses synthetic `menu_demo_001` / `sec_*` ids only.

## Tradeoffs

**Pros:** section grain matches stream unnest handlers; parent pointers are
explicit; unit tests pin fan-out without scanning landing; incremental merge
on `row_id` absorbs republishes.

**Cons:** compile-time `max_depth` must cover the deepest real tree or you
silently drop leaves; expanding before projecting duplicates envelope fields
onto every row (storage cost); if you only need one dashboard, a single
UNNEST in the mart may be cheaper than a dedicated intermediate.
