{#
  Parse timestamps that arrive as either:
  - a castable timestamp / RFC3339-like string
  - epoch milliseconds as a numeric string

  Out-of-range epoch values return null (safe_cast / BETWEEN guard) so
  quarantine models can classify them as invalid_timestamp instead of
  failing the whole run.
#}
{% macro parse_flexible_timestamp(value_expression) -%}
coalesce(
    safe_cast({{ value_expression }} as timestamp),
    case
        when safe_cast({{ value_expression }} as bignumeric)
            between -62135596800000 and 253402300799999
            then timestamp_millis(safe_cast({{ value_expression }} as int64))
    end
)
{%- endmacro %}
