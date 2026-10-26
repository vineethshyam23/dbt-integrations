# Architecture — nested section expand

## Components

```mermaid
flowchart LR
  subgraph Landing
    RAW["marketplace_events_raw\nPub/Sub JSON body"]
  end

  subgraph Staging
    STG["stg_marketplace_menus\nparse + menu filter"]
  end

  subgraph Expand
    CTE["menu_section_expansion_ctes\nUNNEST hasMenuSection"]
    ENR["enrich_menu_section_json\nparent + envelope"]
  end

  subgraph Specs
    SPEC["marketplace_menu_section_schema()\nid / parent / envelope"]
  end

  subgraph Macros
    PROJ["project_nested_json\ntyped columns"]
  end

  subgraph Intermediate
    INT["int_marketplace_menu_sections\none row per descendant"]
  end

  subgraph Consumers
    MART["marts / SCD / BI\njoin on menu_id + section_id"]
  end

  RAW --> STG --> CTE --> ENR --> INT
  SPEC --> PROJ
  PROJ --> INT
  INT --> MART
```

## Expansion decision tree

```mermaid
flowchart TD
  M["menu payload"] --> R["UNNEST root hasMenuSection"]
  R --> W["walk root — do not emit"]
  W --> C["UNNEST child hasMenuSection"]
  C --> E["emit section_json + parent id"]
  E --> D{"deeper children?"}
  D -->|yes| C2["UNNEST next depth\nup to max_depth"]
  C2 --> E
  D -->|no| N["_ms_numbered\nemission_ordinal"]
  N --> J["json_set envelope\n→ project_nested_json"]
```

## Grain and merge key

```mermaid
sequenceDiagram
  participant Pub as Menu JSON
  participant Exp as menu_section_expansion_ctes
  participant Enr as enrich_menu_section_json
  participant Int as int_marketplace_menu_sections

  Pub->>Exp: hasMenuSection tree (root + children)
  Exp->>Exp: omit root, emit descendants
  Exp->>Exp: parent_menu_section_id + sort_key
  Exp->>Enr: section_json + envelope columns
  Enr->>Int: enriched_json + emission_ordinal
  Int->>Int: row_id = md5(message|section|parent|ordinal)
  Note over Int: merge unique_key = row_id
```

## Design notes

- Roots are intentional omissions: they exist so children have a parent
  id, matching streaming unnest handlers that skip top-level section
  shells.
- `path_step` zero-pads offsets so lexicographic `sort_key` order matches
  tree walk order across depths.
- `max_depth` is a compile-time guard. Raise it only when fixtures prove
  deeper nesting; every extra depth multiplies UNION ALL CTE size.
- Broker columns (`message_id`, `publish_time`) stay outside the schema-spec
  so watermarks and merge keys remain obvious in the model.
- Pattern 12's projector is reused; this folder's lesson is the expand
  CTEs, not a second projector implementation.
