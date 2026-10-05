# Architecture — staging envelope parse with unit test

## Components

```mermaid
flowchart LR
  subgraph Ingestion
    PUB["CMS / listing publisher"]
    PS["Pub/Sub topic + subscription"]
    LAND["BigQuery landing\ncms_events_raw\ndata JSON + message_id"]
  end

  subgraph dbt_source["dbt source: cms_events"]
    SRC["source cms_events.cms_events_raw\nbroker columns kept"]
  end

  subgraph dbt_staging["dbt staging"]
    STG["stg_cms_events_raw\nview: json_value / json_query\nmsg_type + payload"]
    UT["unit_tests:\nstg_cms_events_raw_parses_event"]
  end

  subgraph Downstream
    INT["intermediate by msg_type\nEvent / BusinessUnit / IdMapping"]
  end

  PUB --> PS --> LAND --> SRC --> STG
  UT -.->|mocks source rows| STG
  STG --> INT
```

## Parse vs unit-test placement

```mermaid
flowchart TB
  subgraph Model_SQL["stg_cms_events_raw.sql"]
    JV["json_value data $.type → msg_type"]
    JO["json_value data $.operation"]
    JT["timestamp json_value $.timestamp → envelope_ts"]
    JP["json_query data $.payload → payload"]
  end

  subgraph Model_YAML["schema.yml"]
    AV["accepted_values on msg_type\nseverity: warn"]
    KEY["unique + not_null on message_id"]
    UNIT["unit_tests given/expect\nEvent fixture"]
  end

  subgraph Runtime["dbt commands"]
    RUN["dbt run --select stg_cms_events_raw"]
    TEST["dbt test --select stg_cms_events_raw"]
  end

  JV --> AV
  JO --> UNIT
  JT --> UNIT
  JP --> RUN
  KEY --> TEST
  UNIT --> TEST
  RUN --> TEST
```

## Design notes

- Staging is a **view** over the streaming landing table so parse logic
  always mirrors the latest subscription write without a second full copy.
- Unit tests prove the **JSON paths**, not grain. Keep `unique` / `not_null`
  on `message_id` for production load integrity.
- `accepted_values` on `msg_type` is **warn** so a new envelope type does not
  page the whole pipeline before intermediate models are ready.
- Do not unpack nested payload fields here; that is the typed intermediate
  layer's job after filtering on `msg_type`.
