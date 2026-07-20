{{
    config(
        enabled=true,
        schema="staging",
        materialized="view",
        tags=["crm", "staging"],
    )
}}

{#
  Thin staging view over the CRM account source.

  Pattern goals:
  - declare the source once (see _crm__sources.yml) with freshness
  - expose a stable column set for intermediate / marts
  - drop obvious test rows early so tests and joins stay clean

  Grain: one row per account_id (after distinct + test-data filter).
#}

with account as (

    select distinct
        id as account_id,
        is_deleted,
        name as account_name,
        record_type_id,
        country_code,
        account_source,
        channel_code,
        created_at,
        system_modstamp,
        is_test_data,
        _create_ts,
        _update_ts
    from {{ source("crm", "crm_account") }}
    where coalesce(is_test_data, false) = false

)

select *
from account
