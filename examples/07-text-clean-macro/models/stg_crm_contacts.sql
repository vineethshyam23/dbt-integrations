{{
    config(
        enabled=true,
        schema="staging",
        materialized="view",
        tags=["crm", "staging", "text-clean"],
    )
}}

{#
  Staging keeps notes readable for support tooling: newlines become <br />.
  Intermediate will strip edge artifacts with normalize_text.
#}

select
    cast(contact_id as string) as contact_id,
    cast(account_id as string) as account_id,
    lower(trim(cast(email as string))) as email,
    cast(status as string) as status,
    {{ preserve_linebreaks("note") }} as note,
    cast(updated_at as timestamp) as updated_at
from {{ source("crm", "contacts") }}
where contact_id is not null
