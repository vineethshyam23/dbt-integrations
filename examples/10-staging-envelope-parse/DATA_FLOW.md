# Data flow — staging CMS event envelopes

## Happy path

1. Publisher writes CMS events to Pub/Sub; the BigQuery subscription inserts
   into `your-gcp-project.staging.cms_events_raw` with `data` (JSON string),
   `message_id`, and `publish_time`.
2. `dbt run --select stg_cms_events_raw` compiles the view:
   `source('cms_events', 'cms_events_raw')` → `json_value` / `json_query`
   promotions for `msg_type`, `operation`, `envelope_ts`, `payload`.
3. `dbt test --select stg_cms_events_raw` runs:
   - schema tests (`unique` / `not_null` on `message_id`, warn on unexpected
     `msg_type`)
   - unit test `stg_cms_events_raw_parses_event` against a mocked Event
     fixture (no warehouse scan of the landing table)
4. Intermediate models `ref('stg_cms_events_raw')` and filter
   `where msg_type = 'Event'` (or BusinessUnit / IdMapping) before unpacking
   `payload`.

## What fails loudly

| Check | Failure meaning | Typical fix |
|-------|-----------------|-------------|
| Unit test expect mismatch | Envelope JSON path renamed or timestamp format changed | Update staging extract + fixture together |
| `unique` on `message_id` | Duplicate Pub/Sub deliveries landed as duplicates | Dedup with QUALIFY / anti-join in incremental sinks |
| `not_null` on `message_id` / `publish_time` | Broken subscription schema | Quarantine load; fix subscription write |
| `accepted_values` warn on `msg_type` | New envelope type landed | Add typed intermediate + expand the values list |

## Why keep `data` and `payload`

`data` is the full envelope for ops debugging. `payload` is the nested object
string so typed models do not re-walk `$.payload` from the outer blob. Both
are cheap to retain on a view; materialize / unpack only what consumers need
downstream.

## Incremental note

This staging view is not incremental. Downstream incremental models should
anti-join on `message_id` and watermark on `publish_time` (or `envelope_ts`)
against their own tables — see the incremental filter pattern for the
watermark helper.

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| Warehouse project | `your-gcp-project` |
| Landing / staging dataset | `staging` |
| Source system | `cms_events` |
| Landing table | `cms_events_raw` |
| Staging model | `stg_cms_events_raw` |
| Envelope types | `Event`, `BusinessUnit`, `IdMapping` |
