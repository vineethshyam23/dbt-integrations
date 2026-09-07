# Architecture — snapshot / SCD current-row filter

## Components

```mermaid
flowchart LR
  subgraph Source["Raw / landing"]
    SRC["source crm.crm_product"]
  end

  subgraph Staging["dbt staging"]
    STG["stg_crm_product\nrename + drop test rows"]
  end

  subgraph Snapshot["dbt snapshot"]
    SNAP["crm_product_snapshot\ncheck strategy\ndbt_valid_from / dbt_valid_to"]
  end

  subgraph Intermediate["dbt intermediate"]
    INT["int_crm_product\nall versions\n_valid_flag reshape"]
  end

  subgraph Current["Consumer surface"]
    CUR["crm_product_current\nwhere _valid_flag = true"]
  end

  subgraph Consumers["Consumers"]
    BI["BI / pricing joins"]
    AUD["audit / as-of queries"]
  end

  SRC --> STG
  STG --> SNAP
  SNAP --> INT
  INT --> CUR
  CUR --> BI
  INT --> AUD
```

## SCD version windows

```mermaid
flowchart TB
  subgraph Versioning["Per product_id over time"]
    V1["v1: valid_from T0\nvalid_to T1\n_valid_flag false"]
    V2["v2: valid_from T1\nvalid_to null\n_valid_flag true"]
  end

  SNAP2["crm_product_snapshot"] --> V1
  SNAP2 --> V2
  V1 --> INT2["int_crm_product keeps both"]
  V2 --> INT2
  V2 --> CUR2["crm_product_current\ncurrent tip only"]
```

## Design notes

- **Staging stays dumb.** No SCD flags in staging — freshness and renames only.
- **Snapshot is the change detector.** `strategy='check'` + `check_cols='all'`
  is the right default for small catalogs; it is the wrong default for
  clickstream.
- **Intermediate keeps history.** Mapping `dbt_valid_to is null` →
  `_valid_flag` is fine; filtering those rows away here is not.
- **Current is a view by default.** Catalog tips are small; a view avoids a
  second storage copy. Materialize as a table only when scan cost or
  permission boundaries require it.
- **Tests encode grain.** Unique on `product_id` belongs on the current
  model, not on the intermediate history table.
