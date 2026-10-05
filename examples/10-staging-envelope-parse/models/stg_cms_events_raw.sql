{{
    config(
        enabled=true,
        schema="staging",
        materialized="view",
        tags=["cms", "staging", "events"],
    )
}}

{#
  Thin staging view over a Pub/Sub → BigQuery landing table.

  Pattern goals:
  - keep the raw envelope columns (message_id, publish_time) for incremental
    anti-joins downstream
  - promote the few envelope fields every consumer needs (type, operation, ts)
  - leave the nested payload as JSON for typed intermediate models to unpack

  Grain: one row per message_id.
#}

select
    message_id,
    publish_time,
    subscription_name,
    data,
    json_value(data, '$.type') as msg_type,
    json_value(data, '$.operation') as operation,
    timestamp(json_value(data, '$.timestamp')) as envelope_ts,
    json_query(data, '$.payload') as payload
from {{ source('cms_events', 'cms_events_raw') }}
