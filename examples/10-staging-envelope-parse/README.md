# Staging envelope parse + unit test (CMS events)

Thin staging view over a Pub/Sub → BigQuery landing table. Promotes envelope
discriminator fields with `json_value` / `json_query`, and pins the parse
with a dbt `unit_tests:` fixture so CI does not scan the streaming table.

## Why it exists

Streaming landings are broker envelopes, not business tables. Every typed
intermediate that re-parses `$.type` and `$.timestamp` from raw `data` will
eventually disagree after a publisher change. One staging view owns the
paths; one unit test owns the regression proof.

This is deliberately separate from the audit-style unit-test pattern
(`08-model-unit-tests`): here the fixture protects **JSON envelope parsing**,
not branching eligibility logic.

## File index

| Path | Role |
|------|------|
| `models/_cms_events__sources.yml` | Placeholder Pub/Sub landing source |
| `models/stg_cms_events_raw.sql` | Envelope parse view |
| `models/schema.yml` | Column tests + one `unit_tests:` block |
| `BUSINESS_CASE.md` | Cost / reliability rationale |
| `ARCHITECTURE.md` | Mermaid component + parse placement |
| `DATA_FLOW.md` | Build path, failure modes, incremental note |

## How to run (conceptually)

1. Point `_cms_events__sources.yml` at your real Pub/Sub BigQuery
   subscription table (same column shape: `data`, `message_id`,
   `publish_time`, …).
2. Copy `stg_cms_events_raw.sql` + `schema.yml` into your staging path.
3. Adjust `accepted_values` for your real envelope `type` strings.
4. `dbt run --select stg_cms_events_raw`
5. `dbt test --select stg_cms_events_raw`
   (schema + unit tests together on current dbt-core)
6. Optionally: `dbt test --select "test_type:unit"` for unit tests only

Requires a dbt-core version that supports native `unit_tests:` in YAML.

## Sanitization notes

- GCP project / datasets → `your-gcp-project`, `staging`.
- Product / subscription names → generic `cms_events` / `cms-events-bq`.
- Producer-specific ID-mapping type label → generic `IdMapping`.
- Fixture establishment id → `est_demo_001`; no real customer payloads.
- Ticket / request identifiers from source comments dropped.
- Dataset router macros from production config stripped; example uses a
  plain `schema="staging"` config.

## Tradeoffs

**Pros:** parse contract is explicit; unit tests are fast; typed models stop
duplicating JSON paths; warn-level `accepted_values` soft-lands new types.

**Cons:** unit tests do not prove publisher schema drift against live data —
pair with periodic sampled integration checks. Soft-warn means unknown
types still flow until someone reads the warn; escalate to error once the
type set is stable.
