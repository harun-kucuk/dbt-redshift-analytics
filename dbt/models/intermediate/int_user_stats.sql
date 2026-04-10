with users as (
    select * from {{ ref('stg_tickit__users') }}
),

purchases as (
    select
        buyer_id,
        count(*)            as total_purchases,
        sum(price_paid)     as total_spent,
        avg(price_paid)     as avg_order_value,
        min(sale_at)        as first_purchase_at,
        max(sale_at)        as last_purchase_at
    from {{ ref('int_sales_enriched') }}
    group by 1
),

sales as (
    select
        seller_id,
        count(*)            as total_sales,
        sum(net_revenue)    as total_earned,
        avg(net_revenue)    as avg_sale_value
    from {{ ref('int_sales_enriched') }}
    group by 1
),

listings as (
    select
        seller_id,
        count(*)            as total_listings,
        sum(total_price)    as total_listed_value,
        avg(price_per_ticket) as avg_ticket_price
    from {{ ref('stg_tickit__listings') }}
    group by 1
)

select
    u.user_id,
    u.username,
    u.first_name,
    u.last_name,
    u.city,
    u.state,
    u.likes_sports,
    u.likes_concerts,
    u.likes_theatre,
    u.likes_broadway,
    u.likes_musicals,
    coalesce(p.total_purchases, 0)      as total_purchases,
    coalesce(p.total_spent, 0)          as total_spent,
    coalesce(p.avg_order_value, 0)      as avg_order_value,
    p.first_purchase_at,
    p.last_purchase_at,
    coalesce(s.total_sales, 0)          as total_sales,
    coalesce(s.total_earned, 0)         as total_earned,
    coalesce(l.total_listings, 0)       as total_listings,
    coalesce(l.total_listed_value, 0)   as total_listed_value,
    coalesce(l.avg_ticket_price, 0)     as avg_ticket_price
from users u
left join purchases p   on u.user_id = p.buyer_id
left join sales s       on u.user_id = s.seller_id
left join listings l    on u.user_id = l.seller_id
