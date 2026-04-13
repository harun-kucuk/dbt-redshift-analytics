{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set pr_number = env_var('DBT_PR_NUMBER', '') -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- elif pr_number != '' -%}
        ci_pr_{{ pr_number }}_{{ custom_schema_name | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
