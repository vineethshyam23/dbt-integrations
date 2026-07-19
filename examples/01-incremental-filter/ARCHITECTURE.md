# Architecture — incremental filter macro

## Components

```mermaid
flowchart LR
  subgraph Source
    SNAP["crm_account_snapshot\n(SCD / valid_to null)"]
  end

  subgraph dbt_run["dbt run (incremental)"]
    MACRO["get_filter_val\nrun_query max(date(col))\non {{ this }}"]
    MODEL["int_crm_accounts_incremental\nmerge on country_code + account_id"]
  end

  subgraph Target
    TBL["intermediate.int_crm_accounts_incremental"]
  end

  SNAP --> MODEL
  TBL -. "watermark read" .-> MACRO
  MACRO --> MODEL
  MODEL -->|merge| TBL
```

## Compile vs execute

```mermaid
sequenceDiagram
  participant dbt as dbt
  participant Macro as get_filter_val
  participant BQ as BigQuery

  dbt->>Macro: render (is_incremental = true)
  alt execute = false (parse / docs)
    Macro-->>dbt: '1970-01-01'
  else execute = true
    Macro->>BQ: SELECT coalesce(max(date(_updated_at)), date('1970-01-01')) FROM target
    BQ-->>Macro: watermark date
    Macro-->>dbt: 'YYYY-MM-DD'
  end
  dbt->>BQ: SELECT ... WHERE date(_updated_at) >= 'YYYY-MM-DD' MERGE into target
```

## Design notes

- The macro does **not** own merge keys or SCD logic — only the watermark literal.
- Partition pruning still depends on the target being partitioned/clustered on
  something compatible with `_updated_at` or the merge key; the macro alone does
  not create partitions.
- Full refresh skips the macro path because `is_incremental()` is false.
