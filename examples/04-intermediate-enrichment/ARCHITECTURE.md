# Architecture — intermediate enrichment join

## Components

```mermaid
flowchart LR
  subgraph Landing["CRM landing / staging"]
    ACT["stg_crm_activities\nids + flags only"]
    ACC["crm.crm_account"]
    USR["crm.crm_user"]
    TSK["crm.crm_task"]
  end

  subgraph Intermediate["dbt intermediate"]
    ENR["int_crm_activities_enriched\nLEFT JOIN dims\ncoalesce external_id"]
  end

  subgraph Consumers["Downstream"]
    ERP["ERP / CRM sync preview"]
    MART["activity marts"]
  end

  ACT --> ENR
  ACC --> ENR
  USR --> ENR
  TSK --> ENR
  ENR --> ERP
  ENR --> MART
```

## Join topology

```mermaid
flowchart TB
  ACT["stg_crm_activities"]
  USR["crm_user\non created_by_id"]
  ACC["crm_account\non related_to_id"]
  TSK["crm_task\non activity_id"]
  WHO["crm_account (person)\non task.who_id = person_contact_id"]
  KEY["external_id =\ncoalesce(related_account_uid,\nrelated_to_id,\nwho_account_uid)"]

  ACT -->|left join| USR
  ACT -->|left join| ACC
  ACT -->|left join| TSK
  TSK -->|left join| WHO
  ACC --> KEY
  ACT --> KEY
  WHO --> KEY
```

## Design notes

- **Left joins** preserve every activity row. Orphans show up as null
  `external_id` (warn-severity test) instead of silent row loss.
- **Fallback order** is intentional: prefer the stable account uid, then the
  raw related id, then the person-account path via task. Change that order in
  one model, not in five consumers.
- **Staging stays thin.** Body text and mailbox addresses are out of scope for
  this pattern; pull them from a restricted store only if a product feature
  truly needs them.
- Materialization is a **table** because enrichment is join-heavy and reused.
  Switch to a view only if the upstream dims are tiny and rebuild cost is
  negligible.
