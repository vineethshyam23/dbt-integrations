# Resource router + error sink (marketplace events)

Mixed Pub/Sub → BigQuery landing for several resource shapes. Staging parses
JSON once, routes `@type` into a stable `resource` bucket, and an incremental
error model quarantines invalid / unsupported messages with reason codes.

## Why it exists

Pattern 10 shows a thin envelope parse with a unit-tested discriminator.
This pattern covers the next production constraint: **one subscription, many
resource types**, plus a place for bad messages that must not enter marts.

Typed intermediates filter on `resource`. Ops queries
`int_marketplace_events_error` by `error_reason`. CI proves routing and
classification with mocked unit tests — no scan of the streaming table.

## File index

| Path | Role |
|------|------|
| `models/_marketplace_events__sources.yml` | Placeholder Pub/Sub landing source |
| `models/stg_marketplace_events_raw.sql` | Resource-router staging view |
| `models/int_marketplace_events_error.sql` | Incremental quarantine sink |
| `models/schema.yml` | Column tests + unit tests (router + sink) |
| `../../macros/parse_flexible_timestamp.sql` | Safe string / epoch-millis timestamp parse |
| `BUSINESS_CASE.md` | Cost / reliability rationale |
| `ARCHITECTURE.md` | Mermaid router + quarantine diagrams |
| `DATA_FLOW.md` | Build path, failure modes, watermark note |

## How to run (conceptually)

1. Point `_marketplace_events__sources.yml` at your real Pub/Sub BigQuery
   subscription table (columns: `data`, `message_id`, `publish_time`, …).
2. Copy the two models + `schema.yml` into your project; ensure
   `parse_flexible_timestamp` is on the macro path.
3. Adjust the `resource` CASE allow-list and `accepted_values` for your
   real `@type` strings.
4. `dbt run --select stg_marketplace_events_raw int_marketplace_events_error`
5. `dbt test --select stg_marketplace_events_raw int_marketplace_events_error`
6. Optionally: `dbt test --select "test_type:unit"` for unit tests only

Requires a dbt-core version that supports native `unit_tests:` in YAML and
macro overrides (`is_incremental`) in those tests.

## Sanitization notes

- GCP project / datasets → `your-gcp-project`, `staging`, `intermediate`.
- Product / stream names → generic `marketplace_events`.
- Resource labels → `order`, `venue`, `menu`, `service`, `disabledservice`
  (no company product codenames).
- Timestamp macro renamed → `parse_flexible_timestamp`.
- Ticket / exception comments from source YAML dropped.
- Dataset-router macros from production config stripped; examples use plain
  `schema=` configs.
- Fixtures use synthetic `msg-*` ids and demo timestamps only.

## Tradeoffs

**Pros:** one parse contract; typed models stay simple filters; quarantine
gives reason-coded volume; unit tests cover router + watermark without
warehouse cost.

**Cons:** allow-list CASE must be updated when publishers add types — until
then volume lands in `unsupported_resource`. Defaulting null `@type` to
`order` is stream-specific; do not copy that default blindly to a stream
where null means "broken".
