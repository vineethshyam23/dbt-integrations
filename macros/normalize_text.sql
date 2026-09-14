{#
  Text / email normalize helpers for staging → intermediate pipelines.

  Two complementary shapes show up in production warehouses:

  1. preserve_linebreaks — staging often keeps free-text readable for ops tools
     by turning CR/LF into HTML-ish <br /> placeholders.
  2. normalize_text — intermediate strips control newlines and edge <br /> tags
     so joins / exports do not carry export artifacts or mid-field whitespace
     surprises. Mid-string <br /> is kept on purpose (content editors use it).

  Email helpers hash with a project var salt — never hardcode a production salt
  in macros committed to git. Set `email_hash_salt` in dbt_project.yml / CI vars.
#}

{% macro preserve_linebreaks(column_name) %}
    replace(
        replace(
            replace(
                replace(
                    ifnull({{ column_name }}, ''),
                    '\r\n', '<br />'
                ),
                '\n\r', '<br />'
            ),
            '\r', '<br />'
        ),
        '\n', '<br />'
    )
{% endmacro %}


{% macro normalize_text(column_name) %}
    {% if '.' in column_name or '(' in column_name %}
        {% set column_ref = column_name %}
    {% else %}
        {% set column_ref = '`' ~ column_name ~ '`' %}
    {% endif %}
    trim(
        regexp_replace(
            regexp_replace(
                replace(
                    replace(
                        replace(
                            replace(
                                replace(
                                    ifnull(cast({{ column_ref }} as string), ''),
                                    '\r\n',
                                    ''
                                ),
                                '\n\r',
                                ''
                            ),
                            '\r',
                            ''
                        ),
                        '\n',
                        ''
                    ),
                    chr(13),
                    ''
                ),
                r'(?i)(<br\s*/?>\s*)+$',
                ''
            ),
            r'(?i)^(<br\s*/?>\s*)+',
            ''
        )
    )
{% endmacro %}


{% macro email_domain(column_name) %}
    ifnull(split(`{{ column_name }}`, '@')[safe_offset(1)], '')
{% endmacro %}


{% macro email_hash(column_name) %}
    {%- set salt = var('email_hash_salt', 'REPLACE_ME_SET_email_hash_salt') -%}
    ifnull(to_hex(md5(concat('{{ salt }}', lower(`{{ column_name }}`)))), '')
{% endmacro %}


{# Empty / NULL email → '' (matches legacy CONCAT-null behavior). #}
{% macro email_hash_if_present(column_name) %}
    case
        when `{{ column_name }}` is null or trim(cast(`{{ column_name }}` as string)) = ''
        then ''
        else {{ email_hash(column_name) }}
    end
{% endmacro %}
