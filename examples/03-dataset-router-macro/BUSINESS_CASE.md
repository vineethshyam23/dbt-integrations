# Business case — dataset / project routers

## Problem

Large dbt projects on BigQuery usually split physical location by layer:
staging views in one dataset, intermediate builds in another, marts and
snapshots in a third — often across separate prod and dev GCP projects.
Without shared routers:

- snapshot configs hardcode project IDs and drift when a project is renamed
- dbt's default `{target.schema}_{custom}` naming dumps everything into a
  nested sandbox that does not match IAM / cost attribution boundaries
- a wrong `target_schema` on a snapshot writes SCD history into the wrong
  dataset; cleanup is slow and scary

## Decision

Ship two complementary macros:

1. **`generate_database_name`** — resolve the GCP project from `target.name`
   (or an explicit override). Used heavily by snapshots that must set
   `target_database`.
2. **`set_schema`** — resolve the dataset from model-name prefix (`stg_` /
   `int_` / else) and runner env vars, with an optional explicit override.
3. **`generate_schema_name` override** — stop concatenating schema names so
   `schema="staging"` means dataset `staging`.

## Business impact

- **Blast radius:** project and dataset decisions live in two files. Renaming a
  warehouse project is a macro edit + PR, not a 200-file search/replace.
- **Cost attribution:** sibling datasets map cleanly to BigQuery dataset-level
  labels / budgets. Nested `{user}_{layer}` schemas fight FinOps dashboards.
- **Safety:** missing `DBT_*_SCHEMA` env vars fail the run on prod/dev instead
  of silently writing next to an analyst's sandbox tables.

## When not to use this

- Single-dataset prototypes where dbt's default concat is fine.
- Mesh setups that already route via packages / project variables — pick one
  convention; do not stack three routers.
- Cases where every model needs a unique dataset — pass
  `custom_schema_name` explicitly and treat the prefix table as a default only.
