# Architecture — staging with tests and freshness

## Components

```mermaid
flowchart LR
  subgraph Ingestion
    LOAD["CRM extract / load job\nwrites landing table"]
  end

  subgraph dbt_source["dbt source: crm"]
    SRC["crm.crm_account\nfreshness on _update_ts\nwarn 12h / error 24h"]
  end

  subgraph dbt_staging["dbt staging"]
    STG["stg_crm_accounts\nview: rename + filter test rows\ntests: unique/not_null"]
  end

  subgraph Downstream
    INT["intermediate / marts\nref('stg_crm_accounts')"]
  end

  LOAD --> SRC
  SRC --> STG
  STG --> INT
```

## Test and freshness placement

```mermaid
flowchart TB
  subgraph Source_layer["Source YAML"]
    F["source freshness\nloaded_at_field = _update_ts"]
    ST["source column tests\nid: not_null + unique"]
  end

  subgraph Model_layer["Model YAML"]
    MT["stg_crm_accounts tests\naccount_id: not_null + unique\ncountry_code / created_at: not_null"]
  end

  subgraph Runtime["dbt commands"]
    SF["dbt source freshness"]
    DT["dbt test --select stg_crm_accounts"]
    DR["dbt run --select stg_crm_accounts"]
  end

  F --> SF
  ST --> DT
  MT --> DT
  DR --> DT
```

## Design notes

- Staging stays a **view** so it always mirrors the latest landing extract
  without storing a second full copy.
- Freshness lives on the **source**, not the model — it measures ingestion lag,
  not dbt run success.
- Model tests protect the **contract** downstream models rely on (key uniqueness
  after the test-data filter).
- Do not put enrichment joins here; that is the intermediate layer's job.
