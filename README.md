# dbt Integrations

Sanitized dbt reference patterns from enterprise BigQuery data platform work.

This is a **portfolio / learning repo**, not a clone of any company project. All project IDs, datasets, and business names use placeholders.

---

## Scope

| Layer | What you'll find |
|-------|------------------|
| **Staging** | Source-aligned models with tests |
| **Intermediate** | Business logic and joins |
| **Marts** | Consumer-facing tables |
| **Macros** | Reusable SQL helpers |
| **Contracts** | Model contracts / expectations |
| **Style guide** | Team SQL/YAML conventions |

---

## Structure

```
dbt-integrations/
├── dbt_project.yml
├── dbt-styleguide.md
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
├── macros/
├── tests/
├── contracts/
├── examples/          # Small end-to-end pattern samples
└── docs/              # Non-architecture docs and runbooks
```

---

## Placeholder rules

| Production | Portfolio |
|------------|-----------|
| `hd-dwh-stream-1` | `your-gcp-project` |
| Company datasets | `staging` / `refined` / `marts` |
| Real source systems | Generic names (`crm`, `erp`, `payments`) |

Never commit real credentials, service accounts, or customer data.

---

## Contribution rule

Pattern work lands on a descriptive feature branch, then merges to `main` via PR:

```text
feature/dbt-<nn>-<short-descriptive-slug>
```

Example: `feature/dbt-01-incremental-filter`

---

## Related repos

- [airflow-patterns](https://github.com/vineethshyam23/airflow-patterns) — orchestration patterns
- [api-integrations](https://github.com/vineethshyam23/api-integrations) — GCP API Gateway / Apigee / Cloud Run
- [data-platform-portfolio](https://github.com/vineethshyam23/data-platform-portfolio) — architecture and impact

---

## Patterns shipped

| # | Pattern | Location |
|---|---------|----------|
| 01 | Incremental filter macro (`get_filter_val`) | [`examples/01-incremental-filter/`](examples/01-incremental-filter/) |
| 02 | Staging model + tests YAML (CRM accounts) | [`examples/02-staging-with-tests/`](examples/02-staging-with-tests/) |
| 03 | Dataset / materialization router macro | [`examples/03-dataset-router-macro/`](examples/03-dataset-router-macro/) |
| 04 | Intermediate enrichment join (CRM activities) | [`examples/04-intermediate-enrichment/`](examples/04-intermediate-enrichment/) |
| 05 | Mart with model contract (ERP invoices) | [`examples/05-mart-with-contract/`](examples/05-mart-with-contract/) |
| 06 | Snapshot / SCD current-row filter (CRM products) | [`examples/06-snapshot-scd-current/`](examples/06-snapshot-scd-current/) |

See [`docs/PATTERN_BACKLOG.md`](docs/PATTERN_BACKLOG.md) for Done / Next.

## Status

Six patterns shipped. Further examples land one per weekly run (sanitized excerpts only).
