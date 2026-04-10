select
    event_id,
    event_name,
    category_name,
    category_group,
    venue_name,
    venue_city,
    sale_year,
    count(distinct sale_id)             as total_sales,
    sum(quantity_sold)                  as total_tickets_sold,
    sum(price_paid)                     as gross_revenue,
    sum(net_revenue)                    as net_revenue,
    avg(price_paid)                     as avg_sale_price,
    {{ safe_divide('sum(net_revenue)', 'sum(quantity_sold)') }} as revenue_per_ticket
from {{ ref('int_sales_enriched') }}
group by 1, 2, 3, 4, 5, 6, 7
