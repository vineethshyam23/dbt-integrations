{{
    config(
        enabled=true,
        schema="intermediate",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["country_code", "account_id"],
        on_schema_change="sync_all_columns",
        tags=["crm", "incremental"],
    )
}}

{#
  Sanitized intermediate pattern: current SCD rows from a snapshot feed,
  merged incrementally using the shared watermark macro.

  Grain: one row per (country_code, account_id) for the current valid version.
#}

with current_accounts as (

    select
        country_code,
        account_id,
        account_status,
        segment_code,
        registered_at,
        last_modified_at,
        scd_id as _hash_id,
        dbt_updated_at as _updated_at,
        dbt_valid_from as _valid_from,
        dbt_valid_to as _valid_to,
        case when dbt_valid_to is null then true else false end as _valid_flag
    from {{ ref("crm_account_snapshot") }}
    where dbt_valid_to is null

)

select *
from current_accounts

{% if is_incremental() %}
where date(_updated_at) >= {{ get_filter_val(model_name=this, column="_updated_at") }}
{% endif %}
