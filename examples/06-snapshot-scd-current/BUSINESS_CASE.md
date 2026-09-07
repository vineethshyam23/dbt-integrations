# Business case — snapshot / SCD current-row filter

## Problem

Product catalogs and other dimensions look static until a rename, deactivation,
or SKU merge lands mid-week. Without SCD you get one of two failure modes:

1. **Overwrite-only staging** — yesterday's name is gone; finance and pricing
   cannot reconcile what the catalog looked like at invoice time.
2. **Current-only "history" tables** — someone filters `dbt_valid_to is null`
   when building the trusted table, so the warehouse *claims* to be SCD but
   only stores the tip of each key. Audits and as-of joins fail quietly.

BI teams then fork local copies, or ask engineering to "just add a flag",
and you end up with three slightly different definitions of "current".

## Decision

Use dbt snapshots for Type 2 history, then split responsibilities:

- **Snapshot** owns change detection (`strategy='check'`, `unique_key`).
- **Intermediate** keeps every version and maps dbt SCD columns to a stable
  `_valid_from` / `_valid_to` / `_valid_flag` contract.
- **Current view / mart** filters `_valid_flag = true` for everyday joins.

Do not collapse history early. If a legacy consumer needs a sentinel end date
(`2099-12-31`), coalesce it as `_valid_until` without deleting closed rows.

## Business impact

- **Reliability:** pricing and entitlement joins always have a single current
  grain; history remains available for dispute and audit windows.
- **Cost:** check-all on a small catalog is cheap; you avoid full-table
  rebuilds of marts that only need today's products.
- **Governance:** uniqueness tests match the real grain — unique on
  `product_id` in current, unique on `_hash_id` in history — so CI catches
  SCD bugs instead of papering over them.

## When not to use this

- High-churn event facts — prefer incremental merge + partition prune, not
  check-all snapshots.
- Columns you do not care to version — put them outside `check_cols` or use
  a timestamp strategy on a true `updated_at`.
- PII-heavy person entities — same SCD shape works, but restrict column
  exposure and retention under your privacy controls (see staging pattern 02).
