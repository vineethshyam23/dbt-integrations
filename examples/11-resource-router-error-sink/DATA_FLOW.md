# Data flow — marketplace resource router + error sink

## Happy path

1. Publishers write marketplace events to Pub/Sub; the BigQuery subscription
   inserts into `your-gcp-project.staging.marketplace_events_raw`.
2. `dbt run --select stg_marketplace_events_raw` compiles the view:
   `safe.parse_json` → `resource` bucket + flexible timestamp columns.
3. Typed intermediate models `ref('stg_marketplace_events_raw')` and filter
   `where resource = 'order'` (or `venue` / `menu` / `service` /
   `disabledservice`) before unpacking nested JSON.
4. `dbt run --select int_marketplace_events_error` merge-increments rows with
   a non-null `error_reason`, watermarked on `publish_time`.
5. `dbt test --select stg_marketplace_events_raw int_marketplace_events_error`
   runs schema tests plus unit tests (mocked sources / refs — no landing
   table scan).

## What fails loudly

| Check | Failure meaning | Typical fix |
|-------|-----------------|-------------|
| Unit test route mismatch | `@type` casing / default-order rule changed | Update CASE + fixture together |
| Unit test error_reason mismatch | Classification order wrong | Keep invalid_json before unsupported_resource |
| Watermark unit test empty | Lookback / max(publish_time) logic broken | Re-check `timestamp_sub` interval |
| `unique` on `message_id` (error sink) | Merge unique_key not applied | Confirm incremental_strategy merge |
| Spike in `unsupported_resource` | Publisher shipped a new `@type` | Add typed model + expand CASE allow-list |

## Why quarantine is incremental

The landing table grows continuously. Rebuilding a full quarantine table every
run re-scans months of streaming partitions for a thin error slice. Merge on
`message_id` with a short lookback keeps cost bounded and still catches
redeliveries that land slightly before the prior max watermark.

## Incremental note

Staging is not incremental. The error sink owns the watermark. Typed
resource models should anti-join on `message_id` and watermark on
`publish_time` (or `source_timestamp`) against their own tables — see
pattern 01 for the filter helper.

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| Warehouse project | `your-gcp-project` |
| Landing / staging dataset | `staging` |
| Error / intermediate dataset | `intermediate` |
| Source system | `marketplace_events` |
| Landing table | `marketplace_events_raw` |
| Staging router | `stg_marketplace_events_raw` |
| Error sink | `int_marketplace_events_error` |
| Resource buckets | `order`, `venue`, `menu`, `service`, `disabledservice`, `error` |
| Timestamp helper | `parse_flexible_timestamp` |
