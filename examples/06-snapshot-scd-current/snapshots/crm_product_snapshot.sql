{#
  Sanitized CRM product snapshot (check strategy).

  Grain: one version row per product_id change over time.
  dbt writes dbt_scd_id / dbt_updated_at / dbt_valid_from / dbt_valid_to.
  Current versions keep dbt_valid_to IS NULL.

  Wire ref() to your staging product model. Prefer check-all for small
  catalog dimensions; switch to timestamp strategy when volume or churn
  makes full-row compares expensive.
#}
{% snapshot crm_product_snapshot %}

    {{
        config(
            target_database="your-gcp-project",
            target_schema="intermediate",
            unique_key="product_id",
            strategy="check",
            check_cols="all",
            hard_deletes="invalidate",
            tags=["crm", "snapshot", "product"],
        )
    }}

    select
        product_id,
        product_code,
        product_name,
        is_active,
        created_at,
        system_modstamp
    from {{ ref("stg_crm_product") }}

{% endsnapshot %}
