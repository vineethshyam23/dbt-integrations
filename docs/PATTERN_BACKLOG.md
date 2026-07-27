# Pattern backlog — dbt Integrations

Sanitized teaching patterns only. Never dump company `dwh/dbt` wholesale.

## Done

| # | Pattern | Folder | Branch | Shipped |
|---|---------|--------|--------|---------|
| 01 | Incremental filter macro (`get_filter_val`) | `examples/01-incremental-filter/` + `macros/get_filter_val.sql` | `feature/dbt-01-incremental-filter` | 2026-07-19 |
| 02 | Staging model + tests YAML (CRM accounts) | `examples/02-staging-with-tests/` | `feature/dbt-02-staging-with-tests` | 2026-07-20 |
| 03 | Dataset / materialization router macro | `examples/03-dataset-router-macro/` + `macros/generate_database_name.sql` + `macros/set_schema.sql` | `feature/dbt-03-dataset-router-macro` | 2026-07-27 |

## Next candidates

| # | Pattern | Suggested folder / branch | Notes |
|---|---------|---------------------------|-------|
| 04 | Intermediate enrichment join | `examples/04-intermediate-enrichment/` / `feature/dbt-04-intermediate-enrichment` | Leads / enrichment style join |
| 05 | Mart with model contract | `examples/05-mart-with-contract/` / `feature/dbt-05-mart-with-contract` | Grain + contract YAML |

## Out of scope (other automations)

- Airflow DAGs → `airflow-patterns`
- API Gateway / Apigee / Cloud Run → `api-integrations`
- BigQuery FinOps / reservations → `data-platform-portfolio`

## Rules

- One pattern per automation run.
- Feature branch → PR → main. Never commit pattern work straight to `main`.
- Sanitize project IDs, datasets, source names, and PII before commit.
