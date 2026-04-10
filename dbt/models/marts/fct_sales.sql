{{
    config(
        materialized='incremental',
        unique_key='sale_id',
        on_schema_change='sync_all_columns'
    )
}}

with base as (
    select * from {{ ref('int_sales_enriched') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['sale_id']) }} as fct_sale_sk,  -- noqa
    base.*
from base

{% if is_incremental() %}
-- On incremental runs, only process sales newer than the latest record already
-- in the table. 1-day overlap catches late-arriving rows without a full-refresh.
where base.sale_at > (  -- noqa: LT02
    select dateadd(day, -1, max(sale_at)) from {{ this }}  -- noqa: LT02, RF02
)  -- noqa: LT02
{% endif %}
