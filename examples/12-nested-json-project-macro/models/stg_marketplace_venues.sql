{{
    config(
        enabled=true,
        schema="staging",
        materialized="view",
        tags=["marketplace", "staging", "venues"],
    )
}}

{#
  Thin venue filter in front of the nested JSON projector.

  Production usually routes in a shared staging model (pattern 11). This
  view stands alone for the teaching path: keep venue resources and the
  raw JSON string so the intermediate owns parse + projection.
#}

with src as (
    select
        message_id,
        publish_time,
        data,
        safe.parse_json(data) as payload
    from {{ source('marketplace_events', 'marketplace_events_raw') }}
)

select
    message_id,
    publish_time,
    data
from src
where payload is not null
  and lower(json_value(payload, '$."@type"')) = 'venue'
