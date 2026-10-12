{{
    config(
        enabled=true,
        schema="staging",
        materialized="view",
        tags=["marketplace", "staging", "events"],
    )
}}

{#
  Resource-router staging over a mixed Pub/Sub landing table.

  Pattern goals:
  - parse JSON once; promote a stable `resource` bucket for typed models
  - default null @type to `order` (orders omit the discriminator in this stream)
  - route unknown / invalid payloads to `error` so they never land in marts
  - keep broker columns for incremental watermarks and ops debugging

  Grain: one row per message_id.
#}

with src as (
    select
        message_id,
        publish_time,
        subscription_name,
        attributes,
        data,
        safe.parse_json(data) as payload
    from {{ source('marketplace_events', 'marketplace_events_raw') }}
),

enriched as (
    select
        message_id,
        publish_time,
        subscription_name,
        attributes,
        data,
        payload,
        payload is not null as is_valid,
        lower(json_value(payload, '$."@type"')) as raw_resource,
        json_value(payload, '$.timestamp') as source_timestamp_raw,
        json_value(payload, '$.orderDate') as order_date_raw,
        json_value(payload, '$.fulfillment.expiresAt') as fulfillment_expires_at_raw
    from src
)

select
    message_id,
    publish_time,
    subscription_name,
    attributes,
    data,
    payload,
    is_valid,
    raw_resource,
    case
        when not is_valid then 'error'
        when raw_resource is null then 'order'
        when raw_resource in ('venue', 'menu', 'service', 'disabledservice')
            then raw_resource
        else 'error'
    end as resource,
    source_timestamp_raw,
    {{ parse_flexible_timestamp("source_timestamp_raw") }} as source_timestamp,
    order_date_raw,
    {{ parse_flexible_timestamp("order_date_raw") }} as order_date,
    fulfillment_expires_at_raw,
    {{ parse_flexible_timestamp("fulfillment_expires_at_raw") }} as fulfillment_expires_at
from enriched
