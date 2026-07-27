# Dataset / materialization router macros

Two small Jinja helpers that decide **which BigQuery project and dataset** a
model or snapshot writes to — without baking GCP project IDs into every config
block.

| Macro | Job |
|-------|-----|
| `generate_database_name` | Pick prod vs dev project (or honor an override) |
| `set_schema` | Pick dataset from model-name prefix + env vars |
| `generate_schema_name` / `default__generate_schema_name` | Make `schema=` configs literal dataset names |

## Why it exists

In a multi-dataset BigQuery warehouse, dbt's default behavior concatenates
`{target.schema}_{custom}`. That is fine for personal sandboxes; it is wrong
when `staging`, `intermediate`, and `marts` are sibling datasets. Snapshots make
it worse: they need an explicit `target_database` / `target_schema`, so teams
paste project IDs into hundreds of configs.

These macros centralize that routing. Prefix conventions (`stg_`, `int_`) plus
env vars keep CI / Airflow runners in control of physical locations.

## File index

| Path | Role |
|------|------|
| `../../macros/generate_database_name.sql` | Project / database router |
| `../../macros/set_schema.sql` | Prefix + env dataset router + schema-name override |
| `models/stg_crm_accounts.sql` | Stub staging view (shows literal `schema="staging"`) |
| `snapshots/crm_account_snapshot.sql` | Snapshot using both routers |
| `BUSINESS_CASE.md` | Cost / blast-radius rationale |
| `ARCHITECTURE.md` | Mermaid routing diagram |
| `DATA_FLOW.md` | Decision path by target + prefix |

## How to run (conceptually)

1. Drop the macros into your project's `macros/` folder.
2. Set runner env vars for prod/dev:

   ```bash
   export DBT_STG_SCHEMA=staging
   export DBT_INT_SCHEMA=intermediate
   export DBT_MARTS_SCHEMA=marts
   ```

3. Profiles: `prod` and `dev` targets; `default` falls back to `target.schema`.
4. Replace `your-gcp-project` / `your-gcp-project-dev` inside
   `generate_database_name` with real project IDs (do not commit those back here).
5. `dbt snapshot --select crm_account_snapshot` (after pointing the stub staging
   model at a real source).

## Sanitization notes

- Real GCP project IDs (`hd-dwh-stream-*`) → `your-gcp-project` /
  `your-gcp-project-dev`.
- Company trusted / landing dataset names → generic `staging` / `intermediate` /
  `marts`.
- Snapshot source renamed to generic CRM; no PII columns.
- Verbose `log()` noise from production macros trimmed; behavior kept.
- Env var for the non-stg/int bucket renamed to `DBT_MARTS_SCHEMA` (was a
  company-specific refined schema name).

## Tradeoffs

**Pros:** one place to change project IDs; snapshots stay readable; sibling
datasets work without fighting dbt's default concat.

**Cons:** prefix rules are a convention — rename a model from `stg_` to
something else and it silently lands in marts unless you pass
`custom_schema_name`. Missing env vars fail at runtime on prod/dev (by design;
fail loud rather than write to the wrong dataset).
