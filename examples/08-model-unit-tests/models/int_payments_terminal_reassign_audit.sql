{{
    config(
        enabled=true,
        schema="intermediate",
        materialized="table",
        tags=["payments", "terminals"],
    )
}}

-- Actionable ERP ↔ payments match rows only.
-- Include: store unassigned in payments, or merchant null/mismatch.
-- Skip: merchant matches ERP target and store already assigned.
-- Downstream feed readers should select is_in_feed = true only.

with
    ranked as (

        select
            *,
            row_number() over (
                partition by terminal_id
                order by store_id, lot_create_timestamp desc, lot_id desc
            ) as dedupe_rank

        from {{ ref("int_payments_erp_terminal_match") }}

    ),

    classified as (

        select
            ranked.terminal_id,
            ranked.establishment_uid,
            ranked.company_id,
            ranked.merchant_id as erp_target_merchant_id,
            ranked.store_id as erp_target_store_id,
            pay_td.merchant_id as payments_assigned_merchant_id,
            pay_td.store_id as payments_assigned_store_id,
            ranked.to_disable_standalone_tip,
            ranked.create_date,
            ranked.lot_id,
            ranked.dedupe_rank,
            case
                when ranked.dedupe_rank > 1
                    then 'excluded_dedupe'
                when pay_td.terminal_id is null
                    then 'excluded_terminal_not_in_payments'
                when pay_td.merchant_id is not null
                    and pay_td.merchant_id = ranked.merchant_id
                    and pay_td.store_id is not null
                    then 'excluded_merchant_assigned'
                else 'included_reassign'
            end as feed_status

        from ranked
        left join {{ ref("payments_terminal_data") }} as pay_td
            on pay_td.terminal_id = ranked.terminal_id

    ),

    actionable as (

        select *
        from classified
        where
            dedupe_rank = 1
            and feed_status != 'excluded_merchant_assigned'

    )

select
    *,
    feed_status = 'included_reassign' as is_in_feed,
    true as is_audit_actionable,
    current_timestamp() as evaluated_at
from actionable
