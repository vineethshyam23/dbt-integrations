{{
    config(
        enabled=true,
        schema="staging",
        materialized="view",
        tags=["entity_match", "staging", "composite-key"],
    )
}}

{#
  Staging for pairwise match results.

  composite_key is the stable handle for (id_source_1, id_source_2).
  Snapshots and QUALIFY windows use it so null-safe pair identity does not
  drift across runs. Grain at this layer is still "one candidate row per
  landing row" — uniqueness is enforced later (snapshot unique_key /
  QUALIFY), not here.

  Sanitized from a matching-engine weekly staging model that applied the
  same macro shape to id_source_1 / id_source_2.
#}

with source as (

    select *
    from {{ source("raw_entity_match", "entity_match_results") }}

),

renamed as (

    select
        cast(run_id as string) as run_id,
        cast(country_code as string) as country_code,
        cast(source_1 as string) as source_1,
        cast(source_2 as string) as source_2,
        cast(id_source_1 as string) as id_source_1,
        cast(id_source_2 as string) as id_source_2,
        cast(match_type as string) as match_type,
        cast(match_quality as string) as match_quality,
        cast(fm_mean as float64) as fm_mean,
        cast(created_at as timestamp) as source_create_ts,
        {{ composite_match_key("id_source_1", "id_source_2") }} as composite_key
    from source

)

select *
from renamed
