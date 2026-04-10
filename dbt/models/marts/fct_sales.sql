with sales as (
    select * from {{ ref('stg_tickit__sales') }}
),

events as (
    select * from {{ ref('stg_tickit__events') }}
),

dates as (
    select * from {{ ref('stg_tickit__dates') }}
),

categories as (
    select * from {{ ref('stg_tickit__categories') }}
),

venues as (
    select * from {{ ref('stg_tickit__venues') }}
)

select
    s.sale_id,
    s.listing_id,
    s.seller_id,
    s.buyer_id,
    s.event_id,
    e.event_name,
    c.category_name,
    c.category_group,
    v.venue_name,
    v.city          as venue_city,
    v.state         as venue_state,
    d.date          as sale_date,
    d.month         as sale_month,
    d.quarter       as sale_quarter,
    d.year          as sale_year,
    d.is_holiday,
    s.quantity_sold,
    s.price_paid,
    s.commission,
    s.price_paid - s.commission as net_revenue,
    s.sale_at
from sales s
left join events e    on s.event_id = e.event_id
left join categories c on e.category_id = c.category_id
left join venues v    on e.venue_id = v.venue_id
left join dates d     on s.date_id = d.date_id
