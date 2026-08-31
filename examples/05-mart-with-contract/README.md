# Mart with model contract (ERP invoices)

Publish a **current-row finance mart** behind a dbt model contract: typed
columns, accepted-value tests, and SLA / ownership meta in the same YAML
that drives `dbt build`.

## Why it exists

Export platforms and finance teams treat marts as APIs. Without `data_type`,
`accepted_values`, and a written change policy, type drift and enum sprawl
show up as 3am export failures. The mart SQL stays thin; the contract file
is the consumer surface.

## File index

| Path | Role |
|------|------|
| `models/erp_invoices_history.sql` | Ephemeral stub for SCD / snapshot feed |
| `models/int_erp_invoices.sql` | Intermediate validity reshape |
| `models/mart_erp_invoices.sql` | Current-row mart (`_valid_flag = true`) |
| `models/schema.yml` | Model contract + column types + meta SLA |
| `BUSINESS_CASE.md` | Reliability / cost / governance rationale |
| `ARCHITECTURE.md` | Mermaid component + contract surface |
| `DATA_FLOW.md` | Build path, grain, contract lifecycle |

## How to run (conceptually)

1. Replace `erp_invoices_history` with your snapshot or trusted SCD table.
2. `dbt run --select int_erp_invoices mart_erp_invoices`
3. `dbt test --select mart_erp_invoices`
4. Keep `contract.enforced: false` until types and enums are stable in CI.
5. Flip `enforced: true` after consumer sign-off; treat further type changes
   as breaking (14-day notice in the meta change policy).

## Sanitization notes

- GCP project / dataset names → `your-gcp-project`, `intermediate`, `marts`.
- ERP / export product names → generic `erp`, `export-platform`, `finance`.
- Removed internal ticket keys, job ids, schema ids, private wiki URLs,
  owner emails, and real team handles.
- Partner tax id kept as a typed column with a sensitivity note — no sample
  values.
- Shape follows an internal refined invoice mart with a draft dbt YAML
  contract (`contract.enforced: false` + `meta.data_contract`).

## Tradeoffs

**Pros:** one file owns types, enums, and human SLA; export failures move
left into `dbt build`; change policy is versioned with the model.

**Cons:** enforcing too early creates CI noise during ERP schema churn;
deferred uniqueness must be honest in the docs or consumers will assume a
grain you cannot yet guarantee.
