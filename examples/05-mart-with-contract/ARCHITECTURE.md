# Architecture — mart with model contract

## Components

```mermaid
flowchart LR
  subgraph History["History / SCD"]
    SNAP["erp_invoices_history\nsnapshot or trusted SCD"]
  end

  subgraph Intermediate["dbt intermediate"]
    INT["int_erp_invoices\nvalidity columns\n_valid_from / _valid_to / _valid_flag"]
  end

  subgraph Mart["dbt marts"]
    MART["mart_erp_invoices\ncurrent rows only\ncontract YAML + typed columns"]
  end

  subgraph Consumers["Consumers"]
    EXP["export platform\nbulk ingest"]
    FIN["finance reporting"]
  end

  SNAP --> INT
  INT --> MART
  MART --> EXP
  MART --> FIN
```

## Contract surface

```mermaid
flowchart TB
  YML["schema.yml\ncontract.enforced: false (draft)"]
  TYPES["column data_type\nint64 / string / date / float64 / boolean"]
  TESTS["data_tests\nnot_null + accepted_values"]
  META["meta.data_contract\nSLA / RACI / change policy\nbusiness keys / freshness"]
  SQL["mart_erp_invoices.sql\nthin select + _valid_flag filter"]

  YML --> TYPES
  YML --> TESTS
  YML --> META
  SQL --> YML
```

## Design notes

- **Mart stays thin.** History reshape and SCD flags belong in intermediate.
  The mart only publishes current rows consumers should see.
- **`enforced: false` first.** Draft contracts document intent without
  breaking builds on every type mismatch. Flip to `true` after a green
  `dbt build` window and consumer sign-off.
- **Accepted values are part of the API.** Payment status and move type enums
  fail tests when upstream invents new codes — better than silent filter
  drops in finance reports.
- **Meta is the human contract.** Ownership, SLA latency, and breaking-change
  notice days live beside the columns so wiki drift cannot diverge from the
  model that actually ships.
- Materialization is a **table** because export and BI both scan the current
  grain daily; a view over a heavy intermediate would re-pay the filter cost.
