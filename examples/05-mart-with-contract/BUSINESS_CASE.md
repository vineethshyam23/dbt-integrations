# Business case — mart with model contract

## Problem

Finance export jobs and BI consumers treat a mart as an API, even when nobody
wrote one down. Without an explicit contract you get:

1. **Silent type drift** — a column flips from `int64` to `string` after an
   ERP schema change; the next Avro / Parquet export fails at 03:00.
2. **Enum sprawl** — payment statuses arrive as free text; country filters
   stop matching overnight.
3. **No change process** — someone renames `net_price_eur` and three
   downstream jobs break with no notice window.

Column docs alone do not catch this. You need typed columns, accepted values,
and a published ownership / SLA block that consumers can hold you to.

## Decision

Publish the mart behind a **dbt model contract** (YAML):

- Declare `data_type` on every consumer-facing column.
- Keep `contract.enforced: false` while the draft settles; flip to `true`
  once CI proves the select matches and consumers sign off.
- Put SLA, business keys, freshness, and change policy in `meta.data_contract`
  so the same file is both dbt config and the human contract.
- Keep the mart SQL thin: filter current rows (`_valid_flag = true`) from an
  intermediate that owns SCD / history reshape.

## Business impact

- **Reliability:** export jobs fail in `dbt build` when types or enums break,
  not after the warehouse already shipped bad files.
- **Cost:** catching drift before a full-table re-export avoids expensive
  reprocessing and support thrash.
- **Governance:** breaking-change notice days and RACI live next to the model
  that actually ships the columns — not in a wiki nobody updates.

## When not to use this

- Exploratory intermediate tables with weekly schema churn — contract those
  only after the grain stabilizes.
- Enforcing `unique` on a grain that still has known SCD duplicates — document
  the deferral; do not greenwash uniqueness.
- Ultra-sensitive PII marts — still contract types, but restrict column
  exposure and handle tax ids / partner names under your privacy controls.
