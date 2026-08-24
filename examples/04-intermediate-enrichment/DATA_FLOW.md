# Data flow — intermediate enrichment

## Build path

1. Ingestion lands CRM extracts into `your-gcp-project.staging`
   (`crm_activities`, `crm_account`, `crm_user`, `crm_task`).
2. `dbt run --select stg_crm_activities` builds the thin staging view
   (rename + distinct, no dimension joins).
3. `dbt run --select int_crm_activities_enriched` materializes the
   enrichment table:
   - left join user on `created_by_id`
   - left join account on `related_to_id` (skip soft-deleted)
   - left join task on `activity_id`
   - left join person-account on `task.who_id = person_contact_id`
4. `external_id` is coalesced in one expression and tested (warn if null).
5. Downstream sync / marts `ref('int_crm_activities_enriched')`.

## Fallback order for `external_id`

| Priority | Source | When it wins |
|----------|--------|--------------|
| 1 | `acc.external_uid` | Activity related directly to an account |
| 2 | `act.related_to_id` | Related object id exists but account uid missing |
| 3 | `acc_who.external_uid` | Attribution only via task → person contact |

If all three are null, leave `external_id` null. Do not invent keys in the
mart — that hides unmatched activity volume.

## Failure modes to watch

| Symptom | Likely cause |
|---------|----------------|
| Row count >> staging | Task or account join fans out; add `distinct` or tighten keys |
| High null `external_id` rate | Related ids point at non-account objects; check task path |
| Soft-deleted accounts still enrich | Dropped the `is_deleted = false` predicate on account joins |
| Sync rejects related_to_id values | Fallback #2 returned a CRM-internal id; prefer uid-only coalesce |

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| Warehouse project | `your-gcp-project` |
| Staging dataset | `staging` |
| Intermediate dataset | `intermediate` |
| Source system | `crm` |
| Upstream pattern shape | CRM activities + account/task enrichment |
