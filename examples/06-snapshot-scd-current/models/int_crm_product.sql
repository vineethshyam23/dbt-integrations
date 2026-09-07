{{
  config(
    schema='intermediate',
    materialized='table',
    tags=['crm', 'product', 'scd'],
  )
}}

{#
  SCD reshape: keep ALL snapshot versions and expose a boolean current flag.

  Do not filter dbt_valid_to IS NULL here. Filtering in this layer silently
  drops history and breaks any consumer that needs as-of joins or audits.
  Current-row publishing belongs in the next model.
#}

with scd as (

    select
        product_id,
        product_code,
        product_name,
        is_active,
        created_at,
        system_modstamp,
        'etl_crm' as _job_name,
        'crm' as _sourcesystem,
        current_timestamp() as _create_ts,
        cast(null as timestamp) as _update_ts,
        0 as _job_id,
        -- legacy consumers sometimes expect a sentinel end date for current
        -- rows; keep both the raw dbt_valid_to and a coalesced _valid_until
        coalesce(
            dbt_valid_to,
            timestamp('2099-12-31 00:00:00')
        ) as _valid_until,
        dbt_scd_id as _hash_id,
        dbt_updated_at as _updated_at,
        dbt_valid_from as _valid_from,
        dbt_valid_to as _valid_to,
        case
            when dbt_valid_to is null then true
            else false
        end as _valid_flag
    from {{ ref('crm_product_snapshot') }}

)

select *
from scd
