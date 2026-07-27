# Data flow — dataset / project routing

## Model run (`schema=` / folder `+schema`)

1. dbt resolves the model config (`schema="staging"` or folder default).
2. `generate_schema_name` → `default__generate_schema_name` returns the custom
   name as-is (no `{target.schema}_` prefix).
3. Relation lands in `target.database.staging.<model>` unless
   `generate_database_name` is also wired via `+database` / snapshot config.

## Snapshot run (`target_database` + `target_schema`)

1. `generate_database_name()`:
   - `target.name == prod` → `your-gcp-project`
   - `target.name == dev` → `your-gcp-project-dev`
   - else → profile `target.database`
   - explicit `custom_database_name` wins on prod/dev
2. `set_schema(custom_schema_name=..., model_name=...)`:
   - if `custom_schema_name` set → use it
   - else branch on prefix (`stg` / `int` / other) and, for prod/dev, read the
     matching `DBT_*_SCHEMA` env var
3. Snapshot writes SCD history to `{database}.{schema}.{snapshot_name}`.

## Decision table

| target | custom DB | custom schema | prefix | Resulting project | Resulting dataset |
|--------|-----------|---------------|--------|-------------------|-------------------|
| prod | none | none | `stg_` | `your-gcp-project` | `$DBT_STG_SCHEMA` |
| prod | none | `marts` | other | `your-gcp-project` | `marts` |
| dev | none | none | `int_` | `your-gcp-project-dev` | `$DBT_INT_SCHEMA` |
| default | none | none | any | profile default | `target.schema` |
| prod | override | none | `stg_` | override | `$DBT_STG_SCHEMA` |

## Failure modes to watch

| Symptom | Likely cause |
|---------|----------------|
| `Env var required but not provided: 'DBT_STG_SCHEMA'` | Runner missing env; set before `dbt run` / `dbt snapshot` |
| Tables appear as `dev_staging` instead of `staging` | `generate_schema_name` override not loaded (wrong `macro-paths`) |
| Snapshot in wrong project after rename | Macro constants not updated; search only the macro, not every snapshot |
| `stg_` model lands in marts | Name does not start with `stg_`, or override custom schema missing |

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| Prod GCP project | `your-gcp-project` |
| Dev GCP project | `your-gcp-project-dev` |
| Staging / intermediate / marts datasets | `staging` / `intermediate` / `marts` |
| Example feed | CRM accounts |
