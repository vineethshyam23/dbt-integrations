{% snapshot entity_match_results_snapshot %}

{{
    config(
        target_schema="staging",
        unique_key=[
            "country_code",
            "source_1",
            "source_2",
            "composite_key",
            "match_type",
        ],
        strategy="timestamp",
        updated_at="source_create_ts",
        tags=["entity_match", "snapshot"],
    )
}}

{#
  SCD Type 2 over match candidates. composite_key stands in for the two
  raw id columns so null-safe pair identity is one column in unique_key.

  QUALIFY keeps the latest landing row per natural key before the snapshot
  strategy compares timestamps — avoids writing duplicate "current" rows
  when a matching job reloads the same pair in one batch.
#}

select *
from {{ ref("stg_entity_match_results") }}
qualify row_number() over (
    partition by
        country_code,
        source_1,
        source_2,
        composite_key,
        match_type
    order by source_create_ts desc
) = 1

{% endsnapshot %}
