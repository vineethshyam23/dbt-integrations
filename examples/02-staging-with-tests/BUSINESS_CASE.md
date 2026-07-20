# Business case — staging model with tests and source freshness

## Problem

CRM extracts land in a warehouse dataset and get consumed immediately by
intermediate joins. Without an explicit staging contract you get three failure
modes:

1. **Silent staleness** — ingestion stalls overnight; marts keep building on
   yesterday's accounts until someone notices a KPI cliff.
2. **Duplicate keys** — load jobs retry or land overlapping extracts; joins
   fan out and inflate pipeline / revenue numbers.
3. **Test-row pollution** — sandbox accounts leak into production extracts and
   skew conversion metrics.

Teams often document columns in YAML but skip `unique` / `not_null` and never
wire `source freshness`. That feels fine until the first bad Monday dashboard.

## Decision

Treat staging as a **thin, tested contract** between ingestion and business
logic:

- Declare the CRM table as a dbt `source` with `loaded_at_field` + freshness
  warn/error windows.
- Expose a view (`stg_crm_accounts`) that renames keys, filters test data, and
  keeps transformations cheap (no heavy joins here).
- Enforce `not_null` + `unique` on `account_id` (and a few operational columns)
  so broken loads fail in CI / `dbt test` instead of in a mart.

## Business impact

- **Reliability:** freshness errors surface ingestion lag before analytics
  consumers trust the day.
- **Cost:** a view over landing is cheaper than rebuilding intermediate tables
  to recover from duplicate fan-out.
- **Maintainability:** reviewers check one sources file + one staging model per
  entity instead of hunting ad-hoc `select * from raw...` in marts.

## When not to use this shape

- You need SCD history in staging — put that in snapshots / intermediate, not
  the thin view.
- Freshness windows tighter than your true load SLA will page you constantly;
  set warn/error from real lag, not aspirational SLOs.
- Ultra-wide PII tables — stage only the columns downstream actually needs.
