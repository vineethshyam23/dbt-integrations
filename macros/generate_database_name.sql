{#
  Routes the BigQuery project (dbt "database") by target.

  Why: snapshots and some models need an explicit target_database. Hardcoding
  project IDs in every config drifts, and a single profile default is not enough
  when prod and dev projects differ.

  Usage (snapshots / configs):
    target_database=generate_database_name() | trim
    target_database=generate_database_name(custom_database_name='your-gcp-project') | trim

  Notes:
  - custom_database_name wins when provided (prod/dev targets).
  - Otherwise prod → your-gcp-project, dev → your-gcp-project-dev, else profile default.
  - Replace the placeholder project IDs with your own before production use.
#}
{% macro generate_database_name(custom_database_name=none, node=none) -%}

    {%- set default_database = target.database -%}
    {%- set production_database = "your-gcp-project" -%}
    {%- set development_database = "your-gcp-project-dev" -%}

    {%- if custom_database_name -%}

        {%- if target.name in ["prod", "dev"] -%}
            {{ custom_database_name | trim }}
        {%- else -%}
            {{ default_database | trim }}
        {%- endif -%}

    {%- else -%}

        {%- if target.name == "prod" -%}
            {{ production_database | trim }}
        {%- elif target.name == "dev" -%}
            {{ development_database | trim }}
        {%- else -%}
            {{ default_database | trim }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}
