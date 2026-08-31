# Data flow — mart with model contract

## Build path

1. Snapshot / SCD history lands as `erp_invoices_history` (or your trusted
   history relation) with `dbt_valid_from` / `dbt_valid_to`.
2. `dbt run --select int_erp_invoices` reshapes history into typed validity
   columns (`_update_ts`, `_valid_from`, `_valid_to`, `_valid_flag`).
3. `dbt run --select mart_erp_invoices` publishes **current** lines only
   (`where _valid_flag = true`).
4. `dbt test --select mart_erp_invoices` checks `not_null`,
   `accepted_values`, and (when you flip it) contract type enforcement.
5. Export / finance consumers read `ref('mart_erp_invoices')` — not the
   intermediate history table.

## Grain

| Layer | Grain | Notes |
|-------|-------|-------|
| History | invoice line version | Multiple rows per line over time |
| Intermediate | same + validity flags | SCD reshape; keep all versions |
| Mart | current invoice line | Filter `_valid_flag = true` |

Business keys for the consumer contract:
`erp_line_id`, `erp_invoice_id`, `product_code`.

Uniqueness on that grain may still be deferred if upstream SCD leaves
duplicates — call that out in contract meta instead of pretending the mart
is unique.

## Contract lifecycle

| Stage | `contract.enforced` | What you verify |
|-------|---------------------|-----------------|
| Draft | `false` | Docs, types declared, tests run as soft signal |
| Soft launch | `false` + CI monitoring | Type mismatches logged; no hard fail yet |
| Enforced | `true` | `dbt build` fails on type / missing-column drift |

Freshness windows on `_update_ts` should match the real daily load SLA
(example: warn 36h / error 48h), not an aspirational SLO.

## Failure modes to watch

| Symptom | Likely cause |
|---------|----------------|
| Contract fail after ERP upgrade | Column type changed upstream; update YAML + notify consumers |
| `accepted_values` fail on payment_status | New status code shipped without enum update |
| Export row count collapses | `_valid_flag` filter too aggressive or history gap |
| Duplicate business keys in mart | Deferred uniqueness; fix intermediate SCD before enforcing unique |

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| Warehouse project | `your-gcp-project` |
| Intermediate dataset | `intermediate` |
| Marts dataset | `marts` |
| Source system | `erp` |
| Consumer | `export-platform` / `finance` |
| Upstream pattern shape | refined invoice mart + dbt YAML contract |
