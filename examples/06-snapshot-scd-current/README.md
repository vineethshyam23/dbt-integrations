# Snapshot / SCD current-row filter (CRM products)

Teach the three-layer SCD path: **staging → dbt snapshot → intermediate
history → current view**. The point is not "use snapshots"; it is keeping
history intact while giving consumers a boring current-row surface.

## Why it exists

Catalog and dimension feeds change slowly but matter a lot when they do —
price books, entitlement flags, renames. Teams that filter
`dbt_valid_to is null` inside the history table itself lose the audit trail
and cannot answer "what was active last Tuesday?".

This pattern keeps full SCD history in intermediate, then publishes a thin
current view for BI / pricing joins.

## File index

| Path | Role |
|------|------|
| `models/_crm_product__sources.yml` | Source + freshness for CRM product feed |
| `models/stg_crm_product.sql` | Thin staging (rename, drop test rows) |
| `snapshots/crm_product_snapshot.sql` | Check-strategy SCD Type 2 snapshot |
| `snapshots/crm_product_snapshot.yml` | Snapshot column docs |
| `models/int_crm_product.sql` | Full history + `_valid_flag` reshape |
| `models/crm_product_current.sql` | Current rows only (`_valid_flag = true`) |
| `models/schema.yml` | Tests: unique on current grain, not on history |
| `BUSINESS_CASE.md` | Reliability / cost rationale |
| `ARCHITECTURE.md` | Mermaid component + SCD windows |
| `DATA_FLOW.md` | Build path, grain, failure modes |

## How to run (conceptually)

1. Point `_crm_product__sources.yml` at your real CRM product table.
2. Copy the snapshot into a path listed under `snapshot-paths` in
   `dbt_project.yml` (examples here are teaching folders).
3. `dbt snapshot --select crm_product_snapshot`
4. `dbt run --select stg_crm_product int_crm_product crm_product_current`
5. `dbt test --select int_crm_product crm_product_current`

First snapshot run creates one current row per product. Later runs close
changed versions (`dbt_valid_to` set) and open new ones.

## Sanitization notes

- GCP project / dataset names → `your-gcp-project`, `staging`,
  `intermediate`, `marts`, `raw_crm`.
- CRM product entity is generic; no company product names or SKUs.
- Removed PII-heavy account/person fields (use pattern 02 for accounts).
- Shape follows an internal CRM product snapshot + refined SCD table +
  trusted current view (`where _valid_flag = true`).
- Dataset routers from pattern 03 omitted here so the SCD lesson stays
  visible; wire `generate_database_name` / `set_schema` if you already
  ship those macros.

## Tradeoffs

**Pros:** history survives; current consumers stay simple; tests encode the
right uniqueness grain (history vs current).

**Cons:** check-all snapshots re-compare every column each run — fine for
catalogs, expensive for high-churn facts; a separate current view adds one
more object to own in the DAG.
