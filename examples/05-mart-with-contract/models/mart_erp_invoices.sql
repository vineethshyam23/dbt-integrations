{{
  config(
    schema='marts',
    materialized='table',
    tags=['erp_invoices', 'finance', 'mart'],
  )
}}

-- Consumer mart: current invoice lines only.
-- Contract YAML owns column types + accepted values; keep this select boring.

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
    _update_ts,
    _valid_from,
    _valid_to,
    _valid_flag
from {{ ref('int_erp_invoices') }}
where _valid_flag = true
