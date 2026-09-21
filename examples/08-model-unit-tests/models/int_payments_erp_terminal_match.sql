{{
    config(
        enabled=true,
        schema="intermediate",
        materialized="view",
        tags=["payments", "terminals"],
    )
}}

{#
  Stub upstream match grain for the reassignment audit.

  In production this is the ERP lot ↔ establishment ↔ payments
  merchant/store target mapping. Unit tests override this ref with
  inline rows — the stub only needs a stable column set so the graph
  compiles.
#}

select
    cast(null as string) as company_id,
    cast(null as string) as merchant_id,
    cast(null as string) as store_id,
    cast(null as string) as establishment_uid,
    cast(null as string) as terminal_id,
    cast(null as boolean) as to_disable_standalone_tip,
    cast(null as date) as create_date,
    cast(null as timestamp) as lot_create_timestamp,
    cast(null as int64) as lot_id
where false
