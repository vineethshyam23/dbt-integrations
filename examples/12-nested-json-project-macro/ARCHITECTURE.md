# Architecture — nested JSON project / schema-spec

## Components

```mermaid
flowchart LR
  subgraph Landing
    RAW["marketplace_events_raw\nPub/Sub JSON body"]
  end

  subgraph Staging
    STG["stg_marketplace_venues\nparse + venue filter"]
  end

  subgraph Specs
    SPEC["marketplace_venue_schema()\nname / type / mode / aliases"]
  end

  subgraph Macros
    PROJ["project_nested_json\nrecursive projector"]
    TS["parse_flexible_timestamp\nTIMESTAMP scalars"]
  end

  subgraph Intermediate
    INT["int_marketplace_venues\ntyped STRUCT / ARRAY columns"]
  end

  subgraph Consumers
    MART["marts / contracts\njoin on venue_id"]
  end

  RAW --> STG --> INT
  SPEC --> PROJ
  TS --> PROJ
  PROJ --> INT
  INT --> MART
```

## Projector decision tree

```mermaid
flowchart TD
  F["field from schema-spec"] --> M{"mode / type"}
  M -->|REPEATED + RECORD| A["UNNEST json_query_array\n→ array of struct"]
  M -->|REPEATED scalar| B["UNNEST json_value_array\n→ array of scalar"]
  M -->|RECORD| C["json_query null check\n→ STRUCT children"]
  M -->|scalar| D["json_value + cast\nSTRING / INT / FLOAT / BOOL / TIMESTAMP"]
  D --> E{"aliases?"}
  E -->|yes| F2["COALESCE paths"]
  E -->|no| G["single path"]
```

## Alias and path handling

```mermaid
sequenceDiagram
  participant Pub as Publisher JSON
  participant Spec as marketplace_venue_schema
  participant Proj as project_nested_json
  participant Int as int_marketplace_venues

  Pub->>Proj: {"@id":"venue_demo_001", "partnerId":"..."}
  Spec->>Proj: venue_id aliases [@id, id]
  Spec->>Proj: partner_id path partnerId
  Proj->>Proj: COALESCE json_value paths
  Proj->>Int: venue_id, partner_id, address STRUCT, ...
  Note over Int: message_id + publish_time outside the spec
```

## Design notes

- Schema-specs are data (lists of dicts), not SQL. Generate from a known
  BigQuery schema export when the legacy table is the source of truth.
- Broker columns (`message_id`, `publish_time`) stay outside the projector so
  merge keys and watermarks remain obvious in the model file.
- TIMESTAMP fields reuse `parse_flexible_timestamp` — string and epoch-millis
  both appear in marketplace payloads.
- Pattern 11's router can replace `stg_marketplace_venues` in a full project;
  this example keeps a thin filter so the folder runs conceptually alone.
