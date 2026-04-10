select
    venue_id,
    venue_name,
    venue_city,
    venue_state,
    venue_seats,
    count(distinct event_id)            as total_events,
    count(distinct sale_id)             as total_sales,
    sum(quantity_sold)                  as total_tickets_sold,
    sum(net_revenue)                    as total_net_revenue,
    avg(net_revenue)                    as avg_sale_revenue,
    {{ safe_divide('sum(quantity_sold)', 'sum(venue_seats)') }} as avg_seat_fill_rate
from {{ ref('int_sales_enriched') }}
where venue_id is not null
group by 1, 2, 3, 4, 5
