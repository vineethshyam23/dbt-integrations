# Data flow — staging CRM accounts

## Happy path

1. Ingestion writes / merges rows into `your-gcp-project.staging.crm_account`
   and bumps `_update_ts`.
2. `dbt source freshness` reads `max(_update_ts)` against the warn (12h) /
   error (24h) windows defined on the `crm` source.
3. `dbt run --select stg_crm_accounts` compiles the view: `source('crm',
   'crm_account')` → distinct + rename + drop `is_test_data = true`.
4. `dbt test --select stg_crm_accounts` (and source tests) assert
   `account_id` is present and unique, plus a few operational not-nulls.
5. Intermediate models `ref('stg_crm_accounts')` — they never query the
   landing table directly.

## What fails loudly

| Check | Failure meaning | Typical fix |
|-------|-----------------|-------------|
| Source freshness error | No successful load within 24h | Fix ingestion / DAG; do not “fix” by widening windows blindly |
| `unique` on `account_id` | Duplicate keys in landing or distinct not enough | Dedup upstream, or add a quality gate before staging |
| `not_null` on `account_id` / `country_code` | Broken extract schema or null keys | Quarantine load; block downstream until schema matches |
| Empty staging after filter | Only test accounts landed | Confirm environment / filter flags |

## Why `distinct`

CRM landing extracts sometimes retry and land duplicate current rows for the
same `id`. `select distinct` is a cheap staging guard. If duplicates are
semantic (SCD versions), do **not** distinct them away — route history to a
snapshot / intermediate model instead.

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| Warehouse project | `your-gcp-project` |
| Landing / staging dataset | `staging` |
| Source system | `crm` |
| Landing table | `crm_account` |
| Staging model | `stg_crm_accounts` |
