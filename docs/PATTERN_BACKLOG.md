# Pattern backlog — dbt Integrations

Sanitized teaching patterns only. Never dump company `dwh/dbt` wholesale.

## Done

| # | Pattern | Folder | Branch | Shipped |
|---|---------|--------|--------|---------|
| 01 | Incremental filter macro (`get_filter_val`) | `examples/01-incremental-filter/` + `macros/get_filter_val.sql` | `feature/dbt-01-incremental-filter` | 2026-07-19 |
| 02 | Staging model + tests YAML (CRM accounts) | `examples/02-staging-with-tests/` | `feature/dbt-02-staging-with-tests` | 2026-07-20 |
| 03 | Dataset / materialization router macro | `examples/03-dataset-router-macro/` + `macros/generate_database_name.sql` + `macros/set_schema.sql` | `feature/dbt-03-dataset-router-macro` | 2026-07-27 |
| 04 | Intermediate enrichment join (CRM activities) | `examples/04-intermediate-enrichment/` | `feature/dbt-04-intermediate-enrichment` | 2026-08-24 |
| 05 | Mart with model contract (ERP invoices) | `examples/05-mart-with-contract/` | `feature/dbt-05-mart-with-contract` | 2026-08-31 |
| 06 | Snapshot / SCD current-row filter (CRM products) | `examples/06-snapshot-scd-current/` | `feature/dbt-06-snapshot-scd-current` | 2026-09-07 |
| 07 | Text-clean / normalize macro | `examples/07-text-clean-macro/` + `macros/normalize_text.sql` | `feature/dbt-07-text-clean-macro` | 2026-09-14 |

## Next candidates

| # | Pattern | Suggested folder / branch | Notes |
|---|---------|---------------------------|-------|
| 08 | Unit-test style model test pattern | `tests/` + `examples/08-model-unit-tests/` / `feature/dbt-08-model-unit-tests` | Source has dbt `unit_tests:` (e.g. payment terminal audit / CMS models) — sanitize entity IDs heavily |
| 09 | Composite / matching-engine key macro | `macros/` + `examples/09-composite-key-macro/` / `feature/dbt-09-composite-key-macro` | Source: `macros/matching_engine_id_composite_key.sql` — sanitize entity names |

## Out of scope (other automations)

- Airflow DAGs → `airflow-patterns`
- API Gateway / Apigee / Cloud Run → `api-integrations`
- BigQuery FinOps / reservations → `data-platform-portfolio`

## Rules

- One pattern per automation run.
- Feature branch → PR → main. Never commit pattern work straight to `main`.
- Sanitize project IDs, datasets, source names, and PII before commit.
