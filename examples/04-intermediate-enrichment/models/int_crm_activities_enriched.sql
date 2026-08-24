{{
    config(
        enabled=true,
        schema="intermediate",
        materialized="table",
        tags=["crm", "enrichment"],
    )
}}

{#
  Intermediate enrichment: activity facts + CRM dimensions → one external key.

  Pattern:
  1. Start from staging activities (ids + operational flags only).
  2. Left join user / account / task so missing dims do not drop the fact.
  3. Coalesce a single external_id with a documented fallback order.

  Grain: one row per (activity_message_id, activity_id) after distinct.
  Downstream: ERP / CRM sync preview, activity marts.
#}

with enriched as (

    select distinct
        act.activity_message_id,
        act.activity_id,
        act.related_to_id,
        act.subject,
        format_timestamp('%Y-%m-%d %H:%M:%S', safe_cast(act.message_date as timestamp))
            as message_date,
        act.created_by_id,
        act.has_attachment,
        act.is_bounced,
        act.message_identifier,
        act.load_timestamp,

        -- dimension enrichments
        usr.is_active as author_is_active,
        acc.external_uid as related_account_uid,
        task.account_id as task_account_id,
        task.who_id as task_who_id,
        acc_who.external_uid as who_account_uid,

        -- fallback order: related account → related_to_id → who-account via task
        coalesce(
            acc.external_uid,
            act.related_to_id,
            acc_who.external_uid
        ) as external_id

    from {{ ref("stg_crm_activities") }} as act
    left join {{ source("crm", "crm_user") }} as usr
        on act.created_by_id = usr.id
    left join {{ source("crm", "crm_account") }} as acc
        on act.related_to_id = acc.id
        and coalesce(acc.is_deleted, false) = false
    left join {{ source("crm", "crm_task") }} as task
        on act.activity_id = task.id
    left join {{ source("crm", "crm_account") }} as acc_who
        on task.who_id = acc_who.person_contact_id
        and coalesce(acc_who.is_deleted, false) = false

)

select *
from enriched
