{#
  Flatten nested menu-section JSON into one row per descendant section.

  Production streams often land a whole menu tree in one message. BI and
  contracts want a section grain with parent pointers and stable emission
  order — not a REPEATED STRUCT that still needs UNNEST in every dashboard.

  Companion to project_nested_json (pattern 12): expand first, then project
  the enriched section JSON through a small schema-spec.

  Primitives:
    json_node_id       — COALESCE @id / id
    json_children      — safe json_query_array (empty array if missing)
    path_step          — zero-padded sort fragment
    menu_envelope_columns — menu-level ids copied onto every section row
    menu_section_expansion_ctes — recursive UNNEST CTEs (roots omitted)
    enrich_menu_section_json — json_set parent + envelope onto section_json
#}

{% macro json_node_id(json_expr) -%}
coalesce(
    json_value({{ json_expr }}, '$."@id"'),
    json_value({{ json_expr }}, '$.id')
)
{%- endmacro %}


{% macro json_children(json_expr, field_name) -%}
ifnull(json_query_array({{ json_expr }}, '$.{{ field_name }}'), [])
{%- endmacro %}


{% macro path_step(value_expr) -%}
lpad(cast({{ value_expr }} as string), 6, '0')
{%- endmacro %}


{% macro menu_envelope_columns(payload_expr) -%}
    {{ json_node_id(payload_expr) }} as menu_id,
    json_value({{ payload_expr }}, '$.correlationId') as correlation_id,
    json_value({{ payload_expr }}, '$.timestamp') as menu_timestamp,
    json_value({{ payload_expr }}, '$.operation') as operation,
    json_value({{ payload_expr }}, '$.partnerId') as partner_id
{%- endmacro %}


{#
  Emits CTEs ending in `_ms_numbered`. Root `hasMenuSection` nodes are
  walked but not emitted — only descendants (depth >= 1 from each root's
  children). `max_depth` caps compile-time recursion; raise only when
  publishers actually nest deeper.
#}
{% macro menu_section_expansion_ctes(source_cte, max_depth=4) %}
_ms_roots as (
    select
        src.message_id,
        src.publish_time,
        src.payload,
        {{ menu_envelope_columns('src.payload') }},
        root_section,
        {{ json_node_id('root_section') }} as root_id,
        concat('R1.', cast(root_off as string)) as parent_node_path,
        concat({{ path_step(1) }}, '.', {{ path_step('root_off') }}) as parent_sort_key
    from {{ source_cte }} src
    cross join unnest({{ json_children('src.payload', 'hasMenuSection') }}) as root_section
        with offset as root_off
),

_ms_d1 as (
    select
        r.message_id,
        r.publish_time,
        r.payload,
        r.menu_id,
        r.correlation_id,
        r.menu_timestamp,
        r.operation,
        r.partner_id,
        child as section_json,
        r.root_id as parent_menu_section_id,
        child_off as sibling_offset,
        concat(r.parent_node_path, '.B3.', cast(child_off as string)) as node_path,
        r.parent_sort_key,
        concat(
            r.parent_sort_key,
            '.',
            {{ path_step(3) }},
            '.',
            {{ path_step('child_off') }}
        ) as sort_key
    from _ms_roots r
    cross join unnest({{ json_children('r.root_section', 'hasMenuSection') }}) as child
        with offset as child_off
),

{% for depth in range(2, max_depth + 1) %}
_ms_d{{ depth }} as (
    select
        prev.message_id,
        prev.publish_time,
        prev.payload,
        prev.menu_id,
        prev.correlation_id,
        prev.menu_timestamp,
        prev.operation,
        prev.partner_id,
        child as section_json,
        {{ json_node_id('prev.section_json') }} as parent_menu_section_id,
        child_off as sibling_offset,
        concat(prev.node_path, '.B3.', cast(child_off as string)) as node_path,
        prev.sort_key as parent_sort_key,
        concat(
            prev.sort_key,
            '.',
            {{ path_step(3) }},
            '.',
            {{ path_step('child_off') }}
        ) as sort_key
    from _ms_d{{ depth - 1 }} prev
    cross join unnest({{ json_children('prev.section_json', 'hasMenuSection') }}) as child
        with offset as child_off
),
{% endfor %}

_ms_emitted as (
    {% for depth in range(1, max_depth + 1) %}
    select
        message_id,
        publish_time,
        payload,
        menu_id,
        correlation_id,
        menu_timestamp,
        operation,
        partner_id,
        section_json,
        parent_menu_section_id,
        sibling_offset,
        node_path,
        parent_sort_key,
        sort_key
    from _ms_d{{ depth }}
    {%- if not loop.last %}
    union all
    {% endif %}
    {% endfor %}
),

_ms_numbered as (
    select
        message_id,
        publish_time,
        payload,
        menu_id,
        correlation_id,
        menu_timestamp,
        operation,
        partner_id,
        section_json,
        parent_menu_section_id,
        sibling_offset,
        node_path,
        parent_sort_key,
        sort_key,
        row_number() over (
            partition by message_id
            order by parent_sort_key, sibling_offset
        ) - 1 as emission_ordinal
    from _ms_emitted
)
{% endmacro %}


{% macro enrich_menu_section_json() -%}
json_set(
    section_json,
    '$.menuId', menu_id,
    '$.parentMenuSectionId', parent_menu_section_id,
    '$.correlationId', correlation_id,
    '$.timestamp', menu_timestamp,
    '$.operation', operation,
    '$.partnerId', partner_id
)
{%- endmacro %}
