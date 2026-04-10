with base as (
    select * from {{ ref('int_sales_enriched') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['sale_id']) }} as fct_sale_sk,
    base.*
from base
