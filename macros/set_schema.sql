{#
  Prefix-aware dataset (schema) router for snapshots and explicit configs.

  Model / snapshot names starting with:
    stg_  → staging dataset (DBT_STG_SCHEMA in prod/dev)
    int_  → intermediate dataset (DBT_INT_SCHEMA)
    else  → marts / refined dataset (DBT_MARTS_SCHEMA)

  custom_schema_name always wins when set — use that for one-off landing
  datasets (e.g. a trusted snapshot layer) without changing the prefix rules.

  Usage:
    target_schema=set_schema(custom_schema_name=none, model_name="stg_crm_accounts") | trim
    target_schema=set_schema(custom_schema_name="marts", model_name="crm_account_snapshot") | trim

  Pair with generate_database_name for full project + dataset routing.
  Env vars must be set in the runner for prod/dev; default target falls back
  to target.schema / the explicit custom name.
#}
{% macro set_schema(custom_schema_name=none, model_name=none) %}

    {%- set split_name = model_name.split("_") -%}
    {%- set model_prefix = split_name[0] | trim -%}

    {# Staging models #}
    {%- if model_prefix == "stg" -%}

        {%- if target.name == "default" and custom_schema_name is none -%}
            {{ target.schema | trim }}
        {%- elif target.name == "default" and custom_schema_name is not none -%}
            {{ custom_schema_name | trim }}
        {%- elif target.name in ["dev", "prod"] and custom_schema_name is none -%}
            {{ env_var("DBT_STG_SCHEMA") | trim }}
        {%- elif target.name in ["dev", "prod"] and custom_schema_name is not none -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {# Intermediate models #}
    {%- elif model_prefix == "int" -%}

        {%- if target.name == "default" and custom_schema_name is none -%}
            {{ target.schema | trim }}
        {%- elif target.name == "default" and custom_schema_name is not none -%}
            {{ custom_schema_name | trim }}
        {%- elif target.name in ["dev", "prod"] and custom_schema_name is none -%}
            {{ env_var("DBT_INT_SCHEMA") | trim }}
        {%- elif target.name in ["dev", "prod"] and custom_schema_name is not none -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {# Marts / everything else #}
    {%- else -%}

        {%- if target.name == "default" and custom_schema_name is none -%}
            {{ target.schema | trim }}
        {%- elif target.name == "default" and custom_schema_name is not none -%}
            {{ custom_schema_name | trim }}
        {%- elif target.name in ["dev", "prod"] and custom_schema_name is none -%}
            {{ env_var("DBT_MARTS_SCHEMA") | trim }}
        {%- elif target.name in ["dev", "prod"] and custom_schema_name is not none -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {%- endif -%}

{% endmacro %}


{#
  Override dbt's default schema naming so +schema / schema= configs become
  the literal dataset name instead of {target.schema}_{custom}.

  That matches BigQuery layouts where staging / intermediate / marts are
  sibling datasets, not prefixes under one sandbox schema.
#}
{% macro generate_schema_name(custom_schema_name=none, node=none) -%}
    {{
        return(
            adapter.dispatch("generate_schema_name", "dbt")(custom_schema_name, node)
        )
    }}
{% endmacro %}

{% macro default__generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
