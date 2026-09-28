{#
  Stable pair-key for entity matching / SCD unique_key arrays.

  Production matching engines emit one row per (id_source_1, id_source_2)
  candidate. Nulls must hash the same way every run — coalesce to the string
  'null' so (NULL, 'A') and ('null', 'A') collide on purpose (treat missing
  and literal null-marker as the same side). Separator '||' keeps "12||3"
  distinct from "1||23".

  Returns lowercase hex MD5 via BigQuery to_hex(md5(...)).
#}

{% macro composite_match_key(id_source_1_expr, id_source_2_expr) %}
    to_hex(
        md5(
            concat(
                coalesce(cast({{ id_source_1_expr }} as string), 'null'),
                '||',
                coalesce(cast({{ id_source_2_expr }} as string), 'null')
            )
        )
    )
{% endmacro %}
