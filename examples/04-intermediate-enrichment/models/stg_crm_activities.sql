{{
    config(
        enabled=true,
        schema="staging",
        materialized="view",
        tags=["crm", "staging"],
    )
}}

{#
  Thin staging over CRM activity / email metadata.

  No body text, no mailbox addresses — those belong in a restricted store
  if you need them at all. Intermediate enrichment only needs ids + flags.
#}

with activities as (

    select distinct
        id as activity_message_id,
        activity_id,
        related_to_id,
        subject,
        message_date,
        created_by_id,
        has_attachment,
        is_bounced,
        message_identifier,
        cast(load_timestamp as timestamp) as load_timestamp,
        created_at
    from {{ source("crm", "crm_activities") }}
    where activity_id is not null

)

select *
from activities
