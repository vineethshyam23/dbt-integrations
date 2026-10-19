{#
  Schema-spec for marketplace venue payloads.

  Teaching subset of a production BigQuery JSON schema export: enough nested
  RECORD / REPEATED / alias cases to exercise project_nested_json, without
  PII columns (no email, phone, street contact). Generate or hand-maintain
  one of these per resource type; do not inline 80 json_value calls in SQL.
#}

{% macro marketplace_venue_schema() %}
    {{ return(fromjson('[
        {"name":"venue_id","type":"STRING","mode":"NULLABLE","aliases":["@id","id"]},
        {"name":"resource_type","type":"STRING","mode":"NULLABLE","aliases":["@type","type"]},
        {"name":"name","type":"STRING","mode":"NULLABLE"},
        {"name":"partner_id","type":"STRING","mode":"NULLABLE","path":"partnerId"},
        {"name":"correlation_id","type":"STRING","mode":"NULLABLE","path":"correlationId"},
        {"name":"operation","type":"STRING","mode":"NULLABLE"},
        {"name":"version","type":"STRING","mode":"NULLABLE"},
        {"name":"source_timestamp","type":"TIMESTAMP","mode":"NULLABLE","path":"timestamp"},
        {"name":"date_modified","type":"TIMESTAMP","mode":"NULLABLE","path":"dateModified"},
        {"name":"serves_cuisine","type":"STRING","mode":"REPEATED","path":"servesCuisine"},
        {"name":"address","type":"RECORD","mode":"NULLABLE","fields":[
            {"name":"country","type":"STRING","mode":"NULLABLE","path":"addressCountry"},
            {"name":"locality","type":"STRING","mode":"NULLABLE","path":"addressLocality"},
            {"name":"region","type":"STRING","mode":"NULLABLE","path":"addressRegion"},
            {"name":"postal_code","type":"STRING","mode":"NULLABLE","path":"postalCode"}
        ]},
        {"name":"geo","type":"RECORD","mode":"NULLABLE","fields":[
            {"name":"latitude","type":"FLOAT","mode":"NULLABLE"},
            {"name":"longitude","type":"FLOAT","mode":"NULLABLE"}
        ]},
        {"name":"menu_refs","type":"RECORD","mode":"REPEATED","path":"hasMenu","fields":[
            {"name":"menu_id","type":"STRING","mode":"NULLABLE","aliases":["@id","id"]},
            {"name":"menu_type","type":"STRING","mode":"NULLABLE","aliases":["@type","type"]}
        ]}
    ]')) }}
{% endmacro %}
