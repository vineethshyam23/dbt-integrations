# Staging model + tests YAML (CRM accounts)

Thin staging view over a generic CRM account source, with **source freshness**
and **not_null / unique** tests. This is the first trusted relation for CRM
account joins — not a place for enrichment logic.

## Why it exists

Production CRM staging models are usually a view: `source()` → select columns
→ maybe `distinct` → expose to the rest of the project. The engineering value
is the **contract around that view**:

- freshness so stalled loads fail before dashboards do
- uniqueness so retries do not fan out joins
- early filter of test / sandbox rows

Without those, staging is just `select *` with nicer docs.

## File index

| Path | Role |
|------|------|
| `models/_crm__sources.yml` | Source declaration + freshness + source-column tests |
| `models/stg_crm_accounts.sql` | Staging view (rename, distinct, drop test rows) |
| `models/stg_crm_accounts.yml` | Model docs + not_null / unique tests |
| `BUSINESS_CASE.md` | Reliability / cost rationale |
| `ARCHITECTURE.md` | Mermaid component + test placement diagrams |
| `DATA_FLOW.md` | Runtime path and failure modes |

## How to run (conceptually)

1. Point `_crm__sources.yml` at your real landing dataset / table names.
2. `dbt source freshness --select source:crm` — expect warn/error based on
   `_update_ts` lag.
3. `dbt run --select stg_crm_accounts`
4. `dbt test --select stg_crm_accounts source:crm`

Wire freshness into CI or an orchestration sensor so a 24h stall pages the
ingestion owner, not the analytics consumer.

## Sanitization notes

- GCP project IDs and company datasets replaced with `your-gcp-project` /
  `staging`.
- Salesforce-style CRM account staging reduced to non-PII operational columns
  (no email, phone, mailing address, or consent fields).
- Custom `__c` field names generalized (`channel_code`, `country_code`, etc.).
- Freshness windows are teaching defaults (12h warn / 24h error); tune to your
  real load SLA.
- Shape follows internal CRM staging (thin `source()` view + YAML), with tests
  and freshness made explicit for the portfolio pattern.

## Tradeoffs

**Pros:** cheap view; clear ownership boundary between ingestion and dbt;
failures land in `dbt test` / freshness instead of silent mart skew.

**Cons:** freshness false alarms if SLAs are wrong; `distinct` hides bad loads
instead of fixing them — pair with monitoring on duplicate rates upstream when
volume grows.
