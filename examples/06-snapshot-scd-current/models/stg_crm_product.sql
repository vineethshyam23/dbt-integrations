{{
  config(
    schema='staging',
    materialized='view',
    tags=['crm', 'staging', 'product'],
  )
}}

{#
  Thin staging over the CRM product source.

  Keep this boring: rename, cast, drop test rows. Do not invent SCD logic
  here — that belongs in the snapshot + intermediate layers.
#}

with product as (

    select
        id as product_id,
        product_code,
        name as product_name,
        is_active,
        created_date as created_at,
        system_modstamp,
        coalesce(is_test_data, false) as is_test_data
    from {{ source('crm', 'crm_product') }}
    where coalesce(is_test_data, false) = false

)

select
    product_id,
    product_code,
    product_name,
    is_active,
    created_at,
    system_modstamp
from product
