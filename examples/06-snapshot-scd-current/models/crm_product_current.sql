{{
  config(
    schema='marts',
    materialized='view',
    tags=['crm', 'product', 'current'],
  )
}}

{#
  Current-row consumer surface.

  One place owns "give me today's catalog". Downstream BI / pricing joins
  should ref this view, not the snapshot or the full SCD intermediate.
#}

select
    product_id,
    product_code,
    product_name,
    is_active,
    created_at,
    system_modstamp,
    _sourcesystem,
    _updated_at,
    _valid_from,
    _valid_to,
    _valid_flag
from {{ ref('int_crm_product') }}
where _valid_flag = true
