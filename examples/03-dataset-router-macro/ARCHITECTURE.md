# Architecture — dataset / materialization routers

## Component view

```mermaid
flowchart TB
  subgraph Inputs
    TGT["target.name\n(default | dev | prod)"]
    NAME["model / snapshot name\nprefix: stg_ | int_ | other"]
    ENV["Env vars\nDBT_STG_SCHEMA\nDBT_INT_SCHEMA\nDBT_MARTS_SCHEMA"]
    OVR["Optional overrides\ncustom_database_name\ncustom_schema_name"]
  end

  subgraph Macros
    DB["generate_database_name"]
    SCH["set_schema"]
    GEN["generate_schema_name\n(literal dataset, no concat)"]
  end

  subgraph BigQuery
    PROJ["Project\nyour-gcp-project\nor your-gcp-project-dev"]
    DS["Dataset\nstaging | intermediate | marts"]
    REL["Relation\nview / table / snapshot"]
  end

  TGT --> DB
  OVR --> DB
  DB --> PROJ

  NAME --> SCH
  TGT --> SCH
  ENV --> SCH
  OVR --> SCH
  SCH --> DS

  GEN --> DS
  PROJ --> REL
  DS --> REL
```

## Snapshot wiring

```mermaid
flowchart LR
  STG["stg_crm_accounts\nschema=staging via generate_schema_name"]
  SNAP["crm_account_snapshot"]
  DBM["generate_database_name()"]
  SSM["set_schema(custom_schema_name='marts',\nmodel_name='crm_account_snapshot')"]
  OUT["your-gcp-project.marts.crm_account_snapshot"]

  STG -->|ref| SNAP
  DBM --> SNAP
  SSM --> SNAP
  SNAP --> OUT
```

## Design notes

- `set_schema` is for **explicit** configs (snapshots, rare one-offs). Day-to-day
  models usually rely on `dbt_project.yml` folder `+schema` plus the
  `generate_schema_name` override.
- Database routing and schema routing are intentionally separate macros so you
  can override one without the other.
- Prefix detection uses the first `_`-split token only (`stg_crm_accounts` →
  `stg`). Keep naming conventions boring.
