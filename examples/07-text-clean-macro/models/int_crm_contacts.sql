{{
    config(
        enabled=true,
        schema="intermediate",
        materialized="table",
        tags=["crm", "intermediate", "text-clean"],
    )
}}

{#
  Intermediate reshape:
  - normalize_text on free-text / codes (strip CR/LF + edge <br />)
  - email_hash_if_present + email_domain (no raw email in the select list)

  Grain: one row per contact_id.
#}

select
    cast(contact_id as string) as contact_id,
    cast(account_id as string) as account_id,
    {{ email_hash_if_present("email") }} as email_hashed,
    {{ email_domain("email") }} as email_domain,
    {{ normalize_text("status") }} as status,
    {{ normalize_text("note") }} as note,
    cast(updated_at as timestamp) as updated_at
from {{ ref("stg_crm_contacts") }}
