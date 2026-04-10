{{
    config(
        materialized='incremental',
        unique_key='sale_id',
        on_schema_change='sync_all_columns'
    )
}}

with base as (
    select * from {{ ref('int_sales_enriched') }}

    {% if is_incremental() %}
    -- On incremental runs, only process sales newer than the latest
    -- record already in the table. Gives roughly 1-day overlap to
    -- catch any late-arriving rows without a full-refresh.
    where sale_at > (
        select dateadd(day, -1, max(sale_at)) from {{ this }}
    )
    {% endif %}
)

select
    {{ dbt_utils.generate_surrogate_key(['sale_id']) }} as fct_sale_sk,  -- noqa
    base.*
from base
