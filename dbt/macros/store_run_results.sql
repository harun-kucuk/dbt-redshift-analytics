{% macro store_run_results(results) %}
    {#
        Persists dbt run results to dbt_metadata.run_results after every
        prod run. Called from on-run-end in dbt_project.yml.

        Creates the table on first use; subsequent runs append rows.
        Only fires when target.name == 'prod'.
    #}
    {% if execute %}

        {% set create_table %}
            create table if not exists dbt_metadata.run_results (
                invocation_id   varchar(64)     not null,
                run_started_at  timestamp       not null,
                node_id         varchar(256)    not null,
                node_name       varchar(128)    not null,
                resource_type   varchar(32)     not null,
                status          varchar(32)     not null,
                execution_time  numeric(10, 3),
                message         varchar(512),
                recorded_at     timestamp       default getdate()
            )
        {% endset %}
        {% do run_query(create_table) %}

        {% for result in results %}
            {% set message = result.message | replace("'", "''") if result.message else '' %}
            {% set insert_row %}
                insert into dbt_metadata.run_results (
                    invocation_id,
                    run_started_at,
                    node_id,
                    node_name,
                    resource_type,
                    status,
                    execution_time,
                    message
                )
                values (
                    '{{ invocation_id }}',
                    '{{ run_started_at }}',
                    '{{ result.node.unique_id }}',
                    '{{ result.node.name }}',
                    '{{ result.node.resource_type }}',
                    '{{ result.status }}',
                    {{ result.execution_time | round(3) }},
                    '{{ message }}'
                )
            {% endset %}
            {% do run_query(insert_row) %}
        {% endfor %}

    {% endif %}
{% endmacro %}
