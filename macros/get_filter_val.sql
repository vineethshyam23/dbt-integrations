{#
  Returns the max date watermark for an incremental filter as a quoted date literal.

  Why: copy-pasting `select max(date(col)) from {{ this }}` into every model
  drifts. Centralizing the coalesce + parse-time default keeps merge windows
  consistent and makes full-refresh vs incremental behavior predictable.

  Usage (inside `{% if is_incremental() %}`):
    where date(_updated_at) >= {{ get_filter_val(model_name=this, column='_updated_at') }}

  Notes:
  - `run_query` only executes when `execute` is true (compile-safe default).
  - Column is adapter-quoted; pass the physical column name, not an expression.
  - Default watermark is 1970-01-01 so empty targets still load history once.
#}
{% macro get_filter_val(model_name, column) %}
    {%- set default_date = '1970-01-01' -%}

    {%- set sql -%}
        SELECT coalesce(max(date({{ adapter.quote(column) }})), date('{{ default_date }}'))
        FROM {{ model_name }}
    {%- endset -%}

    {%- if execute -%}
        {%- set results = run_query(sql) -%}
        {%- set results_list = results.columns[0][0] if results and results.columns[0][0] else default_date -%}
    {%- else -%}
        {%- set results_list = default_date -%}
    {%- endif -%}

    '{{ results_list }}'
{% endmacro %}
