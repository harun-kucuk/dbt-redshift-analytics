select
    sale_year,
    sale_quarter,
    sale_month,
    category_group,
    category_name,
    count(distinct sale_id)     as total_sales,
    sum(quantity_sold)          as total_tickets_sold,
    sum(price_paid)             as gross_revenue,
    sum(commission)             as total_commission,
    sum(net_revenue)            as net_revenue,
    avg(price_paid)             as avg_sale_value
from {{ ref('fct_sales') }}
group by 1, 2, 3, 4, 5
