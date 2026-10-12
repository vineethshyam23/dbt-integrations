# Architecture — resource router + error sink

## Components

```mermaid
flowchart LR
  subgraph Ingestion
    PUB["Marketplace publishers\norders / venues / menus / services"]
    PS["Pub/Sub topic + subscription"]
    LAND["BigQuery landing\nmarketplace_events_raw\ndata JSON + message_id"]
  end

  subgraph dbt_source["dbt source: marketplace_events"]
    SRC["source marketplace_events.marketplace_events_raw"]
  end

  subgraph dbt_staging["dbt staging router"]
    STG["stg_marketplace_events_raw\nview: parse_json + resource CASE\n+ parse_flexible_timestamp"]
    UT_STG["unit_tests:\nroute / invalid JSON / unknown type"]
  end

  subgraph dbt_error["dbt error sink"]
    ERR["int_marketplace_events_error\nincremental merge on message_id\nerror_reason classification"]
    UT_ERR["unit_tests:\nreasons + watermark filter"]
  end

  subgraph Downstream
    ORD["int_* where resource = order"]
    VEN["int_* where resource = venue"]
    MEN["int_* where resource = menu"]
    SVC["int_* where resource in service / disabledservice"]
  end

  PUB --> PS --> LAND --> SRC --> STG
  STG -->|resource = error or bad ts| ERR
  STG --> ORD
  STG --> VEN
  STG --> MEN
  STG --> SVC
  UT_STG -.->|mocks source| STG
  UT_ERR -.->|mocks staging + this| ERR
```

## Routing and quarantine logic

```mermaid
flowchart TB
  RAW["safe.parse_json data → payload"]
  VALID{"payload is not null?"}
  TYPE["lower json_value @type → raw_resource"]
  CASE{"resource CASE"}
  ORDER["order\nnull @type default"]
  KNOWN["venue / menu / service / disabledservice"]
  ERROR["error"]
  TS["parse_flexible_timestamp on\ntimestamp / orderDate / fulfillment.expiresAt"]
  SINK{"error_reason?"}
  IJ["invalid_json"]
  UR["unsupported_resource"]
  IT["invalid_timestamp"]
  KEEP["typed intermediates\nfilter by resource"]

  RAW --> VALID
  VALID -->|no| ERROR
  VALID -->|yes| TYPE --> CASE
  CASE -->|null| ORDER
  CASE -->|known| KNOWN
  CASE -->|else| ERROR
  ORDER --> TS
  KNOWN --> TS
  ERROR --> TS
  TS --> SINK
  SINK -->|not is_valid| IJ
  SINK -->|resource = error| UR
  SINK -->|raw ts set, parsed null| IT
  ORDER --> KEEP
  KNOWN --> KEEP
```

## Design notes

- Staging stays a **view** so the router always mirrors the latest
  subscription write; quarantine is the only materialization in this pattern.
- `full_refresh=false` on the error sink protects historical quarantine rows
  from accidental wipe during a first-of-month rebuild habit.
- Watermark lookback (1 hour) is a pragmatic late-arrival buffer, not a
  correctness proof — tune against your Pub/Sub redelivery window.
- Do not unpack nested business fields in the router; typed models own that
  after filtering on `resource`.
