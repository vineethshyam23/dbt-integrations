# Architecture — dbt model unit tests

## Components

```mermaid
flowchart LR
  subgraph Upstream["Upstream refs (mocked in unit tests)"]
    MATCH["int_payments_erp_terminal_match\nERP target merchant/store"]
    TERM["payments_terminal_data\ncurrent payments assignment"]
  end

  subgraph Intermediate["dbt intermediate"]
    AUDIT["int_payments_terminal_reassign_audit\nrank → classify → filter"]
  end

  subgraph Tests["Test surface"]
    UNIT["unit_tests:\ngiven rows + expect dict"]
    SCHEMA["data_tests:\nnot_null / accepted_values"]
  end

  subgraph Consumers["Downstream"]
    FEED["feed reader\nis_in_feed = true"]
  end

  MATCH --> AUDIT
  TERM --> AUDIT
  AUDIT --> FEED
  UNIT -.-> AUDIT
  SCHEMA -.-> AUDIT
```

## Classification branches

```mermaid
flowchart TB
  START["ranked match row\ndedupe_rank computed"]
  D1{"dedupe_rank > 1?"}
  D2{"terminal missing\nin payments?"}
  D3{"merchant match\nand store assigned?"}
  INC["feed_status =\nincluded_reassign"]
  EXD["excluded_dedupe"]
  EXM["excluded_terminal_not_in_payments"]
  EXA["excluded_merchant_assigned"]
  KEEP["keep in audit table\n(dedupe_rank = 1 AND\nnot excluded_merchant_assigned)"]
  DROP["drop from audit"]

  START --> D1
  D1 -->|yes| EXD
  D1 -->|no| D2
  D2 -->|yes| EXM
  D2 -->|no| D3
  D3 -->|yes| EXA
  D3 -->|no| INC
  EXD --> DROP
  EXA --> DROP
  EXM --> KEEP
  INC --> KEEP
```

## Design notes

- **Unit tests mock refs, not sources.** The audit model only sees two
  upstream relations; fixtures stay small and readable.
- **Empty `expect.rows` is a first-class case.** Proving a row is *absent*
  (merchant already assigned) matters as much as proving include.
- **Partial expect rows are fine.** Assert the columns that encode the
  business rule; skip `evaluated_at` and other non-deterministic fields.
- **Stub upstream models exist only for the graph.** Their SQL is
  `where false` — production replaces them with real match / refined
  selects. Unit tests never execute the stub bodies.
- Materialize the audit as a **table** when an orchestrator polls it on a
  schedule; keep stubs as views.
