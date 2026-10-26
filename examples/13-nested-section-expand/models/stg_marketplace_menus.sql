{{
    config(
        enabled=true,
        schema="staging",
        materialized="view",
        tags=["marketplace", "staging", "menus"],
    )
}}

{#
  Menu-only staging in front of the section expander.

  Production often shares a resource router (pattern 11). This view stands
  alone for the teaching path: keep menu resources and the raw JSON string
  so the intermediate owns parse + expand + project.
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
  and lower(json_value(payload, '$."@type"')) = 'menu'
