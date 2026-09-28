# Architecture — composite match-key macro

## Components

```mermaid
flowchart LR
  subgraph Landing
    RAW["raw_match.entity_match_results\nCRM id + ERP id candidates"]
  end

  subgraph Staging
    MACRO["composite_match_key\nnull-safe MD5 hex"]
    STG["stg_entity_match_results\n+ composite_key"]
  end

  subgraph Snapshot
    QUAL["QUALIFY latest per natural key"]
    SNAP["entity_match_results_snapshot\nunique_key includes composite_key"]
  end

  subgraph Consumers
    INT["intermediate / marts\njoin on composite_key"]
  end

  RAW --> STG
  MACRO --> STG
  STG --> QUAL --> SNAP
  SNAP --> INT
```

## Key composition

```mermaid
flowchart TD
  A["id_source_1 expr"] --> C["cast → string\ncoalesce → 'null'"]
  B["id_source_2 expr"] --> D["cast → string\ncoalesce → 'null'"]
  C --> E["concat with '||'"]
  D --> E
  E --> F["md5 → to_hex"]
  F --> G["composite_key"]
```

## Snapshot unique_key shape

```mermaid
sequenceDiagram
  participant Land as entity_match_results
  participant Stg as stg_entity_match_results
  participant Snap as entity_match_results_snapshot

  Land->>Stg: id_source_1, id_source_2 (nullable)
  Stg->>Stg: composite_match_key(...)
  Note over Stg: one hex column, null-safe
  Stg->>Snap: QUALIFY latest by natural key
  Snap->>Snap: unique_key = country, sources, composite_key, match_type
  Note over Snap: SCD compares source_create_ts
```

## Design notes

- Macro arguments are **expressions** (column names or SQL fragments), not
  quoted identifiers — same call shape as production matching staging.
- Staging stays a view: cheap to recompute the hash; snapshot owns history.
- Do not put raw PII into the pair — ids only. Fuzzy scores travel as
  attributes, not as part of the key.
- Dataset routers from pattern 03 are omitted so the key lesson stays
  visible; wire them if your project already uses those macros.
