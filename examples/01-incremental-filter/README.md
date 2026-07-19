# Incremental filter macro (`get_filter_val`)

Reusable watermark helper for BigQuery incremental merges. Instead of inlining
`select max(date(_updated_at)) from {{ this }}` in every model, call one macro
so the coalesce / parse-time default stays consistent.

## Why it exists

Across a large dbt project, incremental models tend to grow small local
variants of the same watermark query. That is fine until:

- one model forgets the empty-table default and fails the first incremental run
- another filters on a timestamp while neighbors filter on a date
- compile-time vs execute-time behavior surprises people reading compiled SQL

`get_filter_val` returns a **quoted date literal** from `max(date(column))` on
the target relation (`{{ this }}` in the usual case). Models then compare:

```sql
where date(_updated_at) >= {{ get_filter_val(model_name=this, column="_updated_at") }}
```

## File index

| Path | Role |
|------|------|
| `../../macros/get_filter_val.sql` | Project macro (source of truth) |
| `models/int_crm_accounts_incremental.sql` | Sanitized incremental usage |
| `models/schema.yml` | Column docs + basic tests |
| `BUSINESS_CASE.md` | Cost / reliability rationale |
| `ARCHITECTURE.md` | Mermaid component diagram |
| `DATA_FLOW.md` | Runtime data path |

## How to run (conceptually)

1. Place `get_filter_val.sql` under your project's `macros/`.
2. Point the example model at a real snapshot / staging ref (replace
   `crm_account_snapshot`).
3. `dbt run --select int_crm_accounts_incremental` — first run is a full load
   (`is_incremental()` false). Later runs query the watermark and merge.

## Sanitization notes

- GCP project IDs and company datasets removed; schema set to `intermediate`.
- Source system renamed to generic `crm`.
- Snapshot / PII-heavy address columns not reproduced; account-level attributes only.
- Macro logic matches the internal production watermark helper, without
  environment-specific dataset routers or project IDs.

## Tradeoffs

**Pros:** one place to change default watermark behavior; safer empty-target
runs; readable models.

**Cons:** `run_query` adds a metadata round-trip per model on incremental runs;
date truncation can re-process same-day updates (usually acceptable for merge).
For high-churn event tables, prefer a lookback window or partition prune instead.
