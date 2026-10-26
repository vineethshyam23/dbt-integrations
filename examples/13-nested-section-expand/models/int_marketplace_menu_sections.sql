{{
    config(
        enabled=true,
        schema="intermediate",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["row_id"],
        full_refresh=false,
        on_schema_change="append_new_columns",
        cluster_by=["menu_id", "section_id", "row_id"],
        tags=["marketplace", "intermediate", "menu_sections"],
    )
}}

{#
  Nested hasMenuSection trees → one row per descendant section.

  Flow: watermark → parse → menu_section_expansion_ctes → enrich JSON with
  parent/envelope → project_nested_json through marketplace_menu_section_schema.
  Root sections are walked for parenting but not emitted (streaming unnest
  parity). Merge key hashes message + section + parent + emission ordinal.
#}

with src as (
    select
        message_id,
        publish_time,
        data
    from {{ ref('stg_marketplace_menus') }}
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
),

{{ menu_section_expansion_ctes('parsed') }},

enriched as (
    select
        message_id,
        publish_time,
        parent_menu_section_id,
        emission_ordinal,
        section_json,
        {{ enrich_menu_section_json() }} as enriched_json
    from _ms_numbered
)

select
    {{ project_nested_json('enriched_json', marketplace_menu_section_schema()) }},
    to_hex(md5(concat(
        message_id, '|menu_section|',
        coalesce({{ json_node_id('section_json') }}, ''), '|',
        coalesce(parent_menu_section_id, ''), '|',
        cast(emission_ordinal as string)
    ))) as row_id,
    message_id as source_message_id,
    message_id,
    publish_time
from enriched
