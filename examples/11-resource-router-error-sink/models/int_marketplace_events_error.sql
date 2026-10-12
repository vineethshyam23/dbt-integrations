{{
    config(
        enabled=true,
        schema="intermediate",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["message_id"],
        full_refresh=false,
        on_schema_change="append_new_columns",
        tags=["marketplace", "monitoring", "events"],
    )
}}

{#
  Incremental quarantine for malformed / unsupported marketplace messages.

  Classifies rows already routed to `error` (or with unparseable timestamps)
  so ops can inspect without blocking typed intermediate models.
  Watermark on publish_time with a 1h lookback to absorb late duplicates.
#}

with src as (
    select
        message_id,
        publish_time,
        subscription_name,
        data,
        raw_resource,
        resource,
        is_valid,
        source_timestamp_raw,
        source_timestamp,
        order_date_raw,
        order_date,
        fulfillment_expires_at_raw,
        fulfillment_expires_at
    from {{ ref('stg_marketplace_events_raw') }}
    {% if is_incremental() %}
    where publish_time > timestamp_sub(
        (
            select coalesce(max(publish_time), timestamp('1970-01-01 00:00:00 UTC'))
            from {{ this }}
        ),
        interval 1 hour
    )
    {% endif %}
),

classified as (
    select
        message_id,
        publish_time,
        subscription_name,
        data,
        raw_resource,
        case
            when not is_valid then 'invalid_json'
            when resource = 'error' then 'unsupported_resource'
            when (
                (source_timestamp_raw is not null and source_timestamp is null)
                or (order_date_raw is not null and order_date is null)
                or (
                    fulfillment_expires_at_raw is not null
                    and fulfillment_expires_at is null
                )
            ) then 'invalid_timestamp'
        end as error_reason
    from src
)

select *
from classified
where error_reason is not null
