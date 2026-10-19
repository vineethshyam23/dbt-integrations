{{
    config(
        enabled=true,
        schema="intermediate",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["message_id"],
        full_refresh=false,
        on_schema_change="append_new_columns",
        cluster_by=["venue_id", "publish_time", "message_id"],
        tags=["marketplace", "intermediate", "venues"],
    )
}}

{#
  Typed venue intermediate: schema-spec drives the SELECT list.

  project_nested_json expands marketplace_venue_schema() into SAFE JSON
  extracts + casts (including nested STRUCT / ARRAY). Broker columns stay
  outside the spec so watermarks and merge keys are explicit.
#}

with src as (
    select
        message_id,
        publish_time,
        data
    from {{ ref('stg_marketplace_venues') }}
    {% if is_incremental() %}
    where publish_time > timestamp_sub(
        (
            select coalesce(
                max(publish_time),
                timestamp('1970-01-01 00:00:00 UTC')
            )
            from {{ this }}
        ),
        interval 1 hour
    )
    {% endif %}
),

parsed as (
    select
        message_id,
        publish_time,
        safe.parse_json(data) as payload
    from src
)

select
    {{ project_nested_json('payload', marketplace_venue_schema()) }},
    message_id,
    publish_time
from parsed
