{{
  config(
    schema='intermediate',
    materialized='table',
    tags=['erp_invoices', 'finance'],
  )
}}

-- Intermediate reshape of ERP invoice history into typed validity columns.
-- Upstream is typically a snapshot / SCD table; keep that detail out of the mart.
-- Portfolio stub: replace erp_invoices_history with your snapshot or trusted feed.

with history as (
    select
        erp_line_id,
        erp_invoice_id,
        establishment_id,
        company_partner_id,
        postal_code,
        country_code,
        customer_external_id,
        invoice_partner_name,
        commercial_partner_name,
        tax_id,
        booking_date,
        invoice_date_due,
        parent_bill,
        move_type,
        payment_status,
        paid_on,
        parent_state,
        product_code,
        product_is_setup,
        price_adjustment,
        discount_code,
        net_price_eur,
        gross_price_local,
        dbt_updated_at as _update_ts,
        dbt_valid_from as _valid_from,
        dbt_valid_to as _valid_to,
        case when dbt_valid_to is null then true else false end as _valid_flag
    from {{ ref('erp_invoices_history') }}
)

select *
from history
