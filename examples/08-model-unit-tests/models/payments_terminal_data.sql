{{
    config(
        enabled=true,
        schema="marts",
        materialized="view",
        tags=["payments", "terminals"],
    )
}}

{#
  Stub current payments-provider terminal assignment row.

  Production usually filters an SCD / refined table to _valid_flag = true.
  Unit tests inject merchant_id / store_id / terminal_id directly.
#}

select
    cast(null as string) as terminal_id,
    cast(null as string) as merchant_id,
    cast(null as string) as store_id
where false
