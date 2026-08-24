# Intermediate enrichment join (CRM activities)

Take a thin CRM activity staging view and **left-join** account / user / task
dimensions to publish one coalesced `external_id` for ERP sync and activity
marts. Enrichment lives in intermediate — not in staging, not in every
consumer query.

## Why it exists

CRM activity extracts know CRM-internal ids. Downstream systems need a stable
external account key. Spreading that join logic across sync jobs and BI models
produces divergent coalesce orders and accidental PII pulls (mailbox fields,
bodies). One intermediate table owns attribution.

## File index

| Path | Role |
|------|------|
| `models/_crm__sources.yml` | CRM sources used by staging + enrichment |
| `models/stg_crm_activities.sql` | Thin staging view (ids + flags) |
| `models/int_crm_activities_enriched.sql` | Left-join enrichment + `external_id` |
| `models/schema.yml` | Grain docs + not_null / warn tests |
| `BUSINESS_CASE.md` | Reliability / cost / privacy rationale |
| `ARCHITECTURE.md` | Mermaid component + join topology |
| `DATA_FLOW.md` | Build path and fallback order |

## How to run (conceptually)

1. Point `_crm__sources.yml` at your CRM landing dataset / tables.
2. `dbt run --select stg_crm_activities int_crm_activities_enriched`
3. `dbt test --select int_crm_activities_enriched`
4. Wire consumers to `ref('int_crm_activities_enriched')` — do not re-join
   account dims in every mart.

Measure orphan rate (`external_id is null`) before flipping warn → error on
the test.

## Sanitization notes

- GCP project / dataset names → `your-gcp-project`, `staging`, `intermediate`.
- Salesforce / Odoo-specific names → generic `crm` sources and models.
- Mailbox addresses, HTML bodies, and author emails removed; enrichment keeps
  ids, flags, and external uids only.
- Custom field names like `UID__c` → `external_uid`.
- Shape follows an internal CRM activity enrichment intermediate (staging
  activities + left joins to account / user / task with coalesced external
  key). Company ticket refs and product codes stripped.

## Tradeoffs

**Pros:** one attribution contract; left joins preserve facts; table materialization
amortizes join cost for sync consumers.

**Cons:** rebuild cost grows with activity volume — incrementalize the staging
layer first if daily full rebuilds get expensive; coalesce order is a product
decision, document it or consumers will fight you.
