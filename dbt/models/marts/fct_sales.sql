{{
    config(
        materialized='incremental',
        unique_key='sale_id',
        on_schema_change='append_new_columns'
    )
}}

with base as (
    select * from {{ ref('int_sales_enriched') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['sale_id']) }} as fct_sale_sk,  -- noqa
    sale_id,
    event_id,
    buyer_id,
    seller_id,
    listing_id,
    quantity_sold,
    price_paid,
    commission,
    commission_rate,
    net_revenue,
    category_group,
    sale_at,
    sale_date,
    sale_year,
    sale_week,
    is_holiday,
    event_name,
    event_start_at,
    category_id,
    category_name,
    venue_id,
    venue_name,
    venue_city,
    venue_seats
from base

{% if is_incremental() %}
-- On incremental runs, only process sales newer than the latest record already
-- in the table. 1-day overlap catches late-arriving rows without a full-refresh.
where base.sale_at > (  -- noqa: LT02
    select dateadd(day, -1, max(sale_at)) from {{ this }}  -- noqa: LT02, RF02
)  -- noqa: LT02
{% endif %}
