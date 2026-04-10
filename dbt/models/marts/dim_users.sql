with users as (
    select * from {{ ref('stg_tickit__users') }}
),

sales as (
    select
        buyer_id,
        count(*)            as total_purchases,
        sum(price_paid)     as total_spent
    from {{ ref('fct_sales') }}
    group by 1
),

listings as (
    select
        seller_id,
        count(*)            as total_listings,
        sum(total_price)    as total_listed_value
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
    u.email,
    u.likes_sports,
    u.likes_theatre,
    u.likes_concerts,
    u.likes_jazz,
    u.likes_rock,
    u.likes_broadway,
    u.likes_musicals,
    coalesce(b.total_purchases, 0)      as total_purchases,
    coalesce(b.total_spent, 0)          as total_spent,
    coalesce(l.total_listings, 0)       as total_listings,
    coalesce(l.total_listed_value, 0)   as total_listed_value
from users u
left join sales b    on u.user_id = b.buyer_id
left join listings l on u.user_id = l.seller_id
