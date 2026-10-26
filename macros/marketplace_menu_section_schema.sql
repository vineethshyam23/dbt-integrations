{#
  Schema-spec for one marketplace menu-section row after expansion.

  Teaching subset: identity, parent pointer, envelope fields copied by
  enrich_menu_section_json. Production specs also project hasMenuItem trees;
  keep those out of the portfolio copy — the expand macro is the lesson.
#}

{% macro marketplace_menu_section_schema() %}
    {{ return(fromjson('[
        {"name":"section_id","type":"STRING","mode":"NULLABLE","aliases":["@id","id"]},
        {"name":"resource_type","type":"STRING","mode":"NULLABLE","aliases":["@type","type"]},
        {"name":"name","type":"STRING","mode":"NULLABLE"},
        {"name":"description","type":"STRING","mode":"NULLABLE"},
        {"name":"menu_id","type":"STRING","mode":"NULLABLE","path":"menuId"},
        {"name":"parent_menu_section_id","type":"STRING","mode":"NULLABLE","path":"parentMenuSectionId"},
        {"name":"partner_id","type":"STRING","mode":"NULLABLE","path":"partnerId"},
        {"name":"correlation_id","type":"STRING","mode":"NULLABLE","path":"correlationId"},
        {"name":"operation","type":"STRING","mode":"NULLABLE"},
        {"name":"source_timestamp","type":"TIMESTAMP","mode":"NULLABLE","path":"timestamp"}
    ]')) }}
{% endmacro %}
