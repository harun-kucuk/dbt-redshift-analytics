{#
  Redshift compatibility shims for brooklyn-data/dbt_artifacts.

  The package has no native Redshift support — default__insert_into_metadata_table
  is a no-op and cast(null as varchar) produces varchar(1) on Redshift because
  Redshift infers the shortest possible type for unspecified-length casts.

  Fixes:
    1. redshift__insert_into_metadata_table  — enables actual inserts using the
       same postgres-style INSERT ... VALUES pattern (Redshift is wire-compatible).
    2. redshift__type_string (dbt_artifacts namespace) — returns varchar(65535)
       so source tables get properly wide text columns instead of varchar(1).
#}

{% macro redshift__insert_into_metadata_table(relation, fields, content) -%}
    {% set insert_into_table_query %}
    insert into {{ relation }} {{ fields }}
    values
    {{ content }}
    {% endset %}
    {% do run_query(insert_into_table_query) %}
{%- endmacro %}

{# Override type_string for dbt_artifacts dispatch so source model columns  #}
{# are created with a usable length on Redshift.                            #}
{% macro dbt_artifacts__redshift__type_string() %}
    varchar(65535)
{% endmacro %}
