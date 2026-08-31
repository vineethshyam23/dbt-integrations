{{
  config(
    schema='intermediate',
    materialized='ephemeral',
    tags=['erp_invoices', 'finance'],
  )
}}

-- Placeholder for the SCD / snapshot relation that feeds int_erp_invoices.
-- In production this is usually a dbt snapshot or a trusted history table.
-- Columns below match what the intermediate expects; swap the body for your feed.

select
    cast(null as int64) as erp_line_id,
    cast(null as int64) as erp_invoice_id,
    cast(null as string) as establishment_id,
    cast(null as int64) as company_partner_id,
    cast(null as string) as postal_code,
    cast(null as string) as country_code,
    cast(null as string) as customer_external_id,
    cast(null as string) as invoice_partner_name,
    cast(null as string) as commercial_partner_name,
    cast(null as string) as tax_id,
    cast(null as date) as booking_date,
    cast(null as date) as invoice_date_due,
    cast(null as string) as parent_bill,
    cast(null as string) as move_type,
    cast(null as string) as payment_status,
    cast(null as date) as paid_on,
    cast(null as string) as parent_state,
    cast(null as string) as product_code,
    cast(null as boolean) as product_is_setup,
    cast(null as string) as price_adjustment,
    cast(null as string) as discount_code,
    cast(null as float64) as net_price_eur,
    cast(null as float64) as gross_price_local,
    cast(null as timestamp) as dbt_updated_at,
    cast(null as timestamp) as dbt_valid_from,
    cast(null as timestamp) as dbt_valid_to
where false
