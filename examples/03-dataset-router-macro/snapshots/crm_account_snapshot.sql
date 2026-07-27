{#
  Sanitized snapshot config showing generate_database_name + set_schema.

  Grain: one current row per account_id from staging CRM accounts.
  Strategy: check-all columns — fine for moderate-volume dimension feeds;
  switch to timestamp for high-churn facts.

  This file is a teaching excerpt. Wire ref() to a real staging model and set
  DBT_STG_SCHEMA / DBT_INT_SCHEMA / DBT_MARTS_SCHEMA in the runner before
  targeting prod/dev.
#}
{% snapshot crm_account_snapshot %}

    {{
        config(
            target_database=generate_database_name(custom_database_name=none, node=none) | trim,
            target_schema=set_schema(
                custom_schema_name="marts",
                model_name="crm_account_snapshot",
            ) | trim,
            unique_key="account_id",
            strategy="check",
            check_cols="all",
            hard_deletes="invalidate",
            tags=["crm", "snapshot"],
        )
    }}

    select
        account_id,
        account_status,
        segment_code,
        country_code,
        registered_at,
        last_modified_at
    from {{ ref("stg_crm_accounts") }}

{% endsnapshot %}
