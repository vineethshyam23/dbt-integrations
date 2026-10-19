{#
  Project a JSON payload into typed BigQuery columns from a schema-spec list.

  Schema-spec field shape (dict / fromjson):
    name     — output column name
    type     — STRING | INTEGER | FLOAT | BOOLEAN | TIMESTAMP | RECORD
    mode     — NULLABLE (default) | REPEATED
    path     — optional JSON key when it differs from name
    aliases  — optional list of JSON keys to COALESCE (e.g. ["@id", "id"])
    fields   — nested schema-spec when type == RECORD

  Pair with a resource-specific schema macro (see marketplace_venue_schema)
  so typed intermediates stay one SELECT of projected columns + broker keys.
#}

{% macro project_nested_json(json_expression, schema_fields, base_path='$') -%}
    {%- for field in schema_fields -%}
        {{ project_nested_json_field(json_expression, field, base_path) }}
        as {{ adapter.quote(field['name']) }}
        {%- if not loop.last %},{% endif %}
    {%- endfor -%}
{%- endmacro %}


{% macro project_nested_json_field(json_expression, field, base_path='$') -%}
    {%- set mode = field.get('mode', 'NULLABLE') -%}
    {%- set field_type = field['type'] -%}
    {%- set paths = nested_json_paths(base_path, field) -%}

    {%- if mode == 'REPEATED' and field_type == 'RECORD' -%}
        array(
            select as struct
                {{ project_nested_json('nested_element', field['fields'], '$') }}
            from unnest(
                ifnull({{ nested_json_query_array(json_expression, paths) }}, [])
            ) as nested_element with offset as nested_offset
            order by nested_offset
        )
    {%- elif mode == 'REPEATED' -%}
        array(
            select
                {{ cast_nested_json_scalar('nested_value', field_type, true) }}
            from unnest(
                ifnull({{ nested_json_value_array(json_expression, paths) }}, [])
            ) as nested_value with offset as nested_offset
            order by nested_offset
        )
    {%- elif field_type == 'RECORD' -%}
        if(
            {{ nested_json_query(json_expression, paths) }} is null,
            cast(null as {{ nested_json_bq_type(field) }}),
            struct(
                {{ project_nested_json(json_expression, field['fields'], paths[0]) }}
            )
        )
    {%- else -%}
        {{ cast_nested_json_scalar(
            nested_json_value(json_expression, paths),
            field_type,
            false
        ) }}
    {%- endif -%}
{%- endmacro %}


{% macro nested_json_paths(base_path, field) -%}
    {%- set names = field.get('aliases', [field.get('path', field['name'])]) -%}
    {%- set paths = [] -%}
    {%- for name in names -%}
        {%- do paths.append(base_path ~ '."' ~ name | replace('"', '\\"') ~ '"') -%}
    {%- endfor -%}
    {{ return(paths) }}
{%- endmacro %}


{% macro nested_json_value(json_expression, paths) -%}
    {%- if paths | length == 1 -%}
        json_value({{ json_expression }}, '{{ paths[0] }}')
    {%- else -%}
        coalesce(
            {%- for path in paths -%}
                json_value({{ json_expression }}, '{{ path }}')
                {%- if not loop.last %}, {% endif -%}
            {%- endfor -%}
        )
    {%- endif -%}
{%- endmacro %}


{% macro nested_json_query(json_expression, paths) -%}
    {%- if paths | length == 1 -%}
        json_query({{ json_expression }}, '{{ paths[0] }}')
    {%- else -%}
        coalesce(
            {%- for path in paths -%}
                json_query({{ json_expression }}, '{{ path }}')
                {%- if not loop.last %}, {% endif -%}
            {%- endfor -%}
        )
    {%- endif -%}
{%- endmacro %}


{% macro nested_json_value_array(json_expression, paths) -%}
    {%- if paths | length == 1 -%}
        json_value_array({{ json_expression }}, '{{ paths[0] }}')
    {%- else -%}
        coalesce(
            {%- for path in paths -%}
                json_value_array({{ json_expression }}, '{{ path }}')
                {%- if not loop.last %}, {% endif -%}
            {%- endfor -%}
        )
    {%- endif -%}
{%- endmacro %}


{% macro nested_json_query_array(json_expression, paths) -%}
    {%- if paths | length == 1 -%}
        json_query_array({{ json_expression }}, '{{ paths[0] }}')
    {%- else -%}
        coalesce(
            {%- for path in paths -%}
                json_query_array({{ json_expression }}, '{{ path }}')
                {%- if not loop.last %}, {% endif -%}
            {%- endfor -%}
        )
    {%- endif -%}
{%- endmacro %}


{% macro cast_nested_json_scalar(value_expression, field_type, already_string=false) -%}
    {%- if field_type == 'STRING' -%}
        {{ value_expression }}
    {%- elif field_type == 'INTEGER' -%}
        safe_cast({{ value_expression }} as int64)
    {%- elif field_type == 'FLOAT' -%}
        safe_cast({{ value_expression }} as float64)
    {%- elif field_type == 'BOOLEAN' -%}
        safe_cast({{ value_expression }} as bool)
    {%- elif field_type == 'TIMESTAMP' -%}
        {{ parse_flexible_timestamp(value_expression) }}
    {%- else -%}
        {{ exceptions.raise_compiler_error(
            'Unsupported nested JSON scalar type: ' ~ field_type
        ) }}
    {%- endif -%}
{%- endmacro %}


{% macro nested_json_bq_type(field) -%}
    {%- set field_type = field['type'] -%}
    {%- if field.get('mode', 'NULLABLE') == 'REPEATED' -%}
        array<
    {%- endif -%}
    {%- if field_type == 'RECORD' -%}
        struct<
            {%- for child in field['fields'] -%}
                {{ adapter.quote(child['name']) }} {{ nested_json_bq_type(child) }}
                {%- if not loop.last %}, {% endif -%}
            {%- endfor -%}
        >
    {%- elif field_type == 'INTEGER' -%}
        int64
    {%- elif field_type == 'FLOAT' -%}
        float64
    {%- elif field_type == 'BOOLEAN' -%}
        bool
    {%- else -%}
        {{ field_type | lower }}
    {%- endif -%}
    {%- if field.get('mode', 'NULLABLE') == 'REPEATED' -%}
        >
    {%- endif -%}
{%- endmacro %}
