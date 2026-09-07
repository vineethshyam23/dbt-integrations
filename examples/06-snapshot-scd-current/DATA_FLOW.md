# Data flow — snapshot / SCD current-row filter

## Build path

1. Raw CRM product rows land in `source('crm', 'crm_product')`.
2. `dbt run --select stg_crm_product` exposes a stable column set and drops
   test rows.
3. `dbt snapshot --select crm_product_snapshot` compares to the prior
   snapshot state. Unchanged keys keep `dbt_valid_to` null; changed keys
   close the old version and open a new one.
4. `dbt run --select int_crm_product` copies every snapshot version and
   adds `_valid_from` / `_valid_to` / `_valid_flag` / `_valid_until`.
5. `dbt run --select crm_product_current` publishes current catalog rows
   (`where _valid_flag = true`) for everyday consumers.
6. `dbt test` checks uniqueness on the **current** grain and on
   `_hash_id` in history.

## Grain

| Layer | Grain | Notes |
|-------|-------|-------|
| Staging | one row per `product_id` | After distinct / test filter |
| Snapshot | one row per `product_id` version | Closed rows have `dbt_valid_to` set |
| Intermediate | same as snapshot | Full history + boolean flag |
| Current | one row per `product_id` | Filter `_valid_flag = true` |

## Validity rules

| Condition | Meaning |
|-----------|---------|
| `dbt_valid_to is null` | Current version |
| `dbt_valid_to is not null` | Closed / superseded version |
| `_valid_flag = true` | Same as current (boolean for joins) |
| `_valid_until = 2099-12-31` | Sentinel for legacy as-of filters |

Prefer `_valid_flag` for current filters. Prefer raw `_valid_to` (nullable)
when writing time-travel predicates so you do not accidentally include the
sentinel forever window.

## Failure modes to watch

| Symptom | Likely cause |
|---------|----------------|
| Current view has duplicate `product_id` | Snapshot unique_key wrong or hard-delete handling misconfigured |
| Intermediate row count equals current | History filtered too early (`dbt_valid_to is null` in int) |
| Snapshot grows every run with no real changes | Non-deterministic staging (e.g. `current_timestamp` in checked cols) |
| Check strategy too slow | Catalog too wide / high churn — move to timestamp strategy |
| Freshness errors on source | CRM extract late; fix ingest before blaming SCD |

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| Warehouse project | `your-gcp-project` |
| Raw dataset | `raw_crm` |
| Staging / intermediate / marts | `staging` / `intermediate` / `marts` |
| Source system | `crm` |
| Entity | product catalog |
| Upstream shape | CRM product snapshot + refined SCD + trusted current view |
