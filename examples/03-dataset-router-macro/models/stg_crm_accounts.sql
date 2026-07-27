{{
    config(
        enabled=true,
        schema="staging",
        materialized="view",
        tags=["crm", "staging"],
    )
}}

{#
  Minimal staging stub so the snapshot example has a ref() target.
  In a real project this would be examples/02-staging-with-tests (or your
  own source-backed staging). generate_schema_name makes schema="staging"
  land as dataset `staging`, not `{target.schema}_staging`.
#}

select
    cast(null as string) as account_id,
    cast(null as string) as account_status,
    cast(null as string) as segment_code,
    cast(null as string) as country_code,
    cast(null as timestamp) as registered_at,
    cast(null as timestamp) as last_modified_at
where false
